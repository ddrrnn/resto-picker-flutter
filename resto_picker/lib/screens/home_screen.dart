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
  List<Map<String, dynamic>> _allRestaurants = [];
  bool _isSpinning = false;
  bool _dialogShown = false;

  // Different Filter state and options
  // Dito lang mag add
  bool _showFilters = false;
  final Map<String, List<String>> _filterOptions = {
    'Delivery': ['yes', 'no'],
    'Meal': ['breakfast', 'lunch', 'dinner', 'snacks'],
    'Cuisine': ['filipino', 'korean', 'japanese', 'italian', 'mexican'],
    'Location': ['banwa', 'upv', 'hollywood', 'malagyan'],
  };

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
      _allRestaurants = data;
      _applyFilters();
    });
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _applyFilters() {
    print("Applying filters...");

    setState(() {
      _restaurantNames =
          _allRestaurants
              .where((resto) {
                for (var category in _selectedFilters.keys) {
                  final selectedValues = _selectedFilters[category]!;

                  if (selectedValues.isNotEmpty) {
                    final rawValue =
                        resto[category.toLowerCase()]?.toString().toLowerCase();
                    if (rawValue == null) {
                      print(
                        "Excluding restaurant ${resto['name']} due to missing $category",
                      );
                      return false;
                    }

                    final restoValues =
                        rawValue.split(',').map((e) => e.trim()).toSet();
                    print(
                      "Checking $category filter: $selectedValues against $restoValues",
                    );

                    if (!selectedValues.any(
                      (selected) => restoValues.contains(selected),
                    )) {
                      print(
                        "Excluding restaurant ${resto['name']} due to $category filter",
                      );
                      return false;
                    }
                  }
                }

                print("Including restaurant ${resto['name']}");
                return true;
              })
              .map((e) => e['name'] as String)
              .toList();

      print("Filtered restaurants: $_restaurantNames");

      if (_restaurantNames.isEmpty) {
        Future.delayed(Duration.zero, () {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  title: const Text("No restaurants found"),
                  content: const Text("Try changing your filters."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
          );
        });
      }
    });
  }

  Key _wheelKey = UniqueKey();

  void _spinWheel() {
    _applyFilters();
    if (_restaurantNames.isNotEmpty) {
      final random = Random();
      final selected = random.nextInt(_restaurantNames.length);

      if (_restaurantNames.isNotEmpty &&
          _restaurantNames.length >= 2 &&
          !_isSpinning) {
        setState(() {
          _isSpinning = true;
        });

        if (selected >= 0 && selected < _restaurantNames.length) {
          _controller.add(selected);
          setState(() {
            _wheelKey = UniqueKey();
          });

          print("Selected restaurant index: $selected");
          print("Selected restaurant: ${_restaurantNames[selected]}");

          Future.delayed(const Duration(seconds: 5), () {
            setState(() {
              _isSpinning = false;
            });

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
  }

  bool _isSpinButtonEnabled() {
    return _restaurantNames.isNotEmpty &&
        _restaurantNames.length >= 2 &&
        !_isSpinning;
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (!_showFilters) {
        _applyFilters(); // Apply filters when closing the filter panel
      }
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
      Color(0xFFA5EAD8),
      Color(0xFFFDE648),
      Color(0xFFA467E8),
      Color(0xFFF566BE),
      Color(0xFF00C3F9),
      Color(0xFFBC6BB7),
    ];

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
          //CAPITALIZE THE FIRST LETTER OF EACH OPTION
          _filterOptions[category]!.map((option) {
            String capitalizedOption =
                option[0].toUpperCase() + option.substring(1);

            return CheckboxListTile(
              title: Text(capitalizedOption),
              value: _selectedFilters[category]!.contains(option),
              onChanged: (bool? value) {
                _handleFilter(category, option, value ?? false);
              },
            );
          }).toList(),
    );
  }

  Widget _filterTag(String category, String value) {
    return Chip(
      label: Text('$category: $value'),
      onDeleted: () => _removeFilter(category, value),
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }

  Widget _selectedFiltersTag() {
    final chips = <Widget>[];
    _selectedFilters.forEach((category, values) {
      for (var value in values) {
        chips.add(_filterTag(category, value));
      }
    });
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  void _showSpinDialog(String restoName) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SpinDialog(restoName: restoName);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_restaurantNames.length == 1 && !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSpinDialog(_restaurantNames[0]);
        setState(() {
          _dialogShown = true;
        });
      });
    }

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
                            ? Center(
                              child: Text(
                                "No restaurants to spin.",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                            : _restaurantNames.length == 1
                            ? Center(
                              child: Text(
                                "Need at least 2 restaurants to spin!",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
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
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            style: FortuneItemStyle(
                                              color: _getColorForIndex(index),
                                              borderWidth: 0,
                                              borderColor: Colors.transparent,
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
                        onPressed: _isSpinButtonEnabled() ? _spinWheel : null,
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
                  Positioned(
                    child: GestureDetector(
                      onTap: () {
                        _applyFilters();
                        _toggleFilters();
                      },
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
                      child: Scrollbar(
                        thumbVisibility: true,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
