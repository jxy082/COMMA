import 'package:flutter/material.dart';
import 'package:flutter_plugin/components.dart';
import '../model/44_font_size_provider.dart';
import 'package:provider/provider.dart';
import '44_font_size_page.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  int _selectedIndex = 3;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onTertiary),
        title: Text(
          'Help',
          style: theme.textTheme.titleLarge?.copyWith(
            // One size down
            color: theme.colorScheme.onTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'How to use the app',
            style: theme.textTheme.headlineSmall?.copyWith(
              // One size down
              color: theme.colorScheme.onTertiary,
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSizedBox(height: 16.0), // Slightly smaller spacing
          _buildHelpSection(
            title: 'What is COMMA??',
            content:
                'COMMA is learning aid for people with visual or hearing impairments. You may find it useful in a live, face-to-face lecture setting when you are given lecture aids that relate to lecture content. ',
          ),
          _buildHelpSection(
            title: 'Basic controls (for the visually impaired)',
            content:
                '1. before joining an in-person class, upload lecture materials to the app that will be used in the class.\n2. Before you join an in-person lecture, you can preview the course materials with generated alternate text to help you engage with them.\n3. When the class starts, tap the Record button to record the class. However, you need to ask your instructor for permission to record beforehand. \n4. After the class is over, you can click the Create Colon button to create a review material that combines the lecture material with a transcribed shorthand file. ',
          ),
          _buildHelpSection(
            title: 'Basic controls (for the hearing impaired)',
            content:
                '1. Before joining an in-person class, upload lecture materials to the app that will be used in the class.\n2. When the in-person class begins, tap the record button to record the class. However, you need to ask your instructor for permission to record beforehand. \n3. Once the class is over, you can click the Create Colon button to create a review material that links the lecture material to the recorded shorthand file. ',
          ),
          _buildHelpSection(
            title: 'Add-ons for the visually impaired',
            content:
                'All buttons and text descriptions in the app are highly compatible with screen readers. You can also adjust the font size, brightness, and high contrast mode in the settings. ',
          ),
          ResponsiveSizedBox(height: 16.0), // Slightly smaller spacing
          Text(
            'Data collection and use',
            style: theme.textTheme.titleMedium?.copyWith(
              // One size down
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSizedBox(height: 8.0), // Slightly smaller spacing
          Text(
            'Recordings created while using the app are not stored on the server and are discarded immediately after extracting text from speech.',
            style: theme.textTheme.bodyMedium?.copyWith(
              // One size down
              color: theme.colorScheme.onTertiary,
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
    );
  }

  Widget _buildHelpSection({required String title, required String content}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0), // Slightly smaller spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              // One size down
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          ResponsiveSizedBox(height: 4.0), // Slightly smaller spacing
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(
              // One size down
              color: theme.colorScheme.onTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
