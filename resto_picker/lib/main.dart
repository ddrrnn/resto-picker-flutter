import 'package:flutter/material.dart';
import 'package:resto_picker/screens/splash_screen.dart';
import 'package:resto_picker/helpers/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dbHelper = DatabaseHelper();

  final existingRestos = await dbHelper.getRestos();
  print('Existing restos in DB: $existingRestos');

  final existingNames = existingRestos.map((e) => e['name'] as String).toSet();

  final defaultRestos = [
    'Restaurant A',
    'Restaurant B',
    'Restaurant C',
    'Restaurant D',
    'Vineyard',
    'El Garaje',
  ];

  final toInsert = //newly added restos
      defaultRestos.where((r) => !existingNames.contains(r)).toList();

  if (toInsert.isNotEmpty) {
    await dbHelper.insertRestos(toInsert);
  } else {
    print('All default restos already in DB.'); //debugging
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resto Picker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
    );
  }
}
