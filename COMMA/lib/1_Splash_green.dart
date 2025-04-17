// splash_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import '2_onboarding-1.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '16_homepage_move.dart';
import 'model/user_provider.dart';
import 'model/user.dart';
import 'package:http/http.dart' as http;
import 'api/api.dart';

Future<Map<String, dynamic>?> _fetchUserDetails(int userKey) async {
  try {
    final response =
        await http.get(Uri.parse('${API.baseUrl}/api/user-details/$userKey'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'user_nickname': data['user_nickname'],
        'dis_type': data['dis_type']
      };
    } else {
      print('Failed to load user details: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error fetching user details: $e');
    return null;
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserKey(); // 앱 실행 시 userKey 확인
  }

  Future<void> _checkUserKey() async {
    print('Verify user_id');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    print('UserID : $userId');

    if (userId != null) {
      print('UserID exists (device number has been created)');

      // Loading only userKey from local storage
      int? userKey = prefs.getInt('userKey');

      if (userKey != null) {
        print('A username key also exists : $userKey');

        // Get nickname and type with the User Info API call
        final userDetails = await _fetchUserDetails(userKey);

        if (userDetails != null) {
          String userNickname = userDetails['user_nickname'];
          int disType = userDetails['dis_type'];
          print('${disType}');

          // Setting a nickname for a UserProvider
          Provider.of<UserProvider>(context, listen: false)
              .setUser(User(userKey, userId!, userNickname, null));
          print('Here22');

          // Update the type in UserProvider
          Provider.of<UserProvider>(context, listen: false)
              .updateDisType(disType);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        }
      } else {
        print('No userKey (userId was created but userKey generation failed)');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()),
        );
      }
    } else {
      print('No username (device number never created) --> Go to Onboarding');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the size of the screen
    // Get the size of the screen
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Color(0xFF36AE92),
      body: Center(
        child: Semantics(
          label: 'App logo COMMA',
          child: Container(
            width: size.width * 0.3, // Adjust this value to change logo size
            height: size.width * 0.3, // Maintain aspect ratio
            decoration: const BoxDecoration(
              color: Color(0xFF36AE92),
              image: DecorationImage(
                image: AssetImage('assets/logo_white.png'),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
