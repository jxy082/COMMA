import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_plugin/16_homepage_move.dart';
import 'package:flutter_plugin/2_onboarding-1.dart';
import 'package:path_provider/path_provider.dart'; // path_provider 임포트
import 'dart:io'; // Directory 사용을 위해 추가
import 'components.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import '1_Splash_green.dart'; // SplashScreen import
import 'model/user_provider.dart'; // UserProvider import
import 'package:shared_preferences/shared_preferences.dart'; // SharedPreferences for userKey
import 'model/44_font_size_provider.dart';
import 'model/45_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FontSizeProvider()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()), // 추가
      ],
      child: const MyApp(),
    ),
  );
}

// ThemeData for Light Theme
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Color(0xFF36AE92),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    surface: Colors.white,
    surfaceBright: Color(0xFF0D5836),
    surfaceContainer: Colors.white,
    primaryContainer: Colors.white,
    primary: Color(0xFF36AE92),
    primaryFixed: Color(0x9CE4F0E7),
    secondary: Color(0xFF005A38),
    tertiary: Color(0xFFFFA17A),
    tertiaryContainer: Color(0xFFE0F2F1),
    onTertiary: Color(0xFF303030),
    tertiaryFixed: const Color(0xFF4CAF50).withOpacity(0.05),
    brightness: Brightness.light,
    onSecondary: Color(0xFF4C4C4C),
  ),
  scaffoldBackgroundColor: Colors.white, // Use scaffoldBackgroundColor
  visualDensity: VisualDensity.adaptivePlatformDensity,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white, // Background color for BottomNavigationBar
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.black),

  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 57.0), // headline1
    displayMedium: TextStyle(fontSize: 45.0), // headline2
    displaySmall: TextStyle(fontSize: 36.0), // headline3
    headlineLarge: TextStyle(fontSize: 32.0), // headline4
    headlineMedium: TextStyle(fontSize: 28.0), // headline5
    headlineSmall: TextStyle(fontSize: 24.0), // headline6
    titleLarge: TextStyle(fontSize: 22.0), // subtitle1
    titleMedium: TextStyle(fontSize: 16.0), // subtitle2
    titleSmall: TextStyle(fontSize: 14.0),
    bodyLarge: TextStyle(fontSize: 16.0), // bodyText1
    bodyMedium: TextStyle(fontSize: 14.0), // bodyText2
    bodySmall: TextStyle(fontSize: 12.0),
    labelLarge: TextStyle(fontSize: 14.0), // button
    labelMedium: TextStyle(fontSize: 12.0), // caption
    labelSmall: TextStyle(fontSize: 11.0), // overline
  ),
);

// ThemeData for Dark Theme
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF3BBFA0),
  colorScheme: ColorScheme.fromSwatch().copyWith(
    surface: Color(0xFF2B2B2B),
    surfaceBright: Color(0xFF15B06A),
    surfaceContainer: Color(0xFF383838),
    primaryContainer: Color(0xFF1E1E1E),
    primary: Color(0xFF36AE92),
    primaryFixed: Color.fromARGB(189, 228, 240, 231),
    secondary: Color.fromARGB(255, 3, 159, 99),
    tertiary: Color(0xFFFFA17A),
    tertiaryFixed: Color.fromARGB(255, 61, 61, 61),
    tertiaryContainer: Color(0xFF626968),
    onTertiary: Color(0xD2FFFFFF),
    brightness: Brightness.dark,
    onSecondary: Color(0xD2FFFFFF),
  ),
  scaffoldBackgroundColor: Color(0xFF121212), // Use scaffoldBackgroundColor
  visualDensity: VisualDensity.adaptivePlatformDensity,
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:
          Color(0xFF121212), // Background color for BottomNavigationBar
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey),
  textTheme: TextTheme(
    displayLarge: TextStyle(fontSize: 57.0), // headline1
    displayMedium: TextStyle(fontSize: 45.0), // headline2
    displaySmall: TextStyle(fontSize: 36.0), // headline3
    headlineLarge: TextStyle(fontSize: 32.0), // headline4
    headlineMedium: TextStyle(fontSize: 28.0), // headline5
    headlineSmall: TextStyle(fontSize: 24.0), // headline6
    titleLarge: TextStyle(fontSize: 22.0), // subtitle1
    titleMedium: TextStyle(fontSize: 16.0), // subtitle2
    titleSmall: TextStyle(fontSize: 14.0),
    bodyLarge: TextStyle(fontSize: 16.0), // bodyText1
    bodyMedium: TextStyle(fontSize: 14.0), // bodyText2
    bodySmall: TextStyle(fontSize: 12.0),
    labelLarge: TextStyle(fontSize: 14.0), // button
    labelMedium: TextStyle(fontSize: 12.0), // caption
    labelSmall: TextStyle(fontSize: 11.0), // overline
  ),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    final screenWidth = MediaQuery.sizeOf(context).width;

    return MaterialApp(
      navigatorObservers: [MyNavigatorObserver()],
      debugShowCheckedModeBanner: false,
      // 라이트 및 다크 테마 적용
      theme: lightTheme.copyWith(
        // 라이트 테마에 사용자 지정 폰트 크기 비율 적용
        textTheme: lightTheme.textTheme.apply(
          fontSizeFactor: fontSizeProvider.scaleFactor *
              (screenWidth / 400), // 화면 크기에 따른 조정
          fontSizeDelta: 0.0,
        ),
      ),
      darkTheme: darkTheme.copyWith(
        // 다크 테마에 사용자 지정 폰트 크기 비율 적용
        textTheme: darkTheme.textTheme.apply(
          fontSizeFactor: fontSizeProvider.scaleFactor *
              (screenWidth / 400), // 화면 크기에 따른 조정
          fontSizeDelta: 0.0,
        ),
      ),

      themeMode: themeNotifier.themeMode, // 선택된 테마 모드 적용

      home: const SplashScreen(), // 앱 시작 시 SplashScreen으로 이동
    );
  }
}

class MyNavigatorObserver extends NavigatorObserver {
  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute == null) {
      // 뒤로 가기로 앱 종료 또는 초기화 시 로그아웃 로직 추가
      print('Exit or reset the app with the back button');
    }
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String? _tempDirPath;

  @override
  void initState() {
    super.initState();
    _initTempDir();
  }

  Future<void> _initTempDir() async {
    try {
      Directory tempDir = await getTemporaryDirectory();
      setState(() {
        _tempDirPath = tempDir.path;
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Navigator.of(context).canPop()) {
          return true;
        } else {
          // 앱을 종료하지 않고 로그인 상태를 유지합니다.
          return false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Path Provider Example'),
        ),
        body: Center(
          child: Text('Temporary Directory: $_tempDirPath'),
        ),
        bottomNavigationBar:
            buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
      ),
    );
  }
}
