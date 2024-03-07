import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_event.dart';
import 'package:foodbook_app/data/repository/restaurant_repo.dart';
import 'package:foodbook_app/presentation/views/restaurant_views/browse_view.dart';
import 'package:foodbook_app/presentation/views/restaurant_views/for_you_view.dart';
// Import other views as needed

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;

  CustomNavigationBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_border),
          label: 'For You',
        ),
        // Add more items as needed
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.blue,
      onTap: (index) {
        // This is where you'd put your navigation logic
        if (index == 0) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => BlocProvider<BrowseBloc>(
              create: (context) => BrowseBloc(restaurantRepository: RestaurantRepository())..add(LoadRestaurants()),
              child: BrowseView(),
            ),
          ));
        } else if (index == 1) {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (context) => BlocProvider<BrowseBloc>(
              create: (context) => BrowseBloc(restaurantRepository: RestaurantRepository())..add(LoadRestaurants()),
              child: ForYouView(),
            ),
          ));
        } // Add else if for other indexes as needed
        if(onItemTapped != null){
            onItemTapped(index);
        }
      },
    );
  }
}