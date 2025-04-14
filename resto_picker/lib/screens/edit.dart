// ignore_for_file: empty_statements

/* 
This file implements the restaurant editing screen where users can:
- View all restaurants
- Edit existing restaurants
- Delete restaurants
- Add new restaurants

*/
import 'package:flutter/material.dart';
import 'package:resto_picker/local_db.dart';
import 'package:resto_picker/screens/add_resto.dart';

// Screen for managing restaurants (edit, delete, add)
class EditScreen extends StatefulWidget {
  // triggers a refresh on parent.
  final VoidCallback? onRestaurantUpdated;
  final Function(int, String) onRestaurantDeleted;
  final String? websiteLink;

  const EditScreen({
    super.key,
    this.onRestaurantUpdated,
    required this.onRestaurantDeleted, // Required for deletion callback
    this.websiteLink,
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

// Manages restaurants data and UI
class _EditScreenState extends State<EditScreen> {
  // Future list of all restaurants.
  late Future<List<Map<String, dynamic>>> _restaurants;
  final LocalDatabase _localDb = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _refreshRestaurants();
  }

  // refreshes the resto list from the database
  void _refreshRestaurants() {
    setState(() {
      _restaurants = _localDb.getAllRestaurants();
    });
  }

  // shows modal dialog to confirm deletion of a resto
  Future<void> _deleteRestaurant(int id, String name) async {
    // determines if resto will be deleted or not
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          // shows an alert dialog
          (context) => AlertDialog(
            title: const Text('Delete Restaurant'),
            content: Text('Are you sure you want to delete "$name"?'),
            actions: [
              // Cancel Buton
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              // Delete Button
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    // if user tap confirm
    if (shouldDelete ?? false) {
      try {
        // call db delete function
        final rowsDeleted = await _localDb.deleteRestaurantById(id);
        if (rowsDeleted > 0) {
          if (mounted) {
            // show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"$name" deleted successfully')),
            );
            // notify parent widgets
            widget.onRestaurantDeleted(
              id,
              name,
            ); // Notify HomeScreen about the deletion
            if (widget.onRestaurantUpdated != null) {
              widget
                  .onRestaurantUpdated!(); // Notify parent widget to refresh the list
            }
            // Manually trigger a refresh
            setState(() {
              _restaurants = _localDb.getAllRestaurants();
            });
          }
        } else {
          // Handle case when no rows were deleted
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Restaurant not found.')),
            );
          }
        }
      } catch (e) {
        // show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting restaurant: $e')),
          );
        }
      }
    }
  }

  /*
  Open edit dialog for a resto
  */
  void _editRestaurant(Map<String, dynamic> restaurant) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            // calls on AddResto from add_resto.dart
            child: AddResto(
              onRestaurantAdded: () {
                if (widget.onRestaurantUpdated != null) {
                  widget.onRestaurantUpdated!();
                }
                _refreshRestaurants();
                Navigator.pop(context); // Close the dialog
              },
              // prefills fields using the selected restaurant’s data.
              initialName: restaurant['name'] as String,
              initialMenu: restaurant['menu'] as String,
              restaurantId: restaurant['id'] as int,
              websiteLink: restaurant['website'] as String,
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EE),
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Text(
              'RESTOS',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Restaurant List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                // fetch restaurant list
                future: _restaurants,
                builder: (context, snapshot) {
                  // loading spinner while waiting.
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                    // shows error or empty message.
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No restaurants added'));
                  } else {
                    // display list of restaurant
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final restaurant = snapshot.data![index];
                        return GestureDetector(
                          // if a resto is tap, it opens the edit dialog
                          onTap: () => _editRestaurant(restaurant),
                          // each resto container that shows its name and delete icon
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(),
                                  blurRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            // list of resto names and each have a delete icon
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  restaurant['name'] as String,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed:
                                      // call deleteRestaurant if delete icon is tap
                                      () => _deleteRestaurant(
                                        restaurant['id'] as int,
                                        restaurant['name'] as String,
                                      ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // Builds the "Add Restaurant" button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              // button opens a dialog for adding a new restaurant.
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => Dialog(
                          insetPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          // calls AddResto from add_resto.dart
                          child: AddResto(
                            onRestaurantAdded: () {
                              if (widget.onRestaurantUpdated != null) {
                                widget.onRestaurantUpdated!();
                              }
                              _refreshRestaurants();
                              Navigator.pop(context); // Close the dialog
                            },
                          ),
                        ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '+ Add Resto',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
