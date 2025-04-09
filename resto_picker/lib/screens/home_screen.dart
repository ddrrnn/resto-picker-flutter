import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:resto_picker/screens/edit.dart';
import 'package:resto_picker/dialogs/spin_dialog.dart';
import 'package:resto_picker/local_db.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamController<int> _controller = StreamController<int>.broadcast();
  List<String> _restaurantNames = [];
  bool _showFilters = false;

  final LocalDatabase _localDb = LocalDatabase();

  String _selectedLocation = 'Select Location';
  String _selectedType = 'Select Type';
  String _selectedDelivery = 'Yes';

  @override
  void initState() {
    super.initState();
    _loadRestaurants(); // Changed from directly assigning _restaurantNames
  }

  Future<void> _loadRestaurants() async {
    try {
      final names = await _localDb.getRestaurantNames();
      setState(() {
        _restaurantNames = names;
        // Recreate controller to ensure fresh stream
        _controller.close();
        _controller = StreamController<int>.broadcast();
      });
    } catch (e) {
      //debugging
      ('Error loading restaurants: $e');
    }
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _spinWheel() {
    if (_restaurantNames.isNotEmpty) {
      final random = Random();
      final selected = random.nextInt(_restaurantNames.length);
      _controller.add(selected);

      //delay for winner dialog
      Future.delayed(const Duration(seconds: 5), () {
        showDialog(
          context: context,
          builder: (context) {
            final selectedResto = _restaurantNames[selected];
            return SpinDialog(restoName: selectedResto);
          },
        );
      });
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  // ========== MODIFIED: Added callback and refresh ==========
  void _editScreen() {
    showPopupCard(
      context: context,
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            minWidth: 300,
            minHeight: 300,
          ),
          child: PopupCard(
            elevation: 8,
            color: const Color(0xFFFFF8EE),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: EditScreen(
                    onRestaurantUpdated:
                        _loadRestaurants, // NEW: Added callback
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _loadRestaurants()); // NEW: Refresh after popup closes
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFFF8EE),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_showFilters) {
            setState(() {
              _showFilters = false;
            });
          }
        },
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child:
                        _restaurantNames.isEmpty
                            ? const CircularProgressIndicator()
                            : FortuneWheel(
                              selected: _controller.stream,

                              items:
                                  _restaurantNames
                                      .map(
                                        (name) => FortuneItem(
                                          child: Text(name),
                                          style: FortuneItemStyle(
                                            color:
                                                Colors
                                                    .primaries[_restaurantNames
                                                        .indexOf(name) %
                                                    Colors.primaries.length],
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                            ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _spinWheel,
                        child: const Text('SPIN'),
                      ),
                      const SizedBox(width: 20),

                      ElevatedButton(
                        onPressed: _editScreen,
                        child: const Text('EDIT'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Positioned(
              top: 10,
              left: 10,
              child: GestureDetector(
                onTap: _toggleFilters,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 47,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFEA3EF7),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x33000000),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    SvgPicture.asset(
                      'lib/assets/filter_svg.svg',
                      width: 24,
                      height: 24,
                    ),
                  ],
                ),
              ),
            ),

            if (_showFilters)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('Location: '),
                            DropdownButton<String>(
                              value: _selectedLocation,
                              items:
                                  <String>[
                                    'Select Location',
                                    'Banwa',
                                    'UPV',
                                    'Hollywood',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedLocation = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Text('Type: '),
                            DropdownButton<String>(
                              value: _selectedType,
                              items:
                                  <String>[
                                    'Select Type',
                                    'Local Dish',
                                    'Korean',
                                    'Takeout',
                                    'Lunch',
                                  ].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedType = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Row(
                          children: [
                            const Text('Delivery: '),
                            DropdownButton<String>(
                              value: _selectedDelivery,
                              items:
                                  <String>['Yes', 'No'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDelivery = newValue!;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
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
