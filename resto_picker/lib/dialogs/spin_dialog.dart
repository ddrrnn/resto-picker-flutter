import 'package:flutter/material.dart';
import 'dart:math';
import 'package:resto_picker/local_db.dart';

class SpinDialog extends StatelessWidget {
  final String restoName;
  final LocalDatabase _localDb = LocalDatabase();

  SpinDialog({super.key, required this.restoName});

  Future<List<String>> _getMenuForRestaurant() async {
    final db = await _localDb.database;
    final result = await db.query(
      'restaurants',
      columns: ['menu'],
      where: 'name = ?',
      whereArgs: [restoName],
    );

    if (result.isNotEmpty) {
      final menuString = result.first['menu'] as String;
      final menuItems = menuString.split(',').map((e) => e.trim()).toList();
      return menuItems;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _getMenuForRestaurant(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return AlertDialog(
            title: Text('No Menu Available'),
            content: Text('No menu items available for this restaurant.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        } else {
          final menuItems = snapshot.data!;

          final random = Random();
          menuItems.shuffle(random);
          final randomItems = menuItems.take(3).toList();

          return AlertDialog(
            title: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10, bottom: 0.0),
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              color: Color(0xFFFDE648),
              child: Text(
                restoName.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Righteous',
                  color: Colors.black,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Try these out today!", textAlign: TextAlign.center),
                SizedBox(height: 10),

                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.zero,
                  ),
                  width: 250,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:
                        randomItems.map((dish) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Text(
                              dish,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.black, width: 2),
            ),
            backgroundColor: Color(0xFFFDFBF7),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('BACK', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 50),
                  backgroundColor: Colors.white,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: BorderSide(color: Colors.black, width: 1),
                  ),
                  textStyle: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
