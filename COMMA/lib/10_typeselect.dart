import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '16_homepage_move.dart';
import 'model/user_provider.dart';
import 'package:http/http.dart' as http;
import 'api/api.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'mypage/44_font_size_page.dart';

class DisabilitySelectionPage extends StatelessWidget {
  const DisabilitySelectionPage({Key? key}) : super(key: key);

  // Function to store disability type (0: blind, 1: deaf)
  Future<void> _setDisabilityType(int type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dis_type', type);
  }

  // Storing learning types in the DB
  Future<void> _saveDisabilityTypeToDB(
      int userKey, int type, UserProvider userProvider) async {
    try {
      final response = await http.post(
        Uri.parse('${API.baseUrl}/api/user/$userKey/update-type'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, int?>{
          'type': type,
        }),
      );
      // Log status codes and responses
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Process only if response is 200
      if (response.statusCode == 200) {
        print('The learning type has been saved to the DB.');
        // Update learning types stored in UserProvider
        userProvider.updateDisType(type);
      } else {
        throw Exception('Failed to store learning type in DB.');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to store learning type in DB.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 150),
            Text(
              'Please select a user learning type',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Keep learning with\nCOMMA!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.colorScheme.surfaceBright,
                fontSize: 14,
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 100),
            GestureDetector(
              onTap: () async {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);

                print('User key: ${userProvider.user!.userKey}');

                // Select Visually Impaired Mode and save
                await _setDisabilityType(0); // Visually impaired mode

                // Storing learning types in the DB
                await _saveDisabilityTypeToDB(
                    userProvider.user!.userKey, 0, userProvider);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainPage(),
                  ),
                );
              },
              child: Container(
                width: size.width * 0.9,
                height: size.height * 0.065,
                decoration: ShapeDecoration(
                  color: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Visually impaired mode (alt text)',
                    style: TextStyle(
                      color: theme.colorScheme.surface,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final userProvider =
                    Provider.of<UserProvider>(context, listen: false);

                print('User key: ${userProvider.user!.userKey}');

                // Select and save hearing-impaired mode
                await _setDisabilityType(1); // Hearing impaired mode

                // Storing learning types in the DB
                await _saveDisabilityTypeToDB(
                    userProvider.user!.userKey, 1, userProvider);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainPage(),
                  ),
                );
              },
              child: Container(
                width: size.width * 0.9,
                height: size.height * 0.065,
                decoration: ShapeDecoration(
                  color: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Hearing impaired mode (real-time captions)',
                    style: TextStyle(
                      color: theme.colorScheme.surface,
                      fontSize: 14,
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                    ),
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
