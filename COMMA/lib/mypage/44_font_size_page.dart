import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/44_font_size_provider.dart';

class FontSizePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Adjusting the font size',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSecondary,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onTertiary),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ListTile(
            title: Text(
              'Normal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
            leading: Radio<double>(
              value: 1.0,
              groupValue: fontSizeProvider.scaleFactor,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary; // Colours in the selected state
                  }
                  return theme.colorScheme.onSecondary; // Colours in the unselected state
                },
              ),
              onChanged: (double? value) {
                if (value != null) {
                  fontSizeProvider.setScaleFactor(value);
                }
              },
            ),
          ),
          ListTile(
            title: Text(
              'Large',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
            leading: Radio<double>(
              value: 1.3,
              groupValue: fontSizeProvider.scaleFactor,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary; // Colours in the selected state
                  }
                  return theme.colorScheme.onSecondary; // Colours in the unselected state
                },
              ),
              onChanged: (double? value) {
                if (value != null) {
                  fontSizeProvider.setScaleFactor(value);
                }
              },
            ),
          ),
          ListTile(
            title: Text(
              'Very large',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSecondary,
              ),
            ),
            leading: Radio<double>(
              value: 1.5,
              groupValue: fontSizeProvider.scaleFactor,
              fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.primary; // Colours in the selected state
                  }
                  return theme.colorScheme.onSecondary; // Colours in the unselected state
                },
              ),
              onChanged: (double? value) {
                if (value != null) {
                  fontSizeProvider.setScaleFactor(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ResponsiveSizedBox extends StatelessWidget {
  final double height;
  final double? width;

  const ResponsiveSizedBox({Key? key, required this.height, this.width})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scaleFactor = MediaQuery.textScaleFactorOf(context);
    return SizedBox(
      height: height * scaleFactor,
      width: width,
    );
  }
}
