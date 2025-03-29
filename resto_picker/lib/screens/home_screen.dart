import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StreamController<int> _controller = StreamController<int>();
  bool _showFilters = false;

  String _selectedLocation = 'Select Location';
  String _selectedType = 'Select Type';
  String _selectedDelivery = 'Yes';

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  void _spinWheel() {
    final random = Random();
    _controller.add(random.nextInt(4));
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
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
                    child: FortuneWheel(
                      selected: _controller.stream,
                      items: const [
                        FortuneItem(child: Text('Option 1')),
                        FortuneItem(child: Text('Option 2')),
                        FortuneItem(child: Text('Option 3')),
                        FortuneItem(child: Text('Option 4')),
                      ],
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
                        onPressed: null,
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
