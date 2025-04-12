import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:math';
import 'dart:async';
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
  final LocalDatabase _localDb = LocalDatabase();

  // Different Filter state and options
  // Dito lang mag add
  bool _showFilters = false;
  final Map<String, List<String>> _filterOptions = {
    'Delivery': ['Yes', 'No'],
    'Meal': ['Breakfast', 'Lunch', 'Dinner'],
    'Cuisine': ['Filipino', 'Korean', 'Japanese'],
    'Location': ['Banwa', 'UPV', 'Hollywood'],
  };
  // Store selected Filters used to create tags at the bottom
  final Map<String, Set<String>> _selectedFilters = {
    'Delivery': {},
    'Meal': {},
    'Cuisine': {},
    'Location': {},
  };

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    final data = await _localDb.getAllRestaurants();
    setState(() {
      _restaurantNames = data.map((e) => e['name'] as String).toList();
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Key _wheelKey = UniqueKey();

  void _spinWheel() {
    if (_restaurantNames.isNotEmpty) {
      final random = Random();
      final selected = random.nextInt(_restaurantNames.length);

      // Ensure the selected index is within the valid range.
      if (selected >= 0 && selected < _restaurantNames.length) {
        _controller.add(selected);
        setState(() {
          _wheelKey = UniqueKey();
        });

        print("Selected restaurant index: $selected");
        print("Selected restaurant: ${_restaurantNames[selected]}");

        Future.delayed(const Duration(seconds: 5), () {
          showDialog(
            context: context,
            builder: (context) {
              final selectedResto = _restaurantNames[selected];
              return SpinDialog(restoName: selectedResto);
            },
          );
        });
      } else {
        print("Error: Invalid restaurant index");
      }
    } else {
      print("Error: No restaurants available to spin");
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

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
                    onRestaurantUpdated: _loadRestaurants,
                    onRestaurantDeleted: (id, name) {
                      // Handle restaurant deletion callback
                      setState(() {
                        _restaurantNames.removeWhere(
                          (restaurant) => restaurant == name,
                        );
                      });
                    },
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
    ).then((_) => _loadRestaurants());
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Color(0xFFA5EAD8), // A5EAD8
      Color(0xFFFDE648), // FDE648
      Color(0xFFA467E8), // A467E8
      Color(0xFFF566BE), // F566BE
      Color(0xFF00C3F9), // 00C3F9
      Color(0xFFBC6BB7), // BC6BB7
    ];

    // Ensure that we cycle through the colors if we have more items than colors
    return colors[index % colors.length];
  }

  // Store in selectedFilter if user check the item and remove if not
  void _handleFilter(String category, String value, bool selected) {
    setState(() {
      if (selected) {
        _selectedFilters[category]!.add(value);
      } else {
        _selectedFilters[category]!.remove(value);
      }
    });
  }

  // For filter tag delete
  void _removeFilter(String category, String value) {
    setState(() {
      _selectedFilters[category]!.remove(value);
    });
  }

  Widget _buildFilterDropdown(String category) {
    return ExpansionTile(
      title: Text(category),
      children:
          _filterOptions[category]!.map((option) {
            // creates checkboxes
            return CheckboxListTile(
              title: Text(option),
              value: _selectedFilters[category]!.contains(option),
              onChanged: (bool? value) {
                // call function to create tag
                _handleFilter(category, option, value ?? false);
              },
            );
          }).toList(),
    );
  }

  // Create EACH filter tag
  Widget _filterTag(String category, String value) {
    return Chip(
      label: Text('$category: $value'),
      onDeleted: () => _removeFilter(category, value),
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }

  // creates and displays filter tags at the bottom of the filter dropdowns
  Widget _selectedFiltersTag() {
    final chips = <Widget>[];
    _selectedFilters.forEach((category, values) {
      for (var value in values) {
        // add each filter created in the _filtertag
        chips.add(_filterTag(category, value));
      }
    });
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
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
                                      .asMap()
                                      .map(
                                        (index, name) => MapEntry(
                                          index,
                                          FortuneItem(
                                            child: Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight:
                                                    FontWeight
                                                        .bold, // Make the text bold
                                                color:
                                                    Colors
                                                        .white, // Set text color to white
                                              ),
                                            ),
                                            style: FortuneItemStyle(
                                              color: _getColorForIndex(
                                                index,
                                              ), // Assign a fixed color based on index
                                              borderWidth:
                                                  0, // Remove the border width
                                              borderColor:
                                                  Colors
                                                      .transparent, // Remove border color
                                            ),
                                          ),
                                        ),
                                      )
                                      .values
                                      .toList(),
                            ),
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _spinWheel,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 80,
                            vertical: 20,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 1),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('SPIN'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _editScreen,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.black, width: 1),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                          width: 2,
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
                    Image.asset(
                      'lib/assets/fil_svg.png',
                      width: 50,
                      height: 50,
                    ),
                  ],
                ),
              ),
            ),

            // Filter Page
            if (_showFilters)
              Stack(
                children: [
                  // prevents taps outside the filter page
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {}, // Empty onTap prevents closing
                      behavior: HitTestBehavior.opaque,
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      // added contraints to control page height limit
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.5,
                      ),
                      // Enable scrolling in the filter page
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back button
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: _toggleFilters,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Filters',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Filter dropdowns
                              ..._filterOptions.keys.map(
                                (category) => _buildFilterDropdown(category),
                              ),

                              const SizedBox(height: 16),

                              // Selected filters
                              if (_selectedFilters.values.any(
                                (values) => values.isNotEmpty,
                              ))
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selected Filters:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _selectedFiltersTag(),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
