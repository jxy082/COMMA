import 'package:flutter/material.dart';
import 'package:flutter_plugin/model/user_provider.dart';
import 'package:provider/provider.dart';
import 'api/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '62lecture_start.dart';
import '63record.dart';
import '66colon.dart';
import 'components.dart'; // Import a file with the showCustomMenu function
import 'mypage/44_font_size_page.dart';

class AllFilesPage extends StatefulWidget {
  final int userKey;
  final String fileType;

  const AllFilesPage({
    super.key,
    required this.userKey,
    required this.fileType,
  });

  @override
  _AllFilesPageState createState() => _AllFilesPageState();
}

class _AllFilesPageState extends State<AllFilesPage> {
  List<Map<String, dynamic>> files = [];
  List<Map<String, dynamic>> lectureFiles = [];
  List<Map<String, dynamic>> colonFiles = [];
  List<Map<String, dynamic>> folderList = [];

  @override
  void initState() {
    super.initState();
    fetchFiles();
    fetchLectureFiles();
    fetchColonFiles();
  }

  Future<void> fetchFiles() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final disType = userProvider.user?.dis_type;

    if (userKey != null && disType != null) {
      final fileType = widget.fileType == 'lecture' ? 'Lecture' : 'Colon';
      final response = await http.get(Uri.parse(
          '${API.baseUrl}/api/get${fileType}Files/$userKey?disType=$disType'));

      if (response.statusCode == 200) {
        setState(() {
          files = List<Map<String, dynamic>>.from(
              jsonDecode(response.body)['files']);
        });
      } else {
        throw Exception('Failed to load $fileType files');
      }
    }
  }

  // String formatDateTimeToKorean(String? dateTime) {
  //   if (dateTime == null || dateTime.isEmpty) return 'Unknown';
  //   final DateTime utcDateTime = DateTime.parse(dateTime);
  //   final DateTime koreanDateTime = utcDateTime.add(const Duration(hours: 1));
  //   return DateFormat('yyyy/MM/dd HH:mm').format(UKDateTime);
  // }

  String formatDate(String dateString) {
    try {
      DateTime dateTime = DateTime.parse(dateString);
      DateTime UKTime = dateTime.add(const Duration(hours: 1)); // UTC+1로 변환
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(UKTime);
    } catch (e) {
      print('Error parsing date: $e');
      return dateString; // Return original string on error
    }
  }

  Future<List<String>> fetchKeywords(int lecturefileId) async {
    try {
      final response = await http
          .get(Uri.parse('${API.baseUrl}/api/getKeywords/$lecturefileId'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          final String keywordsUrl = responseData['keywordsUrl'];
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

  Future<List<String>> fetchKeywordsFromUrl(String keywordsUrl) async {
    try {
      final response = await http.get(Uri.parse(keywordsUrl));

      if (response.statusCode == 200) {
        final String content = utf8.decode(response.bodyBytes);
        return content.split(',');
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
      // 1. 먼저 lecturefileId로 existLecture 값을 확인하는 API 요청
      final existLectureResponse = await http.get(
          Uri.parse('${API.baseUrl}/api/checkExistLecture/$lectureFileId'));

      if (existLectureResponse.statusCode == 200) {
        var existLectureData = jsonDecode(existLectureResponse.body);

        // 2. existLecture가 0이면 LectureStartPage로 이동
        if (existLectureData['existLecture'] == 0) {
          // 키워드 fetch 후 LectureStartPage로 이동
          List<String> keywords = await fetchKeywords(lectureFileId);

          // 폴더 이름 가져오기
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
                  type: userDisType!, // 수정
                  selectedFolder: data['folder_name'], // 폴더 이름
                  noteName: file['file_name'] ?? 'Unknown Note',
                  responseUrl: file['alternative_text_url'] ??
                      'https://defaulturl.com/defaultfile.txt', // null 또는 실제 값
                  keywords: keywords, // 키워드 목록
                ),
              ),
            );
          }
        } else if (existLectureData['existLecture'] == 1) {
          // existLecture가 1이면 기존 페이지로 이동
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
    // fileType이 "colon"일 경우
    else if (fileType == "colon") {
      // colonFileId 가져오기 (필요한 경우)
      final colonFileId = file['id'];

      // 폴더 이름 가져오기
        // ColonPage로 이동
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



  void navigateToPage(BuildContext context, String folderName,
    Map<String, dynamic> file, String fileType) {
  try {
    Widget page;
    if (fileType == 'lecture') {
      if (file['type'] == 0) {
        // 강의 파일 + 대체텍스트인 경우
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
        // 강의 파일 + 실시간 자막인 경우
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
      // 콜론 파일인 경우
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

  Future<void> fetchLectureFiles() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final disType = userProvider.user?.dis_type; // dis_type 값 가져오기

    if (userKey != null && disType != null) {
      try {
        print(
            'Fetching lecture files for userKey: $userKey and disType: $disType');

        final response = await http.get(Uri.parse(
          '${API.baseUrl}/api/getLectureFiles/$userKey?disType=$disType', // dis_type 파라미터 추가
        ));

        print('Response status code: ${response.statusCode}'); // 상태 코드 로그

        if (response.statusCode == 200) {
          print('Lecture files fetched successfully'); // 성공 로그
          final List<Map<String, dynamic>> fileData =
              List<Map<String, dynamic>>.from(
                  jsonDecode(response.body)['files']);
          setState(() {
            lectureFiles = fileData;
          });
        } else {
          print(
              'Failed to load lecture files. Status code: ${response.statusCode}');
          print('Response body: ${response.body}'); // 응답 본문 로그
          throw Exception('Failed to load lecture files');
        }
      } catch (e, stacktrace) {
        print('Error occurred while fetching lecture files: $e');
        print('Stacktrace: $stacktrace'); // 스택 트레이스 로그
        throw Exception('Failed to fetch lecture files: $e');
      }
    } else {
      print('UserKey or disType is null');
    }
  }

  Future<void> fetchColonFiles() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final disType = userProvider.user?.dis_type; // dis_type 값 가져오기

    if (userKey != null && disType != null) {
      final response = await http.get(Uri.parse(
        '${API.baseUrl}/api/getColonFiles/$userKey?disType=$disType', // dis_type 파라미터 추가
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
      backgroundColor: theme.scaffoldBackgroundColor,
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
                            color: theme.colorScheme.onSecondary,
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
                  ResponsiveSizedBox(height: 10), // 여기에 적용
                  Center(
                    child: Text(
                      'Move to another folder.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontFamily: 'Raleway',
                      ),
                    ),
                  ),
                  ResponsiveSizedBox(height: 16), // 여기에 적용
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

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(
      iconTheme: IconThemeData(color: theme.colorScheme.onTertiary),
      title: Text(
        widget.fileType == 'lecture' ? 'All lecture files' : 'All colon files',
        style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onTertiary, fontWeight: FontWeight.w600),
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
    ),
    body: files.isEmpty
        ? Center(
            child: Text(
            'No files found.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondary,
            ),
          ))
        : ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];

              final fileName = file['file_name'] ?? 'Unknown Note';
              final fileUrl = file['file_url'] ??
                  'https://defaulturl.com/defaultfile.txt';
              final lectureName = file['lecture_name'] ?? 'Unknown Lecture';
              final createdAt = file['created_at'] ?? 'Unknown Date';
              final folderId = file['folder_id'] ?? 0;
              final fileType = widget.fileType; // fileType을 가져옴

              return GestureDetector(
                onTap: () {
                  print('${fileType.toUpperCase()} ${file['file_name'] ?? "N/A"} is clicked');
                  print('File details: $file');
                  
                  // fileType에 따라 다른 동작을 수행
                  if (fileType == 'lecture') {
                    fetchFolderAndNavigate(
                        context, folderId, 'lecture', file);
                  } else if (fileType == 'colon') {
                    fetchFolderAndNavigate(
                        context, folderId, 'colon', file);
                  }
                },
                child: LectureExample(
                  lectureName: fileName,
                  date: formatDate(file['created_at'] ?? 'Unknown'),
                  
                 onRename: () {
                  print('Rename tapped for file: ${file['file_name']}');
                  

                  showRenameDialog(
                    context,
                    index,
                    fileType == 'lecture' ? lectureFiles : colonFiles, // Lecture와 Colon 파일 리스트 구분
                    (id, newName) async {
                      print('Renaming file with id: $id to new name: $newName');
                      await renameItem(id, newName, fileType); // renameItem 호출
                    },
                    setState,
                    'Rename',
                    'file_name',
                  );
                },


                  onDelete: () async {
                    await deleteItem(file['id'], fileType);
                    setState(() {
                      if (fileType == 'lecture') {
                        lectureFiles.remove(file);
                      } else if (fileType == 'colon') {
                        colonFiles.remove(file);
                      }
                    });
                  },
                  
                  onMove: () async {
                    await fetchOtherFolders(fileType, folderId);
                    showQuickMenu(
                      context,
                      file['id'],
                      fileType,
                      folderId,
                      moveItem,
                      () => fetchOtherFolders(fileType, folderId),
                      folderList,
                      (selectedFolder) {
                        setState(() {
                          file['folder_id'] = selectedFolder;
                        });
                      },
                    );
                  },
                ),
              );
            },
          ),
  );
}
}