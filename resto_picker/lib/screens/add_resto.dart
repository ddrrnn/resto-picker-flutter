/*
This file implements the restaurant addition/editing form with:
- Restaurant details input
- Menu item management
- Category selection
- Form validation
*/

import 'package:flutter/material.dart';
import 'package:resto_picker/local_db.dart';

// Screen for adding or editing restaurant information
class AddResto extends StatefulWidget {
  final VoidCallback? onRestaurantAdded;
  final String? initialName;
  final String? initialMenu;
  final int? restaurantId;
  final String? websiteLink;

  const AddResto({
    super.key,
    this.onRestaurantAdded,
    this.initialName,
    this.initialMenu,
    this.restaurantId,
    this.websiteLink,
  });

  @override
  State<AddResto> createState() => _AddRestoState();
}

// manages form data and validation
class _AddRestoState extends State<AddResto> {
  // form key for validation
  final _formKey = GlobalKey<FormState>();

  // controllers for form fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final List<TextEditingController> _menuControllers = [
    TextEditingController(),
  ];
  // database instances
  final LocalDatabase _localDb = LocalDatabase();
  //scroll controller ffor menu items list
  final ScrollController _scrollController = ScrollController();

  // currently selected categories
  Set<String> _selectedDelivery = {};
  Set<String> _selectedMeal = {};
  Set<String> _selectedCuisine = {};
  Set<String> _selectedLocation = {};

  // loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // initialize form with existing resto data values if editing
    if (widget.initialName != null) _nameController.text = widget.initialName!;
    if (widget.initialMenu != null) {
      _menuControllers.clear();
      widget.initialMenu!.split(', ').forEach((item) {
        _menuControllers.add(TextEditingController(text: item));
      });
    }
    if (widget.websiteLink != null && widget.websiteLink != 'None') {
      _websiteController.text = widget.websiteLink!;
    }
    _selectedDelivery = {};
    _selectedMeal = {};
    _selectedCuisine = {};
    _selectedLocation = {};
  }

  @override
  void dispose() {
    // clean up controllers
    _nameController.dispose();
    _scrollController.dispose();
    _websiteController.dispose();
    for (var controller in _menuControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // adds a new empty menu item field
  void _addMenuField() {
    setState(() {
      _menuControllers.add(TextEditingController());
      // WidgetsBinding.instance.addPostFrameCallback((_) {
      //   _scrollController.animateTo(
      //     _scrollController.position.maxScrollExtent,
      //     duration: const Duration(milliseconds: 300),
      //     curve: Curves.easeOut,
      //   );
      // });
    });
  }

  // remove a menu item field at a specified index
  void _removeMenuField(int index) {
    if (_menuControllers.length > 1) {
      setState(() => _menuControllers.removeAt(index));
    }
  }

  // validates and save resto data to database
  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final menuItems = _menuControllers
          .where((controller) => controller.text.isNotEmpty)
          .map((controller) => controller.text.trim())
          .join(', ');
      final website =
          _websiteController.text.trim().isEmpty
              ? 'None'
              : _websiteController.text.trim();

      if (widget.restaurantId != null) {
        // Update restaurant if restaurantId is provided
        await _localDb.updateResto(
          widget.restaurantId!,
          name,
          menuItems,
          _selectedDelivery.join(', ').toLowerCase(),
          _selectedMeal.join(', ').toLowerCase(),
          _selectedCuisine.join(', ').toLowerCase(),
          _selectedLocation.join(', ').toLowerCase(),
          website,
        );
      } else {
        // Insert a new restaurant
        await _localDb.insertResto(
          name,
          menuItems,
          _selectedDelivery.join(', ').toLowerCase(),
          _selectedMeal.join(', ').toLowerCase(),
          _selectedCuisine.join(', ').toLowerCase(),
          _selectedLocation.join(', ').toLowerCase(),
          website,
        );
      }

      // notify parent and close dialog
      widget.onRestaurantAdded?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving restaurant: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Widget _buildDropdown<T>({
  //   required String label,
  //   required String? value,
  //   required List<T> options,
  //   required void Function(T?) onChanged,
  // }) {
  //   return DropdownButtonFormField<T>(
  //     value: value as T,
  //     items:
  //         options.map((T option) {
  //           return DropdownMenuItem<T>(
  //             value: option,
  //             child: Text(option.toString()),
  //           );
  //         }).toList(),
  //     onChanged: onChanged,
  //     decoration: InputDecoration(
  //       labelText: label,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  //       contentPadding: const EdgeInsets.symmetric(
  //         horizontal: 15,
  //         vertical: 18,
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 1,
          maxWidth: MediaQuery.of(context).size.width * 1.4,
        ),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: const Color(0xFFFFF8EE),
          body: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // determine if resto exits or not
                      Text(
                        widget.restaurantId != null
                            ? 'EDIT RESTO'
                            : 'NEW RESTO',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Back Button
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      labelText: 'Resto Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 18,
                      ),
                    ),
                    // validates if value is null or empty
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a restaurant name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // website - Optional
                  TextFormField(
                    controller: _websiteController,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      labelText: 'Website URL (Optional)',
                      hintText: 'https://HellsKitchen.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Please recommend resto menu',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),

                  // Menu Fields
                  Column(
                    children:
                        // maps to all resto pre-populate list
                        _menuControllers.asMap().entries.map((entry) {
                          final index = entry.key;
                          final controller = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: controller,
                                    decoration: InputDecoration(
                                      fillColor: Colors.white,
                                      filled: true,
                                      labelText: 'Menu name',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 15,
                                            vertical: 18,
                                          ),
                                    ),
                                    // validates if menu field is null or empty
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a menu item';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_menuControllers.length > 1)
                                  // button to remove a menu from a resto
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                    ),
                                    onPressed: () => _removeMenuField(index),
                                    padding: const EdgeInsets.only(left: 10),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                  // Add more menu items button
                  TextButton(
                    onPressed: _addMenuField,
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      '+ Add More',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Delivery - Required field
                  Row(
                    children: const [
                      Text(
                        "Delivery",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    children:
                        ['Yes', 'No'].map((option) {
                          return FilterChip(
                            label: Text(option),
                            selected: _selectedDelivery.contains(option),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedDelivery.add(option);
                                } else {
                                  _selectedDelivery.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Meal - Required field
                  Row(
                    children: const [
                      Text(
                        "Meal",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    children:
                        ['Breakfast', 'Lunch', 'Dinner', 'Snacks'].map((
                          option,
                        ) {
                          return FilterChip(
                            label: Text(option),
                            selected: _selectedMeal.contains(option),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedMeal.add(option);
                                } else {
                                  _selectedMeal.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Cuisine - Required field
                  Row(
                    children: const [
                      Text(
                        "Cuisine",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    children:
                        [
                          'Filipino',
                          'Korean',
                          'Japanese',
                          'Italian',
                          'Mexican',
                        ].map((option) {
                          return FilterChip(
                            label: Text(option),
                            selected: _selectedCuisine.contains(option),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedCuisine.add(option);
                                } else {
                                  _selectedCuisine.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Location - Required field
                  Row(
                    children: const [
                      Text(
                        "Location",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        " *",
                        style: TextStyle(color: Colors.red, fontSize: 18),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    children:
                        ['Banwa', 'UPV', 'Hollywood', 'Malagyan'].map((option) {
                          return FilterChip(
                            label: Text(option),
                            selected: _selectedLocation.contains(option),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedLocation.add(option);
                                } else {
                                  _selectedLocation.remove(option);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed:
                        _isSaving
                            ? null
                            : () {
                              // check if there is an empty value on one of the categories
                              if (_selectedDelivery.isEmpty ||
                                  _selectedMeal.isEmpty ||
                                  _selectedCuisine.isEmpty ||
                                  _selectedLocation.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please fill out all fields.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              _saveRestaurant();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child:
                        _isSaving
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : const Text(
                              'SAVE RESTO',
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
          ),
        ),
      ),
    );
  }
}
