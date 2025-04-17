import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_plugin/16_homepage_move.dart';
import 'package:flutter_plugin/mypage/44_font_size_page.dart';
import '66colon.dart';
import '62lecture_start.dart';
import '63record.dart';
import '30_folder_screen.dart';
import '33_mypage_screen.dart';
import '60prepare.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'model/user_provider.dart';
import 'package:provider/provider.dart';
import 'api/api.dart';
import 'package:intl/intl.dart';

BottomNavigationBar buildBottomNavigationBar(
    BuildContext context, int currentIndex, Function(int) onItemTapped) {
  final List<Widget> widgetOptions = <Widget>[
    const MainPage(),
    const FolderScreen(),
    const LearningPreparation(),
    const MyPageScreen(),
  ];

  final List<FocusNode> focusNodes =
      List.generate(widgetOptions.length, (_) => FocusNode());

  void handleItemTap(int index) {
    onItemTapped(index); // 현재 페이지 인덱스를 업데이트
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNodes[index].requestFocus();
        });
        return WillPopScope(
          onWillPop: () async {
            // 뒤로가기를 누르면 무조건 메인 화면으로 돌아가도록 설정
            if (index != 0) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MainPage()),
                (Route<dynamic> route) => false,
              );
              return false; // 현재 페이지에서는 뒤로가기를 처리하지 않음
            }
            return true;
          },
          child: Focus(
            focusNode: focusNodes[index],
            child: widgetOptions[index],
          ),
        );
      }),
    );
  }

  final theme = Theme.of(context);

  return BottomNavigationBar(
    currentIndex: currentIndex,
    showUnselectedLabels: true,
    backgroundColor: theme.scaffoldBackgroundColor,
    type: BottomNavigationBarType.fixed,
    onTap: handleItemTap,
    items: [
      buildBottomNavigationBarItem(
          context, currentIndex, 0, 'assets/navigation_bar/home.png', 'HOME'),
      buildBottomNavigationBarItem(
          context, currentIndex, 1, 'assets/navigation_bar/folder.png', 'Folder'),
      buildBottomNavigationBarItem(context, currentIndex, 2,
          'assets/navigation_bar/learningstart.png', 'Start learning'),
      buildBottomNavigationBarItem(context, currentIndex, 3,
          'assets/navigation_bar/mypage.png', 'My Page'),
    ],
    selectedItemColor: theme.colorScheme.primary,
    unselectedItemColor: theme.unselectedWidgetColor,
    selectedIconTheme: IconThemeData(color: theme.colorScheme.primary),
    unselectedIconTheme: IconThemeData(color: theme.unselectedWidgetColor),
    selectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    ),
    unselectedLabelStyle: theme.textTheme.bodySmall?.copyWith(
      color: theme.unselectedWidgetColor,
      fontWeight: FontWeight.bold,
    ),
  );
}

BottomNavigationBarItem buildBottomNavigationBarItem(BuildContext context,
    int currentIndex, int index, String iconPath, String label) {
  final bool isSelected = currentIndex == index;
  final theme = Theme.of(context);

  return BottomNavigationBarItem(
    icon: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ImageIcon(
          AssetImage(iconPath),
          color: isSelected
              ? theme.colorScheme.primary
              : theme.unselectedWidgetColor,
        ),
        const SizedBox(height: 4), // 아이콘과 라벨 사이의 간격 조정
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.unselectedWidgetColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (isSelected)
          Container(
            margin: const EdgeInsets.only(top: 2),
            height: 2,
            width: 40, // 바의 길이를 조정
            color: theme.colorScheme.primary,
          ),
      ],
    ),
    label: '',
  );
}

// Future<List<Map<String, String>>> fetchFolders() async {
//   final response =
//       await http.get(Uri.parse('http://localhost:3000/api/lecture-folders'));

//   if (response.statusCode == 200) {
//     final List<dynamic> folderList = json.decode(response.body);
//     return folderList.map((folder) {
//       return {
//         'id': folder['id'].toString(),
//         'name': folder['folder_name'].toString(),
//       };
//     }).toList();
//   } else {
//     throw Exception('Failed to load folders');
//   }
// }

