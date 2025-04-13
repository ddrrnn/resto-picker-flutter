/*
This file implements the dialog that appears after spinning the wheel,
showing restaurant details including:
- Selected restaurant name
- Random menu recommendations
- Facebook page link (if available)
*/

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:resto_picker/local_db.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Data class holding restaurant menu information
class RestaurantMenuData {
  // list of menu items of the selected resto
  final List<String> menuItems;
  final String website;

  RestaurantMenuData({required this.menuItems, required this.website});
}

// Dialog that displays spin results with restaurant information
class SpinDialog extends StatelessWidget {
  final String restoName;
  final LocalDatabase _localDb = LocalDatabase();

  // creates a SpinDialog with the selected resto name
  SpinDialog({super.key, required this.restoName});

  // fetches resto menu and website from database
  Future<RestaurantMenuData> _getMenuForRestaurant() async {
    final db = await _localDb.database;
    final result = await db.query(
      'restaurants',
      columns: ['menu', 'website'],
      where: 'name = ?',
      whereArgs: [restoName],
    );

    if (result.isNotEmpty) {
      final menuString = result.first['menu'] as String;
      final website = result.first['website'] as String;
      final menuItems = menuString.split(',').map((e) => e.trim()).toList();
      return RestaurantMenuData(menuItems: menuItems, website: website);
    } else {
      return RestaurantMenuData(menuItems: [], website: '');
    }
  }

  // Launches the restaurant's website/facebook page
  // Handles special cases for Facebook URLs (tries app first, then web)
  Future<void> _launchURL(String websiteurl, BuildContext context) async {
    if (websiteurl.isEmpty || websiteurl == 'None') return;

    try {
      // Clean the URL string
      String formattedUrl = websiteurl.trim();
      debugPrint('Original URL: $formattedUrl');

      // Remove common problematic characters
      formattedUrl = formattedUrl.replaceAll('@', '');

      // Fix protocol issues
      formattedUrl = formattedUrl
          .replaceAll('https//', 'https://')
          .replaceAll('http//', 'http://')
          .replaceAll('https://https://', 'https://');

      // Ensure proper protocol prefix
      if (!formattedUrl.startsWith('http')) {
        formattedUrl = 'https://$formattedUrl';
      }

      // Special handling for Facebook URLs
      if (formattedUrl.contains('facebook.com')) {
        // Remove any duplicate 'www.'
        formattedUrl = formattedUrl.replaceAll('www.www.', 'www.');
        // Ensure exactly one 'www.'
        if (!formattedUrl.contains('www.')) {
          formattedUrl = formattedUrl.replaceFirst(
            'facebook.com',
            'www.facebook.com',
          );
        }
      }

      debugPrint('Final URL: $formattedUrl');
      final uri = Uri.parse(formattedUrl);

      // Launch with multiple fallback strategies
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Fallback to in-app WebView
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      debugPrint('URL Launch Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open link'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<RestaurantMenuData>(
      future: _getMenuForRestaurant(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
          // shows an alert dialog if selected resto has no menu items
        } else if (!snapshot.hasData || snapshot.data!.menuItems.isEmpty) {
          return AlertDialog(
            title: const Text('No Menu Available'),
            content: const Text('No menu items available for this restaurant.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        } else {
          // builds the main result dialog with resto info ( 3 random manu item and website link)
          final menuItems = snapshot.data!.menuItems;
          final website = snapshot.data!.website;

          final random = Random();
          // shuffle and select 3 random menu item
          menuItems.shuffle(random);
          final randomItems = menuItems.take(3).toList();

          // main result dialog
          return AlertDialog(
            title: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10, bottom: 0.0),
              padding: const EdgeInsets.symmetric(vertical: 15.0),
              color: const Color(0xFFFDE648),
              child: Text(
                restoName.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Righteous',
                  color: Colors.black,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Try these out today!", textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 1),
                    borderRadius: BorderRadius.zero,
                  ),
                  width: 250,
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:
                        // display the 3 random resto menu item
                        randomItems.map((dish) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5.0),
                            child: Text(
                              dish,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),

                // website link

                // Show Facebook link if available
                if (website.isNotEmpty &&
                    website != 'None' &&
                    website.contains('facebook.com')) ...[
                  const SizedBox(height: 15),
                  GestureDetector(
                    // call the launchURL
                    onTap: () => _launchURL(website, context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // facebook icon
                        const FaIcon(
                          FontAwesomeIcons.facebook,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        // visit text
                        Text(
                          'Visit their Page',
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            backgroundColor: const Color(0xFFFDFBF7),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              // builds the back button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'BACK',
                  style: TextStyle(color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                    side: const BorderSide(color: Colors.black, width: 1),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}
