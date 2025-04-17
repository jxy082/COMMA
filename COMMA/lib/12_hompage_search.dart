import 'package:flutter/material.dart';
import 'components.dart';
import 'api/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Add for date formatting
import '63record.dart';
import '66colon.dart';
import 'package:provider/provider.dart';
import 'mypage/44_font_size_page.dart';
import 'model/user_provider.dart';
import '62lecture_start.dart';

class MainToSearchPage extends StatefulWidget {
  const MainToSearchPage({super.key});

  @override
  _MainToSearchPageState createState() => _MainToSearchPageState();
}

class _MainToSearchPageState extends State<MainToSearchPage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> searchResults = [];
  final TextEditingController _searchController = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> searchFiles(String query) async {
    final response = await http
        .get(Uri.parse('${API.baseUrl}/api/searchFiles?query=$query'));

    if (response.statusCode == 200) {
      setState(() {
        searchResults =
            List<Map<String, dynamic>>.from(jsonDecode(response.body)['files']);
      });
    } else {
      print('Failed to search files: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to search files');
    }
  }

  String formatDateTimeToUK(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'Unknown';
    final DateTime utcDateTime = DateTime.parse(dateTime);
    final DateTime UKDateTime = utcDateTime.add(const Duration(hours: 1));
    return DateFormat('yyyy/MM/dd HH:mm').format(UKDateTime);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Look up folder name and check existLecture in lecture file click event
void fetchFolderAndNavigate(BuildContext context, int folderId,
    String fileType, Map<String, dynamic> file) async {
  try {
    final lectureFileId = file['id']; // Get lectureFileId
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userDisType = userProvider.user?.dis_type; // Get a user's dis_type

    // When fileType is ‘lecture’
    if (fileType == "lecture") {
      // 1. make an API request to check the existLecture value with lecturefileId first
      final existLectureResponse = await http.get(
          Uri.parse('${API.baseUrl}/api/checkExistLecture/$lectureFileId'));

      if (existLectureResponse.statusCode == 200) {
        var existLectureData = jsonDecode(existLectureResponse.body);

        // 2. if existLecture is 0, go to LectureStartPage
        if (existLectureData['existLecture'] == 0) {
          // Keyword fetch and navigate to LectureStartPage
          List<String> keywords = await fetchKeywords(lectureFileId);

          // Get folder names
          final response = await http.get(Uri.parse(
              '${API.baseUrl}/api/getFolderName/$fileType/$folderId'));
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LectureStartPage(
                  lectureFolderId: file['folder_id'],
                  lecturefileId: file['id'],
                  lectureName: file['lecture_name'] ?? 'Unknown Lecture',
                  fileURL: file['file_url'] ??
                      'https://defaulturl.com/defaultfile.txt',
                  type: userDisType!, // Modify
                  selectedFolder: data['folder_name'], // Folder name
                  noteName: file['file_name'] ?? 'Unknown Note',
                  responseUrl: file['alternative_text_url'] ??
                      'https://defaulturl.com/defaultfile.txt', // null or actual value
                  keywords: keywords, // Keyword list
                ),
              ),
            );
          }
        } else if (existLectureData['existLecture'] == 1) {
          // If existLecture is 1, go to existing page
          final response = await http.get(Uri.parse(
              '${API.baseUrl}/api/getFolderName/$fileType/$folderId'));
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            navigateToPage(context, data['folder_name'] ?? 'Unknown Folder',
                file, fileType);
          } else {
            print('Failed to load folder name: ${response.statusCode}');
            navigateToPage(context, 'Unknown Folder', file, fileType);
          }
        }
      } else {
        print(
            'Failed to check existLecture: ${existLectureResponse.statusCode}');
      }
    } 
    // When fileType is ‘colon’
    else if (fileType == "colon") {
      // Get colonFileId (if needed)
      final colonFileId = file['id'];

      // Get folder names
        // Go to ColonPage
            final response = await http.get(Uri.parse(
              '${API.baseUrl}/api/getFolderName/$fileType/$folderId'));
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            navigateToPage(context, data['folder_name'] ?? 'Unknown Folder',
                file, fileType);
          } else {
            print('Failed to load folder name: ${response.statusCode}');
            navigateToPage(context, 'Unknown Folder', file, fileType);
          }
    } else {
      print('The fileType is not "lecture" or "colon". Operation skipped.');
    }
  } catch (e) {
    print('Error fetching folder name or existLecture: $e');
    navigateToPage(context, 'Unknown Folder', file, fileType);
  }
}



  // Navigate to a lecture file or colon file page
  void navigateToPage(BuildContext context, String folderName,
    Map<String, dynamic> file, String fileType) {
  try {
    Widget page;
    if (fileType == 'lecture') {
      if (file['type'] == 0) {
        // If it's a lecture file + alt text
        page = RecordPage(
          lecturefileId: file['id'],
          lectureFolderId: file['folder_id'],
          noteName: file['file_name'] ?? 'Unknown Note',
          fileUrl: file['file_url'] ?? 'https://defaulturl.com/defaultfile.txt',
          folderName: folderName,
          recordingState: RecordingState.recorded,
          lectureName: file['lecture_name'] ?? 'Unknown Lecture',
          responseUrl: file['alternative_text_url'] ??
              'https://defaulturl.com/defaultfile.txt',
          type: file['type'] ?? 'Unknown Type',
        );
      } else {
        // For lecture files + live subtitles
        page = RecordPage(
          lecturefileId: file['id'],
          lectureFolderId: file['folder_id'],
          noteName: file['file_name'] ?? 'Unknown Note',
          fileUrl: file['file_url'] ?? 'https://defaulturl.com/defaultfile.txt',
          folderName: folderName,
          recordingState: RecordingState.recorded,
          lectureName: file['lecture_name'] ?? 'Unknown Lecture',
          type: file['type'] ?? 'Unknown Type',
        );
      }
    } else {
      // For colon files
      page = ColonPage(
        folderName: folderName,
        noteName: file['file_name'] ?? 'Unknown Note',
        lectureName: file['lecture_name'] ?? 'Unknown Lecture',
        createdAt: file['created_at'] ?? 'Unknown Date',
        fileUrl: file['file_url'] ?? 'Unknown fileUrl',
        colonFileId: file['id'],
        folderId: file['folder_id'],
      );
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  } catch (e) {
    print('Error in navigateToPage: $e');
  }
}

  // Importing keywords from DB
  Future<List<String>> fetchKeywords(int lecturefileId) async {
    try {
      final response = await http
          .get(Uri.parse('${API.baseUrl}/api/getKeywords/$lecturefileId'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final String keywordsUrl = responseData['keywordsUrl'];

          // Get a list of keywords from keywords_url
          return await fetchKeywordsFromUrl(keywordsUrl);
        } else {
          print('Error fetching keywords: ${responseData['error']}');
          return [];
        }
      } else {
        print('Failed to fetch keywords with status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

// Function to get a list of keywords from keywords_url
  Future<List<String>> fetchKeywordsFromUrl(String keywordsUrl) async {
    try {
      final response = await http.get(Uri.parse(keywordsUrl));

      if (response.statusCode == 200) {
        // Decode to UTF-8
        final String content = utf8.decode(response.bodyBytes);
        return content.split(','); // Return a list of keywords separated by,
      } else {
        print('Failed to fetch keywords from URL');
        return [];
      }
    } catch (e) {
      print('Error fetching keywords from URL: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          title: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 45,
                  child: TextField(
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSecondary),
                    controller: _searchController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: theme.colorScheme.primaryFixed,
                      hintText: 'Enter the filename to search for.',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: Color(0xFF36AE92),
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF36AE92),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 75,
                height: 40,
                child: ElevatedButton(
                  onPressed: () {
                    searchFiles(_searchController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36AE92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Search',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          iconTheme: IconThemeData(color: theme.colorScheme.onSecondary)),
      body: searchResults.isEmpty
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(50.0),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        'There is no recent search history.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                final file = searchResults[index];
                // Handling null values to set default values
                final fileName = file['file_name'] ?? 'Unknown Note';
                final fileUrl = file['file_url'] ??
                    'https://defaulturl.com/defaultfile.txt';
                final lectureName = file['lecture_name'] ?? 'Unknown Lecture';
                final createdAt = file['created_at'] ?? 'Unknown Date';
                final folderId = file['folder_id'] ?? 0;
                final fileType = file['file_type'] ?? 'unknown';

                return ListTile(
                  title: Text(
                    fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                  subtitle: Text(
                    formatDateTimeToUK(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                    ),
                  ),
                  onTap: () {
                    print('File $fileName is clicked');
                    fetchFolderAndNavigate(
                        context, folderId, fileType, file); // Tap a file to open it
                  },
                );
              },
            ),
      bottomNavigationBar:
          buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
    );
  }
}
