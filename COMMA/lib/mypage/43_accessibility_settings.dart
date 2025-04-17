import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/45_theme.dart';
import '../mypage/44_font_size_page.dart';

class AccessibilitySettings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Screen mode',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onSecondary,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onTertiary),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Light Mode',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
            leading: Radio(
              value: ThemeMode.light,
              groupValue: themeNotifier.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeNotifier.toggleTheme(value);
                }
              },
              activeColor: theme.colorScheme.primary,
              fillColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary;
                  }
                  return theme.colorScheme.onSecondary;
                },
              ),
            ),
          ),
          ResponsiveSizedBox(height: 16), // Add appropriate spacing
          ListTile(
            title: Text(
              'Dark Mode',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
            leading: Radio(
              value: ThemeMode.dark,
              groupValue: themeNotifier.themeMode,
              onChanged: (ThemeMode? value) {
                if (value != null) {
                  themeNotifier.toggleTheme(value);
                }
              },
              activeColor: theme.colorScheme.primary,
              fillColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary;
                  }
                  return theme.colorScheme.onSecondary;
                },
              ),
            ),
          ),
          ResponsiveSizedBox(height: 16), // Add appropriate spacing
          // Applies when the code below is enabled
          // ListTile(
          //   title: Text(
          //     'System mode',
          //     style: theme.textTheme.bodyLarge?.copyWith(
          //       color: theme.colorScheme.onSecondary,
          //     ),
          //   ),
          //   leading: Radio(
          //     value: ThemeMode.system,
          //     groupValue: themeNotifier.themeMode,
          //     onChanged: (ThemeMode? value) {
          //       if (value != null) {
          //         themeNotifier.toggleTheme(value);
          //       }
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}
