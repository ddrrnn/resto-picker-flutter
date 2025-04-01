import 'package:flutter/material.dart';
import 'package:resto_picker/local_db.dart';

class EditScreen extends StatefulWidget {
  const EditScreen({super.key});

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late Future<List<String>> _restaurantNames;
  final LocalDatabase _localDb = LocalDatabase();

  @override
  void initState() {
    super.initState();
    _refreshRestaurants();
  }

  void _refreshRestaurants() {
    setState(() {
      _restaurantNames = _localDb.getRestaurantNames();
    });
  }

  Future<void> _deleteRestaurant(String name) async {
    // await _localDb.deleteRestaurant(name);
    _refreshRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Material(
        color: const Color(0xFFFFF8EE),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 30),
              const SizedBox(height: 30),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _restaurantNames,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('Please Add a Resto on the List'),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final name = snapshot.data![index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(name),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _deleteRestaurant(name),
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  //  add restaurant functionality
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Restaurant'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
