import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_event.dart';
import 'package:foodbook_app/bloc/review_bloc/food_category_bloc/food_category_bloc.dart';
import 'package:foodbook_app/bloc/review_bloc/image_upload_bloc/image_upload_bloc.dart';
import 'package:foodbook_app/bloc/review_bloc/image_upload_bloc/image_upload_event.dart';
import 'package:foodbook_app/bloc/review_bloc/image_upload_bloc/image_upload_state.dart';
import 'package:foodbook_app/bloc/review_bloc/review_bloc/review_bloc.dart';
import 'package:foodbook_app/bloc/review_bloc/review_bloc/review_event.dart';
import 'package:foodbook_app/bloc/review_bloc/stars_bloc/stars_bloc.dart';
import 'package:foodbook_app/bloc/user_bloc/user_bloc.dart';
import 'package:foodbook_app/bloc/user_bloc/user_event.dart';
import 'package:foodbook_app/bloc/user_bloc/user_state.dart';
import 'package:foodbook_app/data/dtos/review_dto.dart';
import 'package:foodbook_app/data/models/restaurant.dart';
import 'package:foodbook_app/data/repositories/restaurant_repository.dart';
import 'package:foodbook_app/data/repositories/review_repository.dart';
import 'package:foodbook_app/notifications/background_review_reminder.dart';
import 'package:foodbook_app/presentation/views/restaurant_view/browse_view.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class TextAndImagesView extends StatefulWidget {
  final Restaurant restaurant;

  const TextAndImagesView({super.key, required this.restaurant});

  @override
  _TextAndImagesViewState createState() => _TextAndImagesViewState();
}

class _TextAndImagesViewState extends State<TextAndImagesView> {
  File? _image;
  int _times = 0;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();

  Future<void> getImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop(); // Cierra el modal
                  var storageStatus = await Permission.storage.status; // Para Android
                  if (!storageStatus.isGranted) {
                    await Permission.storage.request(); // Para Android
                  }
                  storageStatus = await Permission.storage.status; // Actualiza el estado para Android
                  if (storageStatus.isGranted) {
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() {
                        _image = File(pickedFile.path);
                      });
                    }
                  }
                storageStatus = await Permission.camera.status;                    
                  if (storageStatus.isPermanentlyDenied) {
                    openAppSettings();
                  }
                }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  var cameraStatus = await Permission.camera.status;
                  if (!cameraStatus.isGranted) {
                    await Permission.camera.request();
                  }
                  cameraStatus = await Permission.camera.status;
                  if (cameraStatus.isGranted) {
                    final pickedFile = await picker.pickImage(source: ImageSource.camera);
                    if (pickedFile != null) {
                      setState(() {
                        _image = File(pickedFile.path);
                      });
                    }
                  }
                  cameraStatus = await Permission.camera.status;                  
                  if (cameraStatus.isPermanentlyDenied) {
                      openAppSettings();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String? _email;
  String? _uploadedImageUrl;
  Future saveImage() async {
    print('Saving image...');
    if (_image == null) return; 
    final imageUploadBloc = BlocProvider.of<ImageUploadBloc>(context);
    imageUploadBloc.add(ImageUploadRequested(_image!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        title: const Text(
          'Leave a comment',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => {

              context.read<UserBloc>().add(GetCurrentUser()),
              saveImage(),
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) {
                  return BlocProvider<BrowseBloc>(
                    create: (context) =>
                        BrowseBloc(
                            restaurantRepository: RestaurantRepository(),
                            reviewRepository: ReviewRepository(),
                          )
                          ..add(LoadRestaurants()),
                    child: BrowseView(),
                  );
                }),
              ),
            },
            style: OutlinedButton.styleFrom(
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Done',
              style: TextStyle(
                fontSize: 20,
                color: Color.fromRGBO(0, 122, 255, 100),
              ),
            ),
          ),
        ],
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<UserBloc, UserState>(
            listener: (context, state) {
              if (state is AuthenticatedUserState) {
                _email = state.email;
                if (_image == null && _times == 0) {
                  print('No image to upload, creating review...');
                  createReview(_email!, null);
                  cancelSingleTask("reviewReminder");
                  initializeBackgroundTaskReminder();
                }
                
          } else if (state is UnauthenticatedUserState) {
                print('Usuario no autenticado. Por favor, inicia sesión.');
              }
            },
          ),
          BlocListener<ImageUploadBloc, ImageUploadState>(
            listener: (context, state) {  
              if (state is ImageUploadSuccess) {
                _uploadedImageUrl = state.imageUrl;
                if (context.read<UserBloc>().state is AuthenticatedUserState && _times == 0) {
                  createReview(_email!, _uploadedImageUrl!);
                }
              } else if (state is ImageUploadFailure) {
                // Manejo del error
                print('Error al subir imagen: ${state.error}');
              }
            },
          ),
        ],
        child: buildForm(),
      ),
    );
  }

  Widget buildForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const Padding(
                  padding: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 24.0),
                  child: Text(
                    'Write what you thought of the restaurant! (add some images to show your experience!)',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: '',
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TextFormField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      hintText: 'Your review',
                    ),
                    maxLines: 5,
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: getImage,
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                    child: _image != null
                        ? Image.file(_image!, fit: BoxFit.cover)
                        : const Icon(Icons.camera_alt, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: OutlinedButton(
                    onPressed: () {
                      if (_image != null) {
                        setState(() {
                          _image = null;
                        });
                      } else {
                        getImage();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      _image != null ? 'Remove image' : 'Add image',
                      style: TextStyle(
                        fontSize: 20,
                        color: _image != null ? const Color.fromRGBO(255, 0, 0, 0.612) : const Color.fromRGBO(0, 122, 255, 100),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void createReview(String userEmail, String? uploadedImageUrl) async {
    final foodCategoryBloc = BlocProvider.of<FoodCategoryBloc>(context);
    final starsBloc = BlocProvider.of<StarsBloc>(context);

    final selectedCategories = foodCategoryBloc.selectedCategories;
    final stars = starsBloc.newRatings;

    final selectedCategoriesString = selectedCategories.map((category) => category.name).toList();
    
    ReviewDTO newReview = ReviewDTO(
      user: userEmail.replaceFirst("@gmail.com", ""),
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      content: _commentController.text.isNotEmpty ? _commentController.text : null,
      date: Timestamp.fromDate(DateTime.now()), // _formatCurrentDate(),
      imageUrl: uploadedImageUrl,
      ratings: stars,
      selectedCategories: selectedCategoriesString,
    );

    try {
      print('Creating review...');
      BlocProvider.of<ReviewBloc>(context).add(CreateReviewEvent(newReview, widget.restaurant.name));
      _resetFormAndImage();
      _times = 1;
      // TO-DO: show a success message
    } catch (e) {
      // TO-DO: show an error message
    }
  }

  void _resetFormAndImage() {
    _titleController.clear();
    _commentController.clear();
    _image = null; // Asegúrate de que la imagen se resetea correctamente
    _uploadedImageUrl = null; // Resetear la URL de la imagen subida
    setState(() {
      _image = null; // Asegúrate de que la imagen se resetea correctamente
      _uploadedImageUrl = null; // Resetear la URL de la imagen subida
    });
  }
}