// CONFIRM ALEART 1,2
void showConfirmationDialog(
  BuildContext context,
  String title,
  String content,
  VoidCallback onConfirm,
) {
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode contentFocusNode = FocusNode();
  final FocusNode cancelFocusNode = FocusNode();
  final FocusNode confirmFocusNode = FocusNode();
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Semantics(
        child: AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainer,
          title: Semantics(
            sortKey: OrdinalSortKey(1.0),
            child: Focus(
              focusNode: titleFocusNode,
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          content: Semantics(
            sortKey: OrdinalSortKey(2.0),
            child: Focus(
              focusNode: contentFocusNode,
              child: Text(
                content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.surfaceBright,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          actions: <Widget>[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Semantics(
                    sortKey: OrdinalSortKey(3.0),
                    child: Focus(
                      focusNode: cancelFocusNode,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.tertiary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    sortKey: OrdinalSortKey(4.0),
                    child: Focus(
                      focusNode: confirmFocusNode,
                      child: TextButton(
                        onPressed: () {
                          onConfirm();
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Confirm',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  // 다음 프레임에서 포커스를 타이틀에 설정합니다.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    FocusScope.of(context).requestFocus(titleFocusNode);
  });
}

// Creating - 콜론 파일 생성중 팝업
void showColonCreatingDialog(
    BuildContext context,
    String fileName, //생성된 콜론 파일 이름
    String fileURL, //강의자료 url
    ValueNotifier<double> progressNotifier) {
  final theme = Theme.of(context);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Creating a colon file',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              strokeWidth: 4.0,
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, value, child) {
                return Text(
                  '${(value * 100).toStringAsFixed(0)}%', // 진행률을 퍼센트로 표시
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

// 콜론 생성 다이얼로그 함수
void showColonCreatedDialog(BuildContext context, String folderName,
    String noteName, String lectureName, String fileUrl, int? lectureFileId) {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  final userKey = userProvider.user?.userKey;

  if (userKey != null) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(context);

        return AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          title: Column(
            children: [
              Text(
                'A colon has been created.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onTertiary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const ResponsiveSizedBox(height: 4),
              Text(
                'Folder name: $folderName (:)', // 기본폴더 대신 folderName 사용
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.surfaceBright,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const ResponsiveSizedBox(height: 4),
              Text(
                'Want to move to?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: <Widget>[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      'Cancel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(
                      'Confirm',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  } else {
    print('User Key is null, cannot create colon folder.');
  }
}

// Learning - 강의 자료 학습중 팝업
void showLearningDialog(BuildContext context, String fileName, String fileURL,
    ProgressNotifier progressNotifier) {
  final theme = Theme.of(context);

  // 변경된 부분: ProgressNotifier로 타입 변경
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        titlePadding: EdgeInsets.zero,
        contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, value, child) {
                return Column(
                  children: [
                    Text(
                      progressNotifier.message, // 메시지 표시
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF36AE92)),
                      strokeWidth: 4.0,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${(value * 100).toStringAsFixed(0)}%', // 진행률을 퍼센트로 표시
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      );
    },
  );
}

//alarm
//delete alarm
void showDeleteAlarmDialog(BuildContext context) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;

  final theme = Theme.of(context);

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 40.0,
      left: 80,
      right: 80,
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSecondary,
                  blurRadius: 10.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                'Deleted.',
                style: TextStyle(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w800),
              ),
              trailing: TextButton(
                child: Text(
                  'Confirm',
                  style: TextStyle(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w700),
                ),
                onPressed: () {
                  if (overlayEntry != null) {
                    overlayEntry.remove();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

//moved alarm & move cancel alarm
void showAlarmDialog(BuildContext context, String message) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;
  final theme = Theme.of(context);

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: 40.0,
      left: 80,
      right: 80,
      child: Material(
        color: theme.colorScheme.surfaceContainer,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onSecondary,
                  blurRadius: 10.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                message,
                style: TextStyle(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w800),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      if (overlayEntry != null) {
                        overlayEntry.remove();
                      }
                    },
                  ),
                  TextButton(
                    child: Text(
                      'Confirm',
                      style: TextStyle(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700),
                    ),
                    onPressed: () {
                      if (overlayEntry != null) {
                        overlayEntry.remove();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
}

//hamburger
Future<void> showCustomMenu(BuildContext context, VoidCallback onRename,
    VoidCallback onDelete, VoidCallback onMove) async {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final Offset buttonPosition =
      button.localToGlobal(Offset.zero, ancestor: overlay);
  final double left = buttonPosition.dx;
  final double top = buttonPosition.dy + button.size.height;
  final theme = Theme.of(context);

  await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(left, top, left + button.size.width, top),
    items: [
      PopupMenuItem<String>(
        value: 'delete',
        child: Center(
          child: Text(
            'Delete',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w700,
              height: 1.2,
              fontFamily: 'Poppins', // 폰트는 그대로 유지
            ),
          ),
        ),
      ),
      PopupMenuItem<String>(
        value: 'move',
        child: Center(
          child: Text(
            'move',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondary,
              fontWeight: FontWeight.w700,
              height: 1.2,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      PopupMenuItem<String>(
        value: 'rename',
        child: Center(
          child: Text(
            'rename',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondary,
              fontWeight: FontWeight.w700,
              height: 1.2,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    ],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: theme.colorScheme.primaryContainer,
  ).then((value) {
    if (value == 'delete') {
      onDelete();
    } else if (value == 'move') {
      onMove();
    } else if (value == 'rename') {
      onRename();
    }
  });
}

Future<void> showCustomMenu2(
    BuildContext context, VoidCallback onRename, VoidCallback onDelete) async {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject() as RenderBox;

  final Offset buttonPosition =
      button.localToGlobal(Offset.zero, ancestor: overlay);
  final double left = buttonPosition.dx;
  final double top = buttonPosition.dy + button.size.height;
  final theme = Theme.of(context);

  await showMenu<String>(
    context: context,
    position: RelativeRect.fromLTRB(left + button.size.width, top, left, top),
    items: [
      PopupMenuItem<String>(
        value: 'rename',
        child: Center(
          child: Text(
            'rename',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSecondary,
              fontWeight: FontWeight.w700,
              height: 1.2,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Center(
          child: Text(
            'delete',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.w700,
              height: 1.2,
              fontFamily: 'Poppins', // 폰트는 유지
            ),
          ),
        ),
      ),
    ],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    color: theme.colorScheme.surfaceContainer,
  ).then((value) {
    if (value == 'delete') {
      onDelete();
    } else if (value == 'rename') {
      onRename();
    }
  });
}

//로그아웃, 회원탈퇴
void showMypageDialog(BuildContext context, String title, String message,
    VoidCallback onConfirm) {
  final theme = Theme.of(context);
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: TextStyle(color: theme.colorScheme.onTertiary, fontSize: 25),
        ),
        content: Text(
          message,
          style: TextStyle(color: theme.colorScheme.onTertiary, fontSize: 18),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('cancel',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: theme.colorScheme.tertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: Text('Confirm',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: theme.colorScheme.onSecondary)),
          ),
        ],
      );
    },
  );
}

// 이름 바꾸기1 : 폴더&파일
Future<void> showRenameDialog(
  BuildContext context,
  int index,
  List<Map<String, dynamic>> items,
  Function renameItem,
  Function setState,
  String title,
  String itemType, // 'file_name' 또는 'folder_name'
) async {
  final TextEditingController nameController =
      TextEditingController(text: items[index][itemType]);
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onTertiary,
            fontWeight: FontWeight.bold,
            fontFamily: 'DM Sans',
          ),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: theme.colorScheme.onSecondary),
          decoration: InputDecoration(
              hintText: items[index][itemType],
              hintStyle: TextStyle(color: theme.colorScheme.onSecondary)),
        ),
        actions: <Widget>[
          TextButton(
            child:
                Text('Cancel', style: TextStyle(color: theme.colorScheme.tertiary)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save',
                style: TextStyle(color: theme.colorScheme.onSecondary)),
            onPressed: () async {
              await renameItem(items[index]['id'], nameController.text);
              setState(() {
                items[index][itemType] = nameController.text;
              });
              Navigator.of(context).pop();
            },
          ),
        ],

      );
    },
  );
}

// 폴더 페이지 - 햄버거 - 이름바꾸기
Future<void> showRenameDialogVer2(
    BuildContext context,
    int index,
    List<Map<String, dynamic>> items,
    String folderType, // 폴더 타입 추가
    Future<void> Function(String, int, String) renameItem,
    Function setState,
    String title,
    String itemType // 'file_name' 또는 'folder_name'
    ) async {
  final TextEditingController nameController =
      TextEditingController(text: items[index][itemType]);
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(
          title,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onTertiary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          style: TextStyle(color: theme.colorScheme.onSecondary),
          controller: nameController,
          decoration: InputDecoration(
              hintText: items[index][itemType],
              hintStyle: TextStyle(color: theme.colorScheme.onSecondary)),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.tertiary)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Save',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSecondary)),
            onPressed: () async {
              await renameItem(
                  folderType, items[index]['id'], nameController.text);
              setState(() {
                items[index][itemType] = nameController.text;
              });
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

//폴더 만들기
Future<void> showAddFolderDialog(
    BuildContext context, Function addFolder) async {
  final TextEditingController folderNameController = TextEditingController();
  final theme = Theme.of(context);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        title: Text(
          'Create a new folder',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onTertiary,
          ),
        ),
        content: TextField(
          controller: folderNameController,
          decoration: InputDecoration(
            hintText: 'Folder name',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSecondary,
            ),
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSecondary,
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(
              'Cancel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.tertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text(
              'Create',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: () async {
              await addFolder(folderNameController.text);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

class CustomRadioButton2 extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const CustomRadioButton2({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        onChanged(!isSelected);
      },
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : theme.colorScheme.onSecondary,
              border: Border.all(
                color: theme.colorScheme.onSecondary,
                width: 1.6,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSecondary,
              ),

              overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
            ),
          ),
        ],
      ),
    );
  }
}

class CustomRadioButton3 extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const CustomRadioButton3({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        onChanged(!isSelected);
      },
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : theme.colorScheme.onSecondary,
              border: Border.all(
                color: theme.colorScheme.onSecondary,
                width: 1.6,
              ),
              borderRadius: BorderRadius.circular(9),
            ),
            child: isSelected
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSecondary,
              ),
              overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
            ),
          ),
        ],
      ),
    );
  }
}

//lecture
class LectureExample extends StatelessWidget {
  final String lectureName;
  final String date;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onMove;

  const LectureExample({
    super.key,
    required this.lectureName,
    required this.date,
    required this.onRename,
    required this.onDelete,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface, // Background color
          borderRadius: BorderRadius.circular(10), // Rounded corners
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: const Color(0xFF005A38), // Color of the square
                borderRadius:
                    BorderRadius.circular(8), // Rounded corners for the square
              ),
              child: const Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.description, // 원하는 아이콘
                      color: Colors.white, // 아이콘 색상
                      size: 21, // 아이콘 크기
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lectureName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          fontFamily: 'Poppins', // 폰트 유지
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      date,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.surfaceBright,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'DM Sans', // 폰트 유지
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Builder(
              builder: (BuildContext context) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    child: Semantics(
                      label: 'File menu button',
                      child: const ImageIcon(
                        AssetImage('assets/folder_menu.png'),
                        color: Color.fromRGBO(255, 161, 122, 1),
                      ),
                    ),
                    onTap: () {
                      showCustomMenu(context, onRename, onDelete, onMove);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

//RenameDeletePopup 이름바꾸기
class RenameDeletePopup extends StatelessWidget {
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const RenameDeletePopup({
    super.key,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'rename') {
          onRename();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'rename',
          child: Text('Rename',
              style: TextStyle(color: theme.colorScheme.onSecondary)),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child:
              Text('Delete', style: TextStyle(color: theme.colorScheme.tertiary)),
        ),
      ],
    );
  }
}

class ClickButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? iconPath;
  final IconData? iconData;
  final Color? iconColor;
  final Color? backgroundColor;
  final bool isDisabled;
  final double height; // 높이를 고정할 수 있는 속성 추가

  const ClickButton({
    super.key,
    required this.text,
    this.onPressed,
    this.iconPath,
    this.iconData,
    this.iconColor,
    this.backgroundColor,
    this.height = 50.0, // 기본 높이 설정
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Define text style
    final TextStyle textStyle = theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.surface,
          fontWeight: FontWeight.w700,
        ) ??
        const TextStyle();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GestureDetector(
        onTap: isDisabled ? null : onPressed,
        child: Container(
          height: height, // 높이 설정
          padding:
              const EdgeInsets.symmetric(horizontal: 20.0), // 패딩에서 수직 방향 패딩 제거
          decoration: BoxDecoration(
            color: isDisabled
                ? Colors.grey
                : (backgroundColor ?? const Color.fromRGBO(54, 174, 146, 1.0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (iconPath != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ImageIcon(
                    AssetImage(iconPath!),
                    color: theme.colorScheme.surface,
                  ),
                )
              else if (iconData != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                    iconData,
                    color: iconColor ?? theme.colorScheme.surface,
                  ),
                ),
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis, // 긴 텍스트는 잘리도록 처리
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 폴더 리스트
class FolderListItem extends StatelessWidget {
  final Map<String, dynamic> folder;
  final int fileCount; // 추가된 파일 개수 필드
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const FolderListItem({
    super.key,
    required this.folder,
    required this.fileCount, // 추가된 파일 개수 필드
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryFixed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(204, 227, 205, 1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.folder_rounded,
                color: Color.fromARGB(255, 41, 129, 108),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              folder['folder_name'],
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onTertiary,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis, // 텍스트 오버플로우 처리
            ),
          ),
          Row(
            children: [
              Text(
                '$fileCount files',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.surfaceBright,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                child: Semantics(
                  label: 'Folder menu button',
                  child: const ImageIcon(
                    AssetImage('assets/folder_menu.png'),
                    color: Color.fromRGBO(255, 161, 122, 1),
                  ),
                ),
                onTap: () {
                  showCustomMenu2(context, onRename, onDelete);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
