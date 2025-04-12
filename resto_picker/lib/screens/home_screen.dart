import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import '../helpers/database_helper.dart';
import '../dialogs/spin_dialog.dart';
import '../dialogs/add_resto_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreamController<int> _controller = StreamController<int>();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<String> _restos = [];
  bool _showFilters = false;

  String _selectedLocation = 'Select Location';
  String _selectedType = 'Select Type';
  String _selectedDelivery = 'Yes';

  @override
  void initState() {
    super.initState();
    _loadRestos();
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  Future<void> _loadRestos() async {
    final restoData = await _dbHelper.getRestos();
    setState(() {
      _restos = restoData.map((e) => e['name'] as String).toList();
    });
  }

  void _spinWheel() {
    if (_restos.isNotEmpty) {
      final random = Random();
      final selected = random.nextInt(_restos.length);
      _controller.add(selected);

      //delay for winner dialog
      Future.delayed(const Duration(seconds: 5), () {
        showDialog(
          context: context,
          builder: (context) {
            final selectedResto = _restos[selected];
            return SpinDialog(restoName: selectedResto);
          },
        );
      });
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (!_showFilters) {
        _applyFilters();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        _restos.isEmpty
                            ? const CircularProgressIndicator()
                            : FortuneWheel(
                              selected: _controller.stream,
                              items:
                                  _restos
                                      .map(
                                        (name) =>
                                            FortuneItem(child: Text(name)),
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
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AddRestaurantDialog(
                                onRestaurantAdded:
                                    _loadRestos, // Pass the callback
                              );
                            },
                          );
                        },
                        child: const Text('EDIT'),
                      ),

                      // UNCOMMENT TO DELETE DATA IN WHEEL
                      // ElevatedButton(
                      //   onPressed: () async {
                      //
                      //     await _dbHelper.clearRestosTemporarily();

                      //
                      //     await _dbHelper.insertRestos([
                      //       'Restaurant A',
                      //       'Restaurant B',
                      //       'Restaurant C',
                      //       'Restaurant D',
                      //     ]);

                      //
                      //     await _loadRestos();

                      //
                      //     ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(
                      //         content: Text(
                      //           'Database cleared and repopulated for this session!',
                      //         ),
                      //       ),
                      //     );
                      //   },
                      //   child: const Text('Clear and Reset Data'),
                      // ),
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
