import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_plugin/16_homepage_move.dart';
import 'package:flutter_plugin/api/api.dart';
import 'package:flutter_plugin/model/user.dart';
import 'package:flutter_plugin/model/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '3_onboarding-2.dart';
import '4_onboarding-3.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Importing libraries to use jsonEncode
import '10_typeselect.dart';

// void main() {
//   runApp(FigmaToCodeApp());
// }

// class FigmaToCodeApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData.dark().copyWith(
//         scaffoldBackgroundColor: const Color.fromRGBO(54, 174, 146, 1.0),
//       ),
//       home: OnboardingScreen(),
//     );
//   }
// }

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _setFocusToTop() {
    _focusNode.requestFocus();
  }

// Save new user information to DB and return userKey
  Future<int> createUserInDB(String userId, String userNickname) async {
    final response = await http.post(
      Uri.parse('${API.baseUrl}/api/signup_info'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': userId,
        'user_nickname': userNickname,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['userKey']; // The userKey returned from the server
    } else {
      throw Exception('Failed to create user in DB');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        return false; // Don't respond when the back button is pressed
      },
      child: Scaffold(
        body: Stack(
          children: [
            PageView(
              controller: _pageController,
              physics: NeverScrollableScrollPhysics(), // Disabling page slides
              onPageChanged: (int page) {
                setState(() {
                  _currentPage = page;
                  _setFocusToTop();
                });
              },
              children: [
                Onboarding1(),
                Onboarding2(focusNode: _focusNode),
                Onboarding3(focusNode: _focusNode),
              ],
            ),
            Positioned(
              bottom: 50.0,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 3; i++) // Modify by page count
                        Indicator(
                            active:
                                i == _currentPage), // Determine whether to enable based on the current page index
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Semantics(
                        sortKey: const OrdinalSortKey(1),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPage > 0
                                ? theme.primaryColor
                                : Colors.grey, // Disabled button background colour
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            fixedSize: Size(size.width * 0.44,
                                size.height * 0.065), // Setting the size
                          ),
                          onPressed: _currentPage > 0
                              ? () {
                                  _pageController.previousPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                }
                              : null, // Disable by assigning null to onPressed when on page 0
                          child: Text(
                            'Previous',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _currentPage > 0
                                  ? theme.colorScheme.surface
                                  : Colors.grey, // Adjust text colour too
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Semantics(
                        sortKey: const OrdinalSortKey(2),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentPage < 2
                                ? theme.primaryColor
                                : Colors.grey, // Disabled button background colour
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            fixedSize: Size(size.width * 0.44,
                                size.height * 0.065), // Setting the size
                          ),
                          onPressed: _currentPage < 2 // On the final page, click Disable
                              ? () {
                                  _pageController.nextPage(
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.ease,
                                  );
                                }
                              : null,
                          child: Text(
                            'Next',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _currentPage < 2
                                  ? theme.colorScheme.surface
                                  : Colors.grey, // Adjust text colour too
                              fontSize: 14,
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Semantics(
                    sortKey: const OrdinalSortKey(3),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor, // Background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        fixedSize: Size(size.width * 0.9,
                            size.height * 0.065), // Button size
                      ),
                      onPressed: () async {
                        print('Press the button');
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        String? userId =
                            prefs.getString('user_id'); // Use UUID as user_id

                        if (userId == null) {
                          print('No userId');

                          // Create new if no userId

                          userId = Uuid().v4(); // Generate a UUID
                          print('Generated userId : $userId');

                          String userNickname = 'New User';
                          await prefs.setString('user_id', userId);
                          await prefs.setString('user_nickname', userNickname);

                          print('Generated user_id : $userId');
                          print('Generated user_nickname : $userNickname');

                          // Save new user information to DB and get userKey
                          int userKey =
                              await createUserInDB(userId, userNickname);

                          // Save the userKey to local storage
                          await prefs.setInt('userKey', userKey);
                        } else {
                          //If userId exists but userKey has not been created
                          String userNickname = 'New User';
                          await prefs.setString('user_nickname', userNickname);

                          print('current user_id : $userId');
                          print('Generated user_nickname : $userNickname');

                          // Save new user information to DB and get userKey
                          int userKey =
                              await createUserInDB(userId, userNickname);

                          // Save the userKey to local storage
                          await prefs.setInt('userKey', userKey);
                        }

                        // Retrieve userKey and user_nickname from local storage
                        int? userKey = prefs.getInt('userKey');
                        String? userNickname = prefs.getString('user_nickname');

                        if (userKey != null && userNickname != null) {
                          // Setting on UserProvider
                          Provider.of<UserProvider>(context, listen: false)
                              .setUser(
                                  User(userKey, userId!, userNickname, null));
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DisabilitySelectionPage()),
                        );
                      },
                      child: Text(
                        'Get started now',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.surface,
                          fontSize: 14,
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Onboarding1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);

    return Container(
      width: size.width,
      height: size.height,
      color: theme.scaffoldBackgroundColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: size.height * 0.20), // Add a top margin
          Text(
            'Provide more accurate subtitles in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onTertiary,
              fontSize: 20,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: size.height * 0.02),
          Text(
            'COMMA learns the course material\nto create more accurate subtitles during live classes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.surfaceBright,
              fontSize: 14,
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: size.height * 0.08),
          Semantics(
            label: 'Learning posture',
            child: SizedBox(
              width: size.width,
              height: size.height * 0.3,
              child: Image.asset('assets/onboarding_1.png'),
            ),
          ),
        ],
      ),
    );
  }
}

class Indicator extends StatelessWidget {
  final bool active;

  Indicator({this.active = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? theme.primaryColor : Colors.grey,
      ),
    );
  }
}
