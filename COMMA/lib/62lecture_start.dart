import 'package:flutter/material.dart';
import 'package:flutter_plugin/model/user.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'components.dart';
import '63record.dart';
import 'package:provider/provider.dart';
import 'model/user_provider.dart';
import 'api/api.dart';
import 'mypage/44_font_size_page.dart';

class LectureStartPage extends StatefulWidget {
  final int? lectureFolderId;
  final int? lecturefileId;
  final String lectureName;
  final String fileURL;
  final String? responseUrl;
  final int type;
  final String? selectedFolder;
  final String? noteName;
  final List<String>? keywords;

  const LectureStartPage({
    super.key,
    this.lectureFolderId,
    this.lecturefileId,
    required this.lectureName,
    required this.fileURL,
    this.responseUrl,
    required this.type,
    this.selectedFolder,
    this.noteName,
    this.keywords,
  });

  @override
  _LectureStartPageState createState() => _LectureStartPageState();
}

class _LectureStartPageState extends State<LectureStartPage> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    print("LectureStartPage Keywords: ${widget.keywords}");
  }

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
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveSizedBox(height: 15),
            Text(
              'Start learning',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onTertiary,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            ResponsiveSizedBox(height: 30),
            Text(
              'AI learning of the uploaded lecture material is complete!\nEnter the classroom to start learning.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSecondary,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            ResponsiveSizedBox(height: 30),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.lectureName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.w500,
                            height: 1.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveSizedBox(height: 15),
            GestureDetector(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    color: theme.colorScheme.onSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Categorise folders > ${widget.selectedFolder}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveSizedBox(height: 10),
            GestureDetector(
              child: Row(
                children: [
                  Icon(
                    Icons.book_outlined,
                    color: theme.colorScheme.onSecondary,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.noteName!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSecondary,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ResponsiveSizedBox(height: 100),
            Center(
              child: ClickButton(
                text: 'Enter the classroom',
                onPressed: () async {
                  if (widget.lecturefileId != null) {
                    print("existLecture update");
                    print(widget.lecturefileId);
                    try {
                      final response = await http.post(
                        Uri.parse('${API.baseUrl}/api/update-existLecture'),
                        headers: {'Content-Type': 'application/json'},
                        body:
                            jsonEncode({'lecturefileId': widget.lecturefileId}),
                      );

                      if (response.statusCode == 200) {
                        print('existLecture Update successful');
                      } else {
                        print('existLecture Update failed');
                        print('Response status: ${response.statusCode}');
                        print('Response body: ${response.body}');
                      }
                    } catch (e) {
                      print('Error occurred during existLecture update: $e');
                    }
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordPage(
                        lectureFolderId: widget.lectureFolderId!,
                        noteName: widget.noteName!,
                        fileUrl: widget.fileURL,
                        folderName: widget.selectedFolder!,
                        recordingState: RecordingState.initial,
                        lectureName: widget.lectureName,
                        responseUrl: widget.responseUrl != null
                            ? widget.responseUrl
                            : null,
                        type: widget.type, //대체인지 실시간인지 전달해줌
                        lecturefileId: widget.lecturefileId,
                        keywords: widget.keywords,
                      ),
                    ),
                  );
                },
                // width: MediaQuery.sizeOf(context).width * 0.5,
                // height: 50.0,
              ),
            ),
            ResponsiveSizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar:
          buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
    );
  }
}
