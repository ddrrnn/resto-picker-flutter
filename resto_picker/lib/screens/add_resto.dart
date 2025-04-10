import 'package:flutter/material.dart';
import 'package:resto_picker/local_db.dart';

class AddResto extends StatefulWidget {
  final VoidCallback? onRestaurantAdded;
  final String? initialName;
  final String? initialMenu;
  final int? restaurantId;

  const AddResto({
    super.key,
    this.onRestaurantAdded,
    this.initialName,
    this.initialMenu,
    this.restaurantId,
  });

  @override
  State<AddResto> createState() => _AddRestoState();
}

class _AddRestoState extends State<AddResto> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final List<TextEditingController> _menuControllers = [
    TextEditingController(),
  ];
  final LocalDatabase _localDb = LocalDatabase();
  final ScrollController _scrollController = ScrollController();

  String? _selectedDelivery;
  String? _selectedMeal;
  String? _selectedCuisine;
  String? _selectedLocation;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialName != null) _nameController.text = widget.initialName!;
    if (widget.initialMenu != null) {
      _menuControllers.clear();
      widget.initialMenu!.split(', ').forEach((item) {
        _menuControllers.add(TextEditingController(text: item));
      });
    }

    // Set defaults
    _selectedDelivery = 'Yes';
    _selectedMeal = 'Breakfast';
    _selectedCuisine = 'Filipino';
    _selectedLocation = 'Banwa';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    for (var controller in _menuControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addMenuField() {
    setState(() {
      _menuControllers.add(TextEditingController());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    });
  }

  void _removeMenuField(int index) {
    if (_menuControllers.length > 1) {
      setState(() => _menuControllers.removeAt(index));
    }
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final name = _nameController.text.trim();
      final menuItems = _menuControllers
          .where((controller) => controller.text.isNotEmpty)
          .map((controller) => controller.text.trim())
          .join(', ');

      if (widget.restaurantId != null) {
        // Update restaurant if restaurantId is provided
        await _localDb.updateResto(
          widget.restaurantId!,
          name,
          menuItems,
          _selectedDelivery!,
          _selectedMeal!,
          _selectedCuisine!,
          _selectedLocation!,
        );
      } else {
        // Insert a new restaurant
        await _localDb.insertResto(
          name,
          menuItems,
          _selectedDelivery!,
          _selectedMeal!,
          _selectedCuisine!,
          _selectedLocation!,
        );
      }

      // ✅ Notify parent widget to refresh list
      widget.onRestaurantAdded?.call();

      // ✅ Close dialog after saving
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving restaurant: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDropdown<T>({
    required String label,
    required String? value,
    required List<T> options,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value as T,
      items:
          options.map((T option) {
            return DropdownMenuItem<T>(
              value: option,
              child: Text(option.toString()),
            );
          }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 18,
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
                      Text(
                        widget.restaurantId != null
                            ? 'EDIT RESTO'
                            : 'NEW RESTO',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                      labelText: 'Resto Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 18,
                      ),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter a restaurant name'
                                : null,
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
                                  ),
                                ),
                                if (_menuControllers.length > 1)
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

                  // Dropdowns
                  _buildDropdown<String>(
                    label: 'Delivery',
                    value: _selectedDelivery,
                    options: ['Yes', 'No'],
                    onChanged:
                        (value) => setState(() => _selectedDelivery = value),
                  ),
                  const SizedBox(height: 10),

                  _buildDropdown<String>(
                    label: 'Meal',
                    value: _selectedMeal,
                    options: ['Breakfast', 'Lunch', 'Dinner'],
                    onChanged: (value) => setState(() => _selectedMeal = value),
                  ),
                  const SizedBox(height: 10),

                  _buildDropdown<String>(
                    label: 'Cuisine',
                    value: _selectedCuisine,
                    options: ['Filipino', 'Korean', 'Japanese'],
                    onChanged:
                        (value) => setState(() => _selectedCuisine = value),
                  ),
                  const SizedBox(height: 10),

                  _buildDropdown<String>(
                    label: 'Location',
                    value: _selectedLocation,
                    options: ['Banwa', 'UPV', 'Hollywood'],
                    onChanged:
                        (value) => setState(() => _selectedLocation = value),
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveRestaurant,
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
