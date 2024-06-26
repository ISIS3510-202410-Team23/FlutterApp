import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foodbook_app/bloc/bookmark_bloc/bookmark_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_bloc.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_event.dart';
import 'package:foodbook_app/bloc/browse_bloc/browse_state.dart';
import 'package:foodbook_app/bloc/review_bloc/food_category_bloc/food_category_state.dart';
import 'package:foodbook_app/bloc/reviewdraft_bloc/reviewdraft_bloc.dart';
import 'package:foodbook_app/data/repositories/bookmark_manager.dart';
import 'package:foodbook_app/data/repositories/reviewdraft_repository.dart';
import 'package:foodbook_app/data/repositories/shared_preferences_repository.dart';
import 'package:foodbook_app/presentation/views/spot_infomation_view/spot_detail_view.dart';
import 'package:foodbook_app/presentation/widgets/restaurant_card/restaurant_card.dart';

// SearchPage2 Widget
class SearchPage2 extends StatefulWidget {
  final BrowseBloc browseBloc;
  const SearchPage2({Key? key, required this.browseBloc}) : super(key: key);

  @override
  _SearchPage2State createState() => _SearchPage2State();
}

class _SearchPage2State extends State<SearchPage2> {
  late BrowseBloc browseBloc;

  @override
  void initState() {
    super.initState();
    browseBloc = widget.browseBloc;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width, // Adjust the width as needed
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use as little space as needed
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              browseBloc.add(SearchButtonPressed2(query: ''));
              showSearch(
                context: context,
                delegate: CustomSearchDelegate(browseBloc: browseBloc),
              );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
              backgroundColor: Colors.grey[200],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, color: Colors.grey),
                SizedBox(width: 10),
                Text("Search", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// CustomSearchDelegate Widget
class CustomSearchDelegate extends SearchDelegate<String> {
  final BrowseBloc browseBloc;
  final SharedPreferencesRepository repository = SharedPreferencesRepository();

  CustomSearchDelegate({required this.browseBloc});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          browseBloc.add(SearchButtonPressed2(query: query));
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
        browseBloc.add(LoadRestaurants());
      },
    );
  }


  @override
  Widget buildResults(BuildContext context) {
    browseBloc.add(SearchButtonPressed2(query: query));
    return MultiBlocProvider(
      providers: [
        BlocProvider<BrowseBloc>(
          create: (context) => browseBloc,
        ),
        BlocProvider<BookmarkBloc>(
          create: (context) => BookmarkBloc(BookmarkManager()),
        ),
      ],
      child: BlocBuilder<BrowseBloc, BrowseState>(
        bloc: browseBloc,
        builder: (context, state) {
          if (state is SearchLoading2) {
            if (query != '' && query.length < 25) {
              browseBloc.add(FilterRestaurants(name: query));
            }
            else if (query.length >= 25) {
              browseBloc.add(TooLongSearch(query: query));
            }
            return const Center(child: CircularProgressIndicator());
          } else if (state is RestaurantsLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }else if (state is SearchBlocked){
            return const Center(child: Text("Search limit is 25 characters"));
          }
          
          else if (state is RestaurantsLoadSuccess) {
            return ListView.builder(
              itemCount: state.restaurants.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MultiBlocProvider(
                          providers: [
                            BlocProvider<ReviewDraftBloc>(
                              create: (context) => ReviewDraftBloc(
                                  RepositoryProvider.of<ReviewDraftRepository>(context)),
                            ),
                          ],
                          child: SpotDetail(restaurantId: state.restaurants[index].id),
                        ),
                      ),
                    );
                  },
                  child: RestaurantCard(restaurant: state.restaurants[index]),
                );
              },
            );
          } 
          if (state is RestaurantsLoadFailure) {
            return Center(child: Text("Failed to load restaurants: ${state.error}",
            textAlign: TextAlign.center,));
          }
          else {
            return Center(child: Text("No results found for: $query"));
          }
        },
      )
  
    );
  }



  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: repository.getSearchHistory(),
      builder: (context, snapshot) {
        final suggestions = snapshot.data!;
        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = suggestions[index];
            return ListTile(
              title: Text(suggestion),
              onTap: () {
                query = suggestion; // Set the suggestion as the initial query
                browseBloc.add(SearchButtonPressed2(query: query));
                buildResults(context); // Show the search results immediately
              },
            );
          },
        );
      },
    );
  }

  @override
  void close(BuildContext context, String result) {
    super.close(context, result);
    //browseBloc.add(LoadRestaurants());
  }
} 
// @override
// Widget build(BuildContext context) {
//   return Scaffold(
//     appBar: AppBar(
//       backgroundColor: Colors.white,
//       title: const Text('Search Page'),
//     ),
//     body: Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               // Trigger your search functionality here
//               // For example, dispatch an event if using bloc
//               // browseBloc.add(SearchButtonPressed2(query: ''));
//               showSearch(
//                 context: context,
//                 delegate: CustomSearchDelegate(), // Custom search delegate
//               );
//             },
//           ),
//           const SizedBox(height: 20), // Adjust as needed
//           const Text('Search Content Goes Here'),
//         ],
//       ),
//     ),
//   );
// }
