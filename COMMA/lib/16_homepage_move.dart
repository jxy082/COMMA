import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'components.dart';
import 'package:provider/provider.dart';
import 'model/user_provider.dart';
import 'api/api.dart';
import '17_allFilesPage.dart';
import 'package:http/http.dart' as http;
import '62lecture_start.dart';
import '63record.dart';
import '66colon.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '12_hompage_search.dart';
import 'mypage/44_font_size_page.dart';

// import 'popscope.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, dynamic>> lectureFiles = [];
  List<Map<String, dynamic>> colonFiles = [];
  List<Map<String, dynamic>> folderList = [];
  int _selectedIndex = 0;

  final FocusNode _focusNode = FocusNode(); // Add a FocusNode

  @override
  void initState() {
    super.initState();
    fetchLectureFiles();
    fetchColonFiles();

    // Setting focus after the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> fetchLectureFiles() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final disType = userProvider.user?.dis_type; // Get dis_type value

    if (userKey != null && disType != null) {
      try {
        print(
            'Fetching lecture files for userKey: $userKey and disType: $disType');

        final response = await http.get(Uri.parse(
          '${API.baseUrl}/api/getLectureFiles/$userKey?disType=$disType', // Adding the dis_type parameter
        ));

        print('Response status code: ${response.statusCode}'); // Status code log

        if (response.statusCode == 200) {
          print('Lecture files fetched successfully'); // Success log
          final List<Map<String, dynamic>> fileData =
              List<Map<String, dynamic>>.from(
                  jsonDecode(response.body)['files']);
          setState(() {
            lectureFiles = fileData;
          });
        } else {
          print(
              'Failed to load lecture files. Status code: ${response.statusCode}');
          print('Response body: ${response.body}'); // Response body log
          throw Exception('Failed to load lecture files');
        }
      } catch (e, stacktrace) {
        print('Error occurred while fetching lecture files: $e');
        print('Stacktrace: $stacktrace'); // Stack Trace Log
        throw Exception('Failed to fetch lecture files: $e');
      }
    } else {
      print('UserKey or disType is null');
    }
  }

  Future<void> fetchColonFiles() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final disType = userProvider.user?.dis_type; // Get dis_type value

    if (userKey != null && disType != null) {
      final response = await http.get(Uri.parse(
        '${API.baseUrl}/api/getColonFiles/$userKey?disType=$disType', // Adding the dis_type parameter
      ));

      if (response.statusCode == 200) {
        setState(() {
          colonFiles = List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['files']);
        });
      } else {
        throw Exception('Failed to load colon files');
      }
    }
  }

  Future<void> fetchOtherFolders(String fileType, int currentFolderId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;

    if (userKey != null) {
      try {
        final uri = Uri.parse(
            '${API.baseUrl}/api/getOtherFolders/$fileType/$userKey=$userKey');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          List<Map<String, dynamic>> fetchedFolders =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));

          setState(() {
            folderList = fetchedFolders.map((folder) {
              return {
                ...folder,
                'selected': false,
              };
            }).toList();
            print('Fetched folders in fetchOtherFolders: $folderList');
          });
        } else {
          throw Exception(
              'Failed to load folders with status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching other folders: $e');
        rethrow;
      }
    } else {
      print('User Key is null, cannot fetch folders.');
    }
  }

  void showQuickMenu(
    BuildContext context,
    int fileId,
    String fileType,
    int currentFolderId,
    Future<void> Function(int, int, String) moveItem,
    Future<void> Function() fetchOtherFolders,
    List<Map<String, dynamic>> folders,
    Function(int) selectFolder,
  ) async {
    print('Attempting to fetch other folders.');
    try {
      await fetchOtherFolders();
      print('Fetched other folders successfully.');
    } catch (e) {
      print('Error fetching other folders: $e');
    }

    var updatedFolders = folders.map((folder) {
      bool isSelected = folder['id'] == currentFolderId;
      return {
        ...folder,
        'selected': isSelected,
      };
    }).toList();

    print('Updated folders: $updatedFolders');

    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      backgroundColor: theme.colorScheme.surfaceContainer,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onTertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        'Go to Next',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final selectedFolder = updatedFolders.firstWhere(
                            (folder) => folder['selected'] == true,
                            orElse: () => {'id': null},
                          );
                          final selectedFolderId = selectedFolder['id'];
                          await moveItem(fileId, selectedFolderId, fileType);
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Move',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'Move to another folder.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontFamily: 'Raleway',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: updatedFolders.map((folder) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: CustomRadioButton3(
                            label: folder['folder_name'],
                            isSelected: folder['selected'],
                            onChanged: (bool value) {
                              setState(() {
                                for (var f in updatedFolders) {
                                  f['selected'] = false;
                                }
                                folder['selected'] = value;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      DateTime UKTime = dateTime.add(const Duration(hours: 1)); // Convert to UTC+1
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(UKTime);
    } catch (e) {
      print('Error parsing date: $e');
      return dateString; // Return original string on error
    }
  }

  Future<void> renameItem(int fileId, String newName, String fileType) async {
    try {
      final response = await http.put(
        Uri.parse('${API.baseUrl}/api/$fileType-files/$fileId'),
        body: jsonEncode({'file_name': newName}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          if (fileType == 'lecture') {
            lectureFiles = lectureFiles.map((file) {
              if (file['id'] == fileId) {
                return {...file, 'file_name': newName};
              }
              return file;
            }).toList();
          } else {
            colonFiles = colonFiles.map((file) {
              if (file['id'] == fileId) {
                return {...file, 'file_name': newName};
              }
              return file;
            }).toList();
          }
        });
      } else {
        throw Exception('Failed to rename file');
      }
    } catch (error) {
      print('Error renaming file: $error');
      rethrow;
    }
  }

  Future<void> deleteItem(int fileId, String fileType) async {
    try {
      final response = await http.delete(
        Uri.parse('${API.baseUrl}/api/$fileType-files/$fileId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          if (fileType == 'lecture') {
            lectureFiles.removeWhere((file) => file['id'] == fileId);
          } else {
            colonFiles.removeWhere((file) => file['id'] == fileId);
          }
        });
      } else {
        throw Exception('Failed to delete file');
      }
    } catch (error) {
      print('Error deleting file: $error');
      rethrow;
    }
  }

  Future<void> moveItem(int fileId, int newFolderId, String fileType) async {
    try {
      final response = await http.put(
        Uri.parse('${API.baseUrl}/api/$fileType-files/move/$fileId'),
        body: jsonEncode({'folder_id': newFolderId}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          if (fileType == 'lecture') {
            lectureFiles = lectureFiles.map((file) {
              if (file['id'] == fileId) {
                return {...file, 'folder_id': newFolderId};
              }
              return file;
            }).toList();
          } else {
            colonFiles = colonFiles.map((file) {
              if (file['id'] == fileId) {
                return {...file, 'folder_id': newFolderId};
              }
              return file;
            }).toList();
          }
        });
      } else {
        throw Exception('Failed to move file');
      }
    } catch (error) {
      print('Error moving file: $error');
      rethrow;
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

  // Look up folder name and check existLecture in lecture file click event
void fetchFolderAndNavigate(BuildContext context, int folderId,
    String fileType, Map<String, dynamic> file) async {
  try {
    final lectureFileId = file['id']; // Get lectureFileId
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userDisType = userProvider.user?.dis_type; // Get a user's dis_type

    // When fileType is ‘lecture’
    if (fileType == "lecture") {
      // 1. First, make an API request to check the value of existLecture with lecturefileId
      final existLectureResponse = await http.get(
          Uri.parse('${API.baseUrl}/api/checkExistLecture/$lectureFileId'));

      if (existLectureResponse.statusCode == 200) {
        var existLectureData = jsonDecode(existLectureResponse.body);

        // 2. If existLecture is 0, go to LectureStartPage
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
            lecturefileId: file['id'] ?? 'Unknown id',
            lectureFolderId: file['folder_id'],
            noteName: file['file_name'] ?? 'Unknown Note',
            fileUrl:
                file['file_url'] ?? 'https://defaulturl.com/defaultfile.txt',
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
            lecturefileId: file['id'] ?? 'Unknown id',
            lectureFolderId: file['folder_id'],
            noteName: file['file_name'] ?? 'Unknown Note',
            fileUrl:
                file['file_url'] ?? 'https://defaulturl.com/defaultfile.txt',
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
          folderId: file['folder_id'] ?? 'Unknown folderId',
        );
      }

      Navigator.push(context, MaterialPageRoute(builder: (context) => page));
    } catch (e) {
      print('Error in navigateToPage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final size = MediaQuery.sizeOf(context);
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: theme.scaffoldBackgroundColor,
          iconTheme: IconThemeData(
            color: theme.colorScheme.primary,
          ),
          leading: null,
          actions: [
            Semantics(
              label: 'Search icon',
              child: IconButton(
                icon: const Icon(
                  Icons.search_rounded,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainToSearchPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Focus(
                  // Using FocusNode to receive focus
                  focusNode: _focusNode,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Hello, ',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            TextSpan(
                              text: userProvider.user?.user_nickname ?? 'Guest',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: ' 님',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.onTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'A file of a recently studied lesson.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllFilesPage(
                              userKey: userProvider.user!.userKey,
                              fileType: 'lecture',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'View all',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Color(0xFF36AE92),
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Color(0xFF36AE92),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(lectureFiles.isEmpty
                    ? [
                        Text(
                          'There is a no recently studied lecture material.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiary,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      ]
                    : lectureFiles.take(3).map((file) {
                        return Semantics(
                          sortKey: OrdinalSortKey(2),
                          child: GestureDetector(
                            onTap: () {
                              print(colonFiles.indexOf(file));
                              print(
                                  'Lecture ${file['file_name'] ?? "N/A"} is clicked');
                              print('File details: $file');
                              fetchFolderAndNavigate(
                                  context, file['folder_id'], 'lecture', file);
                            },
                            child: LectureExample(
                              lectureName: file['file_name'] ?? 'Unknown',
                              date: formatDate(file['created_at'] ?? 'Unknown'),
                              onRename: () => showRenameDialog(
                                context,
                                lectureFiles.indexOf(file),
                                lectureFiles,
                                (id, name) => renameItem(id, name, 'lecture'),
                                setState,
                                'Rename',
                                'file_name',
                              ),
                              onDelete: () async {
                                await deleteItem(file['id'], 'lecture');
                                setState(() {
                                  lectureFiles.remove(file);
                                });
                              },
                              onMove: () async {
                                await fetchOtherFolders(
                                    'lecture', file['folder_id']);
                                showQuickMenu(
                                  context,
                                  file['id'],
                                  'lecture',
                                  file['folder_id'],
                                  moveItem,
                                  () => fetchOtherFolders(
                                      'lecture', file['folder_id']),
                                  folderList,
                                  (selectedFolder) {
                                    setState(() {
                                      file['folder_id'] = selectedFolder;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      }).toList()),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This is the colon file we recently learned about.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AllFilesPage(
                              userKey: userProvider.user!.userKey,
                              fileType: 'colon',
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Text(
                            'View all',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Color(0xFF36AE92),
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Mulish',
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: Color(0xFF36AE92),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...(colonFiles.isEmpty
                    ? [
                        Text(
                          'There is a no recently studied colon material.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiary,
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      ]
                    : colonFiles.take(3).map((file) {
                        return Semantics(
                          sortKey: OrdinalSortKey(3),
                          child: GestureDetector(
                            onTap: () {
                             //print(colonFiles.indexOf(file));
                              print(
                                  'Colon ${file['file_name'] ?? "N/A"} is clicked');
                              print('Colon file clicked: ${file['file_name']}');
                              print('File details: $file');
                              fetchFolderAndNavigate(
                                  context, file['folder_id'], 'colon', file);
                            },
                            child: LectureExample(
                              lectureName: file['file_name'] ?? 'Unknown',
                              date: formatDate(file['created_at'] ?? 'Unknown'),
                              onRename: () => showRenameDialog(
                                context,
                                colonFiles.indexOf(file),
                                colonFiles,
                                (id, name) => renameItem(id, name, 'colon'),
                                setState,
                                'Rename',
                                'file_name',
                              ),
                              onDelete: () async {
                                await deleteItem(file['id'], 'colon');
                                setState(() {
                                  colonFiles.remove(file);
                                });
                              },
                              onMove: () async {
                                await fetchOtherFolders(
                                    'colon', file['folder_id']);
                                showQuickMenu(
                                  context,
                                  file['id'],
                                  'colon',
                                  file['folder_id'],
                                  moveItem,
                                  () => fetchOtherFolders(
                                      'colon', file['folder_id']),
                                  folderList,
                                  (selectedFolder) {
                                    setState(() {
                                      file['folder_id'] = selectedFolder;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      }).toList()),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
        bottomNavigationBar:
            buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
      ),
    );
  }
}