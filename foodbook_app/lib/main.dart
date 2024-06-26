import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/bookmark_internet_view_bloc/bookmark_internet_view_bloc.dart';
import 'package:foodbook_app/bloc/bug_report_bloc/bug_report_bloc.dart';
import 'package:foodbook_app/bloc/hot_categories_bloc/hot_categories_bloc.dart';
import 'package:foodbook_app/bloc/login_bloc/auth_bloc.dart';
import 'package:foodbook_app/bloc/review_bloc/review_bloc/review_bloc.dart';
import 'package:foodbook_app/bloc/review_report_bloc/review_report_bloc.dart';
import 'package:foodbook_app/bloc/reviewdraft_bloc/reviewdraft_bloc.dart';
import 'package:foodbook_app/bloc/search_bloc/search_bloc.dart';
import 'package:foodbook_app/bloc/settings_bloc/settings_bloc.dart';
import 'package:foodbook_app/bloc/user_bloc/user_bloc.dart';
import 'package:foodbook_app/data/data_access_objects/shared_preferences_dao.dart';
import 'package:foodbook_app/data/data_sources/database_provider.dart';
import 'package:foodbook_app/data/repositories/auth_repository.dart';
import 'package:foodbook_app/data/repositories/bugs_report_repository.dart';
import 'package:foodbook_app/data/repositories/hot_categories_manager.dart';
import 'package:foodbook_app/data/repositories/restaurant_repository.dart';
import 'package:foodbook_app/data/repositories/review_repository.dart';
import 'package:foodbook_app/data/repositories/reviewdraft_repository.dart';
import 'package:foodbook_app/data/repositories/settings_manager.dart';
import 'package:foodbook_app/data/repositories/shared_preferences_repository.dart';
import 'package:foodbook_app/notifications/background_review_reminder.dart';
import 'package:foodbook_app/notifications/background_task.dart';
import 'package:foodbook_app/notifications/notification_service.dart';
import 'package:foodbook_app/presentation/views/login_view/signin_view.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:foodbook_app/presentation/views/test_views/search_bar.dart';
import 'package:foodbook_app/presentation/views/test_views/search_test.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: false);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]); // Set up background message handler
  NotificationService.init(); // Initialize notification service
  await requestLocationPermission();   // Request location permission
  // initializeBackgroundTaskReminder(); // Initialize background task for review reminder
  initializeBackgroundTask(); // Initialize background task
  runApp(const MyApp());
}

Future<void> requestLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, don't continue
    // accessing the position and request users of the 
    // app to enable the location services.
    throw Exception('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale 
      // returned true. According to Android guidelines
      // your app should show an explanatory UI now.
      throw Exception('Location permissions are denied.');
    }
  }
  
  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately. 
    throw Exception('Location permissions are permanently denied, we cannot request permissions.');
  } 
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider<RestaurantRepository>(
          create: (context) => RestaurantRepository(),
        ),
        RepositoryProvider<ReviewDraftRepository>(
          create: (context) => ReviewDraftRepository(DatabaseProvider()),
        ),
        // Add other repositories here if needed
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            ),
          ),
          BlocProvider<UserBloc>(
            create: (context) => UserBloc()
          ),
          BlocProvider<ReviewDraftBloc>(
            create: (context) => ReviewDraftBloc(
              RepositoryProvider.of<ReviewDraftRepository>(context, listen: false),
            ),
          ),
          BlocProvider<BookmarkInternetViewBloc>(
            create: (context) => BookmarkInternetViewBloc(),
          ),
          BlocProvider<SettingsBloc>(
            create: (context) => SettingsBloc(SettingsManager()),
          ),
          BlocProvider<BugReportBloc>(
            create: (context) => BugReportBloc(
              BugReportRepository(DatabaseProvider()),
            ),
          ),
          BlocProvider<ReviewReportBloc>(
            create: (context) => ReviewReportBloc(
              ReviewRepository(),
            ),
          ),
          BlocProvider<ReviewBloc>(
            create: (context) => ReviewBloc(
              reviewRepository: ReviewRepository(),
              restaurantRepository: RestaurantRepository(),
            ),
          ),
          BlocProvider<HotCategoriesBloc>(
            create: (context) => HotCategoriesBloc(
              hotCategoriesManager: HotCategoriesManager(),
            ),
          )
        ],
        child: MaterialApp(
          title: 'FoodBook',
          theme: ThemeData(
            primarySwatch: Colors.blue,
          ),
          home: const SignInView(),
          // Define the routing and other MaterialApp properties here
        ),
      ),
    );
  }
}




