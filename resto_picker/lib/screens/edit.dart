import 'package:flutter/material.dart';
import 'package:resto_picker/local_db.dart';
import 'package:resto_picker/screens/add_resto.dart';

class EditScreen extends StatefulWidget {
  final VoidCallback? onRestaurantUpdated;
  final Function(int, String) onRestaurantDeleted; // Added this callback
  const EditScreen({
    super.key,
    this.onRestaurantUpdated,
    required this.onRestaurantDeleted, // Required for deletion callback
  });

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late Future<List<Map<String, dynamic>>> _restaurants;
  final LocalDatabase _localDb = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _refreshRestaurants();
  }

  void _refreshRestaurants() {
    setState(() {
      _restaurants = _localDb.getAllRestaurants();
    });
  }

  Future<void> _deleteRestaurant(int id, String name) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Restaurant'),
            content: Text('Are you sure you want to delete "$name"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
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

    if (shouldDelete ?? false) {
      try {
        final rowsDeleted = await _localDb.deleteRestaurantById(id);
        if (rowsDeleted > 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"$name" deleted successfully')),
            );
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting restaurant: $e')),
          );
        }
      }
    }
  }

  void _editRestaurant(Map<String, dynamic> restaurant) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: AddResto(
              onRestaurantAdded: () {
                if (widget.onRestaurantUpdated != null) {
                  widget.onRestaurantUpdated!();
                }
                _refreshRestaurants();
                Navigator.pop(context); // Close the dialog
              },
              initialName: restaurant['name'] as String,
              initialMenu: restaurant['menu'] as String,
              restaurantId: restaurant['id'] as int, // Add this line
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
              'SPIN',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Restaurant List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _restaurants,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No restaurants added'));
                  } else {
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final restaurant = snapshot.data![index];
                        return GestureDetector(
                          onTap: () => _editRestaurant(restaurant),
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
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
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

            // Add Restaurant Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder:
                      (context) => Dialog(
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                        ),
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
                backgroundColor: Colors.black,
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
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
