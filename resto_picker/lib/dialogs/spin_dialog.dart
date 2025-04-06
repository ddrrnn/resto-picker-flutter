import 'package:flutter/material.dart';

class SpinDialog extends StatelessWidget {
  final String restoName;

  const SpinDialog({super.key, required this.restoName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        restoName.toUpperCase(),
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: const Text(
        "Try these out today!\n(Insert three menu dishes)",
        textAlign: TextAlign.center,
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('SPIN AGAIN'),
        ),
      ],
    );
  }
}
