import 'package:flutter/material.dart';
import 'package:resto_picker/helpers/database_helper.dart';

class AddRestaurantDialog extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();
  final TextEditingController _controller = TextEditingController();
  final VoidCallback onRestaurantAdded; //callback function

  AddRestaurantDialog({Key? key, required this.onRestaurantAdded})
    : super(key: key);

  Future<void> _addRestaurant(BuildContext context) async {
    final newResto = _controller.text;
    if (newResto.isNotEmpty) {
      //insert the new restaurant into the database
      await dbHelper.insertRestos([newResto]);

      //call the callback to update the list of restaurants
      onRestaurantAdded();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$newResto added!')));

      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a restaurant name.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a New Restaurant'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: 'Enter restaurant name'),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => _addRestaurant(context), //call the add function
          child: const Text('Add'),
        ),
      ],
    );
  }
}
