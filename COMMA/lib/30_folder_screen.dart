import 'package:flutter/material.dart';
import 'components.dart'; // components.dart 파일에서 정의한 위젯들 임포트
import 'folder/37_folder_files_screen.dart';
import 'folder/39_folder_section.dart';
import 'folder/38_folder_list.dart';
import '31_full_folder_list_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'model/user_provider.dart';
import 'package:provider/provider.dart';
import 'api/api.dart';
import 'mypage/44_font_size_page.dart';
import '../model/44_font_size_provider.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  List<Map<String, dynamic>> lectureFolders = [];
  List<Map<String, dynamic>> colonFolders = [];

  int _selectedIndex = 1; // 학습 시작 탭이 기본 선택되도록 설정

  final FocusNode _focusNode = FocusNode();

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchFolders();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> fetchFolders() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
   

    if (userKey != null) {
      try {
        final lectureResponse = await http.get(
          Uri.parse('${API.baseUrl}/api/lecture-folders?userKey=$userKey'),
        );
        final colonResponse = await http.get(
          Uri.parse('${API.baseUrl}/api/colon-folders?userKey=$userKey'),
        );

        if (lectureResponse.statusCode == 200 &&
            colonResponse.statusCode == 200) {
          setState(() {
            lectureFolders = List<Map<String, dynamic>>.from(
                jsonDecode(lectureResponse.body));
            colonFolders =
                List<Map<String, dynamic>>.from(jsonDecode(colonResponse.body));
          });
        } else {
          throw Exception('Failed to load folders');
        }
      } catch (e) {
        print(e);
        // 오류 처리 로직 추가 가능
      }
    }
  }

  Future<void> _addFolder(String folderName, String folderType) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;

    if (userKey != null) {
      final url = Uri.parse(
          '${API.baseUrl}/api/${folderType == 'lecture' ? 'lecture' : 'colon'}-folders');
      try {
        final response = await http.post(url,
            body: jsonEncode({'folder_name': folderName, 'userKey': userKey}),
            headers: {'Content-Type': 'application/json'});
        if (response.statusCode == 200) {
          final newFolder = jsonDecode(response.body);
          setState(() {
            if (folderType == 'lecture') {
              lectureFolders.add(newFolder);
            } else {
              colonFolders.add(newFolder);
            }
          });
        } else {
          throw Exception('Failed to add folder');
        }
      } catch (e) {
        print(e);
      }
    }
  }

  Future<void> _renameFolder(String folderType, int id, String newName) async {
    final url = Uri.parse(
        '${API.baseUrl}/api/${folderType == 'lecture' ? 'lecture' : 'colon'}-folders/$id');
    try {
      print('Sending PUT request to $url with name $newName');
      final response = await http.put(
        url,
        body: jsonEncode({'folder_name': newName}),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200) {
        print('Failed to rename folder: ${response.statusCode}');
        throw Exception('Failed to rename folder');
      } else {
        print('Folder renamed successfully');
      }
    } catch (e) {
      print('Error renaming folder: $e');
    }
  }

  Future<void> _deleteFolder(String folderType, int id) async {
    final url = Uri.parse(
        '${API.baseUrl}/api/${folderType == 'lecture' ? 'lecture' : 'colon'}-folders/$id');
    try {
      final response = await http.delete(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to delete folder');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontSizeProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(toolbarHeight: 0),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FolderSection(
                    sectionTitle: 'Lecture Folder',
                    onAddPressed: () async {
                      await showAddFolderDialog(context,
                          (folderName) => _addFolder(folderName, 'lecture'));
                    },
                    onViewAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FullFolderListScreen(
                            title: 'Lecture Folder',
                          ),
                        ),
                      );
                    },
                  ),
                  ResponsiveSizedBox(height: 16),
                  FolderList(
                    folders: lectureFolders.take(3).toList(),
                    onFolderTap: (folder) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FolderFilesScreen(
                            folderName: folder['folder_name'],
                            folderId: folder['id'],
                            folderType: 'lecture',
                          ),
                        ),
                      );
                    },
                    onRename: (index) => showRenameDialogVer2(
                        context,
                        index,
                        lectureFolders,
                        'lecture',
                        _renameFolder,
                        setState,
                        "Rename a folder", // 다이얼로그 제목
                        "folder_name" // 변경할 항목 타입
                        ),
                    onDelete: (index) => showConfirmationDialog(
                      context,
                      "Are you sure you want to delete the '${lectureFolders[index]['folder_name']}'folder?", // 다이얼로그 제목
                      "Once you delete a folder, it cannot be recovered.", // 다이얼로그 내용
                      () async {
                        await _deleteFolder(
                            'lecture', lectureFolders[index]['id']);
                        setState(() {
                          lectureFolders.removeAt(index);
                        });
                      },
                    ),
                  ),
                  ResponsiveSizedBox(height: 16), // 간격 조절
                  FolderSection(
                    sectionTitle: 'ColonFolder',
                    onAddPressed: () async {
                      await showAddFolderDialog(context,
                          (folderName) => _addFolder(folderName, 'colon'));
                    },
                    onViewAllPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FullFolderListScreen(
                            title: 'ColonFolder',
                          ),
                        ),
                      );
                    },
                  ),
                  ResponsiveSizedBox(height: 16), // 간격 조절
                  FolderList(
                    folders: colonFolders.take(3).toList(),
                    onFolderTap: (folder) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FolderFilesScreen(
                            folderName: folder['folder_name'],
                            folderId: folder['id'],
                            folderType: 'colon',
                          ),
                        ),
                      );
                    },
                    onRename: (index) => showRenameDialogVer2(
                        context,
                        index,
                        colonFolders,
                        'colon',
                        _renameFolder,
                        setState,
                        "Rename a folder", // 다이얼로그 제목
                        "folder_name" // 변경할 항목 타입
                        ),
                    onDelete: (index) => showConfirmationDialog(
                      context,
                      "Are you sure you want to delete the \n '${colonFolders[index]['folder_name']}' folder? ", // 다이얼로그 제목
                      "Once you delete a folder, it cannot be recovered.", // 다이얼로그 내용
                      () async {
                        await _deleteFolder('colon', colonFolders[index]['id']);
                        setState(() {
                          colonFolders.removeAt(index);
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar:
          buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
    );
  }
}
