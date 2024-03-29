import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_state.dart';
import 'package:foodbook_app/presentation/views/spot_infomation_view/spot_detail_view.dart';
import 'package:foodbook_app/presentation/widgets/menu/navigation_bar.dart';
import 'package:foodbook_app/presentation/widgets/menu/filter_bar.dart';
import 'package:foodbook_app/presentation/widgets/restaurant_card/restaurant_card.dart';



class BrowseView extends StatelessWidget {
  BrowseView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white, // Set AppBar background to white
        title: const Text(
          'Browse',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black, // Title color
          ),
        ),
        // Add the FilterBar widget to the AppBar
        actions: [
          FilterBar(),
        ],
        elevation: 0, // Remove shadow
      ),
      backgroundColor: Colors.grey[200], // Set the background color to grey
      body: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 255, 255, 255), // White background color for search bar container
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0), // Horizontal padding only
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 5), // Reduced vertical padding to make the search bar thinner
                filled: true,
                fillColor: const Color.fromARGB(2192, 217, 219, 225), // Search bar fill color
              ),
            ),
          ),
          Divider(
            height: 1, // Height of the divider line
            color: Colors.grey[300], // Color of the divider line
          ),
          Expanded(
            child: BlocBuilder<BrowseBloc, BrowseState>(
              builder: (context, state) {
                if (state is RestaurantsLoadInProgress) {
                  return const Center(child: CircularProgressIndicator());
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
                              builder: (context) => SpotDetail(restaurant: state.restaurants[index]),
                            ),
                          );
                        },
                        child: RestaurantCard(restaurant: state.restaurants[index]),
                      );
                    }
                  );
                } else if (state is RestaurantsLoadFailure) {
                  return const Center(child: Text('Failed to load restaurants'));
                }
                // Si el estado inicial es RestaurantsInitial o cualquier otro estado no esperado
                return const Center(child: Text('Start browsing by applying some filters!'));
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: 0, // Set the selected index to 1
        onItemTapped: (int index) {
          // Handle navigation to different views
          if (index == 1) {
            Navigator.pushNamed(context, 'package:foodbook_app/presentation/views/restaurant_views/login_view.dart');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/bookmarks');
          }
        },
      ),
    );
  }
}


