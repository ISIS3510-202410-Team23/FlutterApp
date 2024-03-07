import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_state.dart';
import 'package:foodbook_app/presentation/widgets/menu/navigation_bar.dart';
import 'package:foodbook_app/presentation/widgets/restaurant_card/restaurant_card.dart';
import 'package:foodbook_app/data/models/restaurant.dart';

class ForYouView extends StatelessWidget {
  ForYouView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white, // Set AppBar background to white
        title: const Text(
          'For You',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Title color
          ),
        ),
        elevation: 10, // Remove shadow
      ),
      backgroundColor: Colors.grey[200], // Set the background color to grey
      body: Column(
        children: [
          Divider(
            height: 1, // Height of the divider line
            color: Colors.grey[300], // Color of the divider line
          ),
          Expanded(
            child: BlocBuilder<BrowseBloc, BrowseState>(
              builder: (context, state) {
                if (state is RestaurantsLoadInProgress) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is RestaurantsLoadSuccess) {
                  return ListView.builder(
                    itemCount: state.restaurants.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          // Navigate to another view when the restaurant card is clicked
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnotherView(restaurant: state.restaurants[index]),
                            ),
                          );
                        },
                        child: RestaurantCard(restaurant: state.restaurants[index]),
                      );
                    }
                  );
                } else if (state is RestaurantsLoadFailure) {
                  return Center(child: Text('Failed to load restaurants'));
                }
                // Si el estado inicial es RestaurantsInitial o cualquier otro estado no esperado
                return Center(child: Text('Start browsing by applying some filters!'));
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: 1, // Set the selected index to 1
        onItemTapped: (int index) {
          // Handle navigation to different views
          if (index == 0) {
            Navigator.pushNamed(context, '/browse');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/bookmarks');
          }
        },
      ),
    );
  }


}


class AnotherView extends StatelessWidget {
  final Restaurant restaurant;

  const AnotherView({Key? key, required this.restaurant}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.name), // Display the restaurant's name in the AppBar
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Display various restaurant details here
            // For example, an image if available
            if (restaurant.imagePaths.isNotEmpty)
              Image.network(restaurant.imagePaths.first),
            // You can add more details like the restaurant's description, menu, etc.
          ],
        ),
      ),
    );
  }
}