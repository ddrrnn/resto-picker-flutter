import 'package:flutter/material.dart';
import 'dart:math';
import 'package:resto_picker/local_db.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RestaurantMenuData {
  final List<String> menuItems;
  final String website;

  RestaurantMenuData({required this.menuItems, required this.website});
}

class SpinDialog extends StatelessWidget {
  final String restoName;
  final LocalDatabase _localDb = LocalDatabase();

  SpinDialog({super.key, required this.restoName});

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

  // for website redirect function
  Future<void> _launchURL(String websiteurl, BuildContext context) async {
    // should be not empty to display the link
    if (websiteurl.isEmpty || websiteurl == 'None') return;

    try {
      // declare URL
      String formattedUrl = websiteurl.trim();

      // if website link contains facebook.com
      if (formattedUrl.contains('facebook.com')) {
        // enable both app and web redirection
        final webUrl =
            formattedUrl.startsWith('http')
                ? formattedUrl
                : 'https://$formattedUrl';
        final appUrl = webUrl.replaceFirst('https://www.', 'fb://');

        try {
          // launc mobile app
          await launchUrl(
            Uri.parse(appUrl),
            mode: LaunchMode.externalApplication,
          );
          return;
        } catch (e) {
          // launch web app if app fails
          await launchUrl(
            Uri.parse(webUrl),
            mode: LaunchMode.externalApplication,
          );
          return;
        }
      }

      // ensure that website link is formatted and in https
      if (!formattedUrl.startsWith('http')) {
        formattedUrl = 'https://$formattedUrl';
      }

      final websiteUri = Uri.parse(formattedUrl);

      if (await canLaunchUrl(websiteUri)) {
        await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch $formattedUrl');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open website: ${e.toString()}')),
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
          final menuItems = snapshot.data!.menuItems;
          final website = snapshot.data!.website;

          final random = Random();
          menuItems.shuffle(random);
          final randomItems = menuItems.take(3).toList();

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
