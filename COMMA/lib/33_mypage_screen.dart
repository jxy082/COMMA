import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components.dart';
import 'mypage/42_help_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'model/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'api/api.dart';
import '1_Splash_green.dart';
import 'mypage/44_font_size_page.dart';
import 'mypage/43_accessibility_settings.dart';
import 'mypage/43_accessibility_settings.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  _MyPageScreenState createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  int _selectedIndex = 3;
  final FocusNode _appBarFocusNode = FocusNode();

  String nickname = "-";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    nickname = userProvider.user?.user_nickname ?? "-";
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appBarFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _appBarFocusNode.dispose();
    super.dispose();
  }

  Widget _buildCard(BuildContext context, String title, VoidCallback onTap) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainer,
          // border: Border.all(color: Colors.grey[600]!, width: 2),
          borderRadius: BorderRadius.circular(10),
          boxShadow: theme.brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.4), // Shadow color
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // Shadow position
                  ),
                ]
              : [], // No shadow in dark mode
        ),
        child: ListTile(
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onTertiary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            color: theme.colorScheme.onSecondary,
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> deleteUser(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;

    final response = await http.post(
      Uri.parse('${API.baseUrl}/api/delete_user'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userKey': userKey}),
    );

    print(response.statusCode);
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['success']) {
        Fluttertoast.showToast(msg: 'Unsubscribing is complete.');

        //userProvider에서 userKey 기록 삭제 (user 기록 전체 비우기)
        Provider.of<UserProvider>(context, listen: false).logOut();

        // SharedPreferences에서 userKey 삭제
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.remove('userKey');

        // SplashGreenScreen 화면으로 이동
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const SplashScreen()),
            (Route<dynamic> route) => false);
      } else {
        Fluttertoast.showToast(msg: 'An error occurred while unsubscribing.');
      }
    } else {
      Fluttertoast.showToast(msg: 'Server error: Unsubscribing failed');
    }
  }

  //스위치 당겨서 학습 모드 (dis_type) 변경하기
  Future<void> _updateDisType(int updatedDisType) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey ?? 0;

    final response = await http.put(
      Uri.parse('${API.baseUrl}/api/update_dis_type'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userKey': userKey,
        'dis_type': updatedDisType,
      }),
    );

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      if (responseBody['success']) {
        userProvider.updateDisType(updatedDisType); // Update in the provider
        Fluttertoast.showToast(msg: 'Learning mode has been successfully updated.');
      } else {
        Fluttertoast.showToast(msg: 'Error updating learning mode.');
      }
    } else {
      Fluttertoast.showToast(msg: 'Server Error: Learning Mode Update Failed');
    }
  }

  //닉네임 업데이트 함수
  Future<void> _updateNickname(String newNickname) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey ?? 0;

    final response = await http.put(
      Uri.parse('${API.baseUrl}/api/update_nickname'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userKey': userKey,
        'user_nickname': newNickname,
      }),
    );

    print('Request body: ${jsonEncode({
          'userKey': userKey,
          'user_nickname': newNickname,
        })}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      if (responseBody['success']) {
        userProvider.updateUserNickname(newNickname);
        Fluttertoast.showToast(msg: 'Your nickname has been successfully updated.');
      } else {
        Fluttertoast.showToast(msg: 'There was an error updating your nickname.');
      }
    } else {
      Fluttertoast.showToast(msg: 'Server error: Failed to update nickname');
    }
  }

void _showEditNameDialog() {
    final TextEditingController nicknameController =
        TextEditingController(text: nickname);

    final FocusNode titleFocusNode = FocusNode();
    final FocusNode contentFocusNode = FocusNode();
    final FocusNode cancelFocusNode = FocusNode();
    final FocusNode saveFocusNode = FocusNode();

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Semantics(
            sortKey: const OrdinalSortKey(1.0),
            child: Text(
              'Change nickname',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onTertiary,
              ),
            ),
          ),
          content: Semantics(
            sortKey: const OrdinalSortKey(2.0),
            child: TextField(
              focusNode: contentFocusNode,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
              controller: nicknameController,
              decoration: InputDecoration(
                hintText: 'Enter a new nickname',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSecondary,
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
              ),
            ),
          ),
          actions: <Widget>[
            Semantics(
              sortKey: const OrdinalSortKey(3.0),
              child: TextButton(
                focusNode: cancelFocusNode,
                child: Text(
                  'Cancel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
            Semantics(
              sortKey: const OrdinalSortKey(4.0),
              child: TextButton(
                focusNode: saveFocusNode,
                child: Text(
                  'Save',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                onPressed: () async {
                  String newNickname = nicknameController.text;
                  await _updateNickname(newNickname);
                  setState(() {
                    nickname = newNickname;
                  });
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(titleFocusNode);
    });
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int disType = userProvider.user?.dis_type ?? 0;

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        title: Focus(
          focusNode: _appBarFocusNode,
          child: Text(
            'My Page',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSecondary),
      ),
      body: ListView(
        children: <Widget>[
          ResponsiveSizedBox(height: 15),
          _buildCard(context, 'Change nickname', () {
            _showEditNameDialog();
          }),
          _buildCard(context, 'Screen mode', () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AccessibilitySettings()));
          }),
          _buildCard(context, 'Adjusting the font size', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => FontSizePage()));
          }),
          _buildCard(context, 'Help', () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const HelpPage()));
          }),
          _buildCard(context, 'Unsubscribing', () {
            showConfirmationDialog(
              context,
              'Unsubscribing',
              'Are you sure you want to unsubscribe? \nAll deleted data will not be recovered.',
              () async {
                await deleteUser(context);
              },
            );
          }),
          ResponsiveSizedBox(height: 50),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Text(
                'To change learning modes, pull the switch to reboot',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: MediaQuery.sizeOf(context).width * 0.075),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(
                    'Visually impaired mode',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
              ),
              SizedBox(width: MediaQuery.sizeOf(context).width * 0.0375),
              Transform.scale(
                scale: 1.5,
                child: Switch(
                  value: disType == 1,
                  onChanged: (bool newValue) async {
                    int updatedDisType = newValue ? 1 : 0;
                    await _updateDisType(updatedDisType);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => SplashScreen()),
                    );
                  },
                  activeTrackColor: Colors.teal,
                  activeColor: Colors.white,
                  inactiveTrackColor: Colors.teal,
                  inactiveThumbColor: Colors.white,
                ),
              ),
              SizedBox(width: MediaQuery.sizeOf(context).width * 0.0375),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    'Hearing impaired mode',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onTertiary,
                    ),
                  ),
                ),
              )
            ],
          ),
        ],
      ),
      bottomNavigationBar:
          buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
    );
  }
}
