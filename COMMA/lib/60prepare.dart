import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'dart:io';
import 'components.dart';
import 'model/user_provider.dart';
import 'package:provider/provider.dart';
import '62lecture_start.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_image/flutter_image.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf_render/pdf_render.dart' as pdfr;
import 'env/env.dart';
import 'package:dart_openai/dart_openai.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import './api/api.dart';
import 'package:image/image.dart' as img;
import 'mypage/44_font_size_page.dart';


bool isAlternativeTextEnabled = true;
bool isRealTimeSttEnabled = false;

bool isBasicSelected = true; // 기본 설명이 기본적으로 선택됨
bool isDetailSelected = false; // 자세한 설명은 선택되지 않음

class LearningPreparation extends StatefulWidget {
  const LearningPreparation({super.key});

  @override
  _LearningPreparationState createState() => _LearningPreparationState();
}

class ProgressNotifier extends ValueNotifier<double> {
  ProgressNotifier(double value, this.message) : super(value);

  String message;
}

class _LearningPreparationState extends State<LearningPreparation> {
  String? _selectedFileName;
  String? _downloadURL;
  bool _isMaterialEmbedded = false;
  bool _isIconVisible = true;
  Uint8List? _fileBytes;
  bool _isPDF = false;
  late pdfx.PdfController _pdfController;
  final _progressNotifier = ProgressNotifier(0.0, '');
  String _selectedFolder = 'Folder';
  String _noteName = 'New note';
  List<Map<String, dynamic>> folderList = [];
  List<Map<String, dynamic>> items = [];
  int _selectedIndex = 2;
  int? lecturefileId;
  int? lectureFolderId;
  bool isBasicSelected = true; // "기본 설명"이 선택된 상태를 관리
  bool isDetailSelected = false; // "자세한 설명"이 선택된 상태를 관리

  final FocusNode _focusNode = FocusNode(); // 추가된 부분

  @override
  void initState() {
    super.initState();

    // 유저의 타입에 따라 학습 유형 자동 설정
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userDisType = userProvider.user?.dis_type; // 유저의 dis_type 가져오기
    print(userDisType);

      //유저의 dis_type이 null인 경우 안전 처리
    if (userDisType == null) {
      print("User dis_type is null");
      return;
    }

    if (userDisType == 0) {
      // 시각장애인용 모드 (대체텍스트)
      isAlternativeTextEnabled = true;
      isRealTimeSttEnabled = false;
    } else if (userDisType == 1) {
      // 청각장애인용 모드 (실시간 자막)
      isAlternativeTextEnabled = false;
      isRealTimeSttEnabled = true;
    }

    // 폴더 목록 불러오기
    fetchFolderList();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); // 페이지 빌드 후 초점 설정
    });
  }

  @override
  void dispose() {
    _focusNode.dispose(); // 추가된 부분
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> fetchFolderList() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
  

    if (userKey != null) {
      try {
        // currentFolderId를 쿼리 파라미터로 포함
        final uri =
            Uri.parse('${API.baseUrl}/api/lecture-folders?userKey=$userKey');
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final List<dynamic> folderData = json.decode(response.body);

          setState(() {
            // 현재 선택된 폴더를 제외하고 나머지 폴더 목록 업데이트
            folderList = folderData
                .map((folder) => {
                      'id': folder['id'],
                      'folder_name': folder['folder_name'],
                      'selected': false,
                    })
                .toList();

            var defaultFolder = folderList.firstWhere(
                (folder) => folder['folder_name'] == 'Default Folder',
                orElse: () => <String, dynamic>{});
            if (defaultFolder.isNotEmpty) {
              _selectFolder(defaultFolder['folder_name']);
            }
          });
        } else {
          throw Exception('Failed to load folders');
        }
      } catch (e) {
        print('Folder list fetch failed: $e');
      }
    } else {
      print('User Key is null, cannot fetch folders.');
    }
  }

  void _selectFolder(String folderName) {
    setState(() {
      _selectedFolder = folderName;
    });
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
            // 기존의 폴더 리스트를 업데이트하는 대신, fetchedFolders를 사용합니다.
            folderList = fetchedFolders;
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

  Future<void> renameItem(String newName) async {
    setState(() {
      _noteName = newName;
    });
  }

  int getFolderIdByName(String folderName) {
    return folderList.firstWhere(
        (folder) => folder['folder_name'] == folderName,
        orElse: () => {'id': -1})['id'];
  }

  void showQuickMenu2(
    BuildContext context,
    Future<void> Function() fetchOtherFolders,
    List<Map<String, dynamic>> folders,
    Function(String) selectFolder,
  ) async {
    print('Attempting to fetch other folders.');
    try {
      await fetchOtherFolders();
      print('Fetched other folders successfully.');
    } catch (e) {
      print('Error fetching other folders: $e');
    }

    // updatedFolders는 fetchOtherFolders 호출 후 업데이트된 folderList를 사용합니다.
    var updatedFolders = folderList.map((folder) {
      bool isSelected = folder['folder_name'] == _selectedFolder;
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
      isScrollControlled: true, // 전체 화면에서 모달을 사용할 수 있게 함
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.sizeOf(context).aspectRatio + 16,
                //bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                left: 16,
                right: 16,
                top: 16,
              ),
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
                        'Move to next',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.bold,
                        ),

                      ),
                      TextButton(
                        onPressed: () async {
                          final selectedFolder = updatedFolders.firstWhere(
                              (folder) => folder['selected'] == true,
                              orElse: () => {});
                          if (selectedFolder.isNotEmpty) {
                            print(
                                'Selected folder: ${selectedFolder['folder_name']}');
                            selectFolder(selectedFolder['folder_name']);
                          } else {
                            print('No folder selected.');
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Move',
                          style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.bold,
                        ),

                        ),
                      ),
                    ],
                  ),
                  const ResponsiveSizedBox(height: 2),
                  Center(
                    child: Text(
                      'Move to another folder.',
                      style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSecondary,
                      fontFamily: 'Raleway', // 폰트 유지
                      fontWeight: FontWeight.w500, // 폰트 두께 설정
                      height: 1.5, // 줄 높이 설정
                    ),

                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: updatedFolders.length,
                      itemBuilder: (BuildContext context, int index) {
                        final folder = updatedFolders[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: CustomRadioButton2(
                            label: folder['folder_name'],
                            isSelected: folder['selected'] ?? false,
                            onChanged: (bool isSelected) {
                              setState(() {
                                for (var f in updatedFolders) {
                                  f['selected'] = false;
                                }
                                folder['selected'] = isSelected;
                              });
                              print(
                                  'Folder selected: ${folder['folder_name']}');
                            },
                          ),
                        );
                      },
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

  void showRenameDialog2(
    BuildContext context,
    String currentName,
    Future<void> Function(String) renameItem,
    void Function(VoidCallback) setState,
    String title,
    String fieldName,
  ) {
    final TextEditingController textController = TextEditingController();
    textController.text = currentName;

    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surfaceContainer,
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSecondary,
            fontWeight: FontWeight.bold, // 폰트 두께 유지
          ),
          ),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(
              hintText: "New note",
              hintStyle: TextStyle(color: theme.colorScheme.onSecondary),
            ),
            style: TextStyle(
                color: theme.colorScheme.onSecondary), // 입력할 때 글자 색상 지정
            onTap: () {
         if (textController.text == currentName) {
              textController.clear();
            } 
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save',
                  style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onTertiary,
                ),
              ),
              onPressed: () async {
                String newName = textController.text;
                await renameItem(newName);
                setState(() {
                  _noteName = newName;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    // 파일 선택이 취소된 경우
    if (result == null) {
      print("User cancelled the picker request");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have deselected a file..")),
      );
     return; // 더 이상의 처리를 하지 않도록 리턴
    }

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;

      if (fileBytes == null) {
        String? filePath = result.files.first.path;
        if (filePath != null) {
          File file = File(filePath);
          fileBytes = await file.readAsBytes();
        } else {
          return;
        }
      }
      try {
        String mimeType = 'application/octet-stream';
        if (fileName.endsWith('.pdf')) {
          mimeType = 'application/pdf';
          _isPDF = true;
        } else if (fileName.endsWith('.png') ||
            fileName.endsWith('.jpg') ||
            fileName.endsWith('.jpeg')) {
          mimeType = 'image/png';
          _isPDF = false;
        }
        
   // Define metadata
        final metadata = SettableMetadata(
          contentType: mimeType,
        );

        // 파일명 유니크하게 만들기
        int timestamp = DateTime.now().millisecondsSinceEpoch;
        int f_id = timestamp ~/ fileName.length;
        int id = f_id ~/ fileName.length;

        // Upload file with metadata
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        Reference storageRef = FirebaseStorage.instance.ref().child(
            'uploads/${userProvider.user!.userKey}/${getFolderIdByName(_selectedFolder)}/$lecturefileId/show_handle/${fileName}_${id}');
        UploadTask uploadTask = storageRef.putData(fileBytes, metadata);

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();

        setState(() {
          _selectedFileName = fileName;
          _downloadURL = downloadURL;
          _isMaterialEmbedded = true;
          _isIconVisible = false;
          _fileBytes = fileBytes;

          if (_isPDF) {
            _pdfController = pdfx.PdfController(
              document: pdfx.PdfDocument.openData(fileBytes!),
            );
          }
        });

        print('File uploaded successfully: $downloadURL');
      } catch (e) {
        print('File upload failed: $e');
      }
    }
  }

  Future<List<Uint8List>> convertPdfToImages(Uint8List pdfBytes) async {
    final document = await pdfr.PdfDocument.openData(pdfBytes);
    final pageCount = document.pageCount;
    List<Uint8List> images = [];

    for (int i = 0; i < pageCount; i++) {
      final page = await document.getPage(i + 1);
      final pageImage = await page.render(
        width: page.width.toInt(),
        height: page.height.toInt(),
        x: 0,
        y: 0,
      );

      final image = await pageImage.createImageIfNotAvailable();
      final imageData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (imageData != null) {
        images.add(imageData.buffer.asUint8List());
      }
    }
    return images;
  }

  Future<List<String>> uploadImagesToFirebase(
      List<Uint8List> images, int userKey) async {
    List<String> downloadUrls = [];

    for (int i = 0; i < images.length; i++) {
      _progressNotifier.value = (i + 1) / images.length; // 진행률 업데이트
      _progressNotifier.message = 'Uploading lecture materials to the server';

      final storageRef = FirebaseStorage.instance.ref().child(
          'uploads/$userKey/${getFolderIdByName(_selectedFolder)}/$lecturefileId/pdf_handle/page_$i.jpg');
      final uploadTask = storageRef.putData(
          images[i], SettableMetadata(contentType: 'image/jpeg'));
      final taskSnapshot = await uploadTask;
      final downloadUrl = await taskSnapshot.ref.getDownloadURL();
      downloadUrls.add(downloadUrl);
    }

    return downloadUrls;
  }

  Future<String> callChatGPT4APIForAlternativeText(
      List<String> imageUrls, int userKey, String lectureFileName) async {
    const String apiKey = Env.apiKey;
    final Uri apiUrl = Uri.parse('https://api.openai.com/v1/chat/completions');

     const String promptForAlternativeText = '''
    Please convert the content of the following lecture materials into text so that visually impaired individuals can recognize it using a screen reader. 
    Write all the text that is in the lecture materials as IT IS, with any additional description or modification.
    If there is a picture in the lecture material, please generate a alternative text which describes about the picture.
    Visually impaired individuals should be able to understand where and what letters or pictures are located in the lecture materials through this text.
    Conditions: 
    1. Write the text included in the lecture materials without any modifications. 
    2. Write as clearly and concisely as possible.
    3. When creating alternative text for images, do not indicate the position of the image. Instead, describe the image from top to bottom.
    4. Determine the type of visual content (table, diagram, graph, or other) and specify the format as [Table], [Image], [Graph], etc., followed by the descriptive text.
      After the description, mark the end with "[End of table]","[End of image]", "[End of graph]".
    5. For each slide, format the text as follows: "Topic of this page is ~~~."
    6. Write all text in the slides as continuous prose without special characters that are hard to read aloud. This includes excluding emoticons, emojis, and other symbols that are difficult to read aloud.
    7. Write numbers in words to ensure smooth reading.
    8. For mathematical formulas and symbols, write them out in text form so that they can be read aloud properly by a screen reader. This includes symbols like sigma, square root, alpha, beta, etc.
    9.If mathematical symbols appear, convert them into text form based on your judgment, ensuring that the symbols are not written as they are but transformed into readable text.
    10. When generating alternative text for images, tables, or graphs, ensure that the description provides enough detail for visually impaired individuals to fully understand the content. Include details such as the structure, data values, trends, and key information to help them grasp the meaning of the table or graph as clearly as possible.
    11. For tables, graphs, or diagrams, specify the format as [Table], [Image], [Graph], etc., followed by the descriptive text. Ensure that the description is detailed enough so that the visually impaired can understand the content as if they were seeing the table or graph themselves. Use words to explain key insights, trends, or important data points in graphs or tables.
   After the description, mark the end with "[End of table]", "[End of image]", "[End of graph]".
  ''';
  

    try {
      List<String> allResponses = [];
      _progressNotifier.value = 0.0;
      _progressNotifier.message = 'learning lecture material..';

      for (int i = 0; i < imageUrls.length; i++) {
        var url = imageUrls[i];
        _progressNotifier.value = (i + 1) / imageUrls.length;
        var messages = [
          {'role': 'system', 'content': promptForAlternativeText},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': promptForAlternativeText},
              {
                'type': 'image_url',
                'image_url': {'url': url}
              }
            ]
          }
        ];

        var data = {"model": "gpt-4o", "messages": messages, "max_tokens": 1000};

        var apiResponse = await http.post(
          apiUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(data),
        );

        if (apiResponse.statusCode == 200) {
          var responseBody = utf8.decode(apiResponse.bodyBytes);
          var decodedResponse = jsonDecode(responseBody);
          var gptResponse = decodedResponse['choices'][0]['message']['content'];
          print('GPT-4 response content for image URL: $url');
          print(gptResponse);
          String pageResponse =
              '[${i + 1} Start a page description]\n$gptResponse\n[${i + 1} End of page description] \n';
          allResponses.add(pageResponse);

          // Create a temporary text file for each page
          final directory = await getTemporaryDirectory();
          final filePath = path.join(directory.path, 'page_$i.txt');

          final file = File(filePath);
          await file.writeAsString(pageResponse);

          // Upload the file to Firebase
          final storageRef = FirebaseStorage.instance.ref().child(
              //쪼개 대체
              'div_alttxt/$userKey/${getFolderIdByName(_selectedFolder)}/$lecturefileId/page_$i.txt');
          UploadTask uploadTask = storageRef.putFile(file);

          TaskSnapshot taskSnapshot = await uploadTask;
          String responseUrl = await taskSnapshot.ref.getDownloadURL();
          print('GPT Response stored URL: $responseUrl');

          // Insert into database
          await insertIntoAltTable(lecturefileId!, responseUrl, i);

          // Delete the temporary file
          await file.delete();
        } else {
          var responseBody = utf8.decode(apiResponse.bodyBytes);
          print('Error calling ChatGPT-4 API: ${apiResponse.statusCode}');
          print('Response body: $responseBody');
        }
      }

      String finalResponse = allResponses.join();

      final directory = await getTemporaryDirectory();
      final filePath = path.join(
          directory.path, '${DateTime.now().millisecondsSinceEpoch}.txt');

      final file = File(filePath);
      await file.writeAsString(finalResponse);

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      // 통 대체
      final storageRef = FirebaseStorage.instance.ref().child(
          'response/${userProvider.user!.userKey}/${getFolderIdByName(_selectedFolder)}/$lecturefileId/${path.basename(filePath)}');
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask;
      String responseUrl = await taskSnapshot.ref.getDownloadURL();
      print('GPT Response stored URL: $responseUrl');

      await file.delete();
      return responseUrl;
    } catch (e) {
      print('Error: $e');
      return 'Error: $e';
    }
  }

  Future<void> processFileWithGpt(List<String> imageUrls, int type) async {
    String? responseUrl;
    List<String>? keywords;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // 대체텍스트와 키워드를 모두 생성
    responseUrl = await callChatGPT4APIForAlternativeText(
        imageUrls, userProvider.user!.userKey, _selectedFileName!);
    keywords = await callChatGPT4APIForKeywords(imageUrls);

    print("GPT-4 Response: $responseUrl");
    print("GPT-4 keywords: $keywords");

    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LectureStartPage(
          lectureFolderId: lectureFolderId!,
          lecturefileId: lecturefileId!, // Inserted ID 전달
          lectureName: _selectedFileName!,
          fileURL: _downloadURL!,
          responseUrl: responseUrl ?? '', // null일 경우 빈 문자열 전달
          type: type, // 대체인지 실시간인지 전달해줌
          selectedFolder: _selectedFolder,
          noteName: _noteName,
          keywords: keywords ?? [], // 키워드 전달
        ),
      ),
    );
  }

  Future<List<String>> callChatGPT4APIForKeywords(
      List<String> imageUrls) async {
    const String apiKey = Env.apiKey;
    final int maxKeywordPerPage = (100 / imageUrls.length).ceil();
    final Uri apiUrl = Uri.parse('https://api.openai.com/v1/chat/completions');
    final String promptForKeywords = '''
  You are an image analysis expert. Please extract the keywords in the following image. The conditions are as follows:
  1. Please list the non-overlapping keywords.
  2. Please extract only the key keywords in the class.
  3. Please list each keyword separated by a comma.
  4. The maximum number of keywords is $maxKeywordPerPage.
  ''';

    try {
      List<String> allKeywords = [];

      for (int i = 0; i < imageUrls.length; i++) {
        var url = imageUrls[i];
        var messages = [
          {'role': 'system', 'content': promptForKeywords},
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': promptForKeywords},
              {
                'type': 'image_url',
                'image_url': {'url': url}
              }
            ]
          }
        ];

        var data = {
          "model": "gpt-4o",
          "messages": messages,
          "max_tokens": 1000
        };

        var apiResponse = await http.post(
          apiUrl,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode(data),
        );

        if (apiResponse.statusCode == 200) {
          var responseBody = utf8.decode(apiResponse.bodyBytes);
          var decodedResponse = jsonDecode(responseBody);
          var gptResponse = decodedResponse['choices'][0]['message']['content'];
          print('GPT-4 response content for image URL: $url');
          print(gptResponse);

          // Extract keywords from GPT response
          var keywords = gptResponse.split('&');
          allKeywords.addAll(keywords);
        } else {
          var responseBody = utf8.decode(apiResponse.bodyBytes);
          print('Error calling ChatGPT-4 API: ${apiResponse.statusCode}');
          print('Response body: $responseBody');
        }
      }

      // Remove duplicates and limit to 50 keywords
      var uniqueKeywords = allKeywords.toSet().toList();
      if (uniqueKeywords.length > 100) {
        uniqueKeywords = uniqueKeywords.sublist(0, 100);
      }

      // ,기준으로 분리? => 로직 수정 필요
      String keywordContent = uniqueKeywords.join(',');

      // 키워드 파이어베이스에 저장하기
      final directory = await getTemporaryDirectory();
      final filePath = path.join(directory.path,
          '${DateTime.now().millisecondsSinceEpoch}_keywords.txt');

      final file = File(filePath);
      await file.writeAsString(keywordContent);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final storageRef = FirebaseStorage.instance.ref().child(
          'keywords/${userProvider.user!.userKey}/${getFolderIdByName(_selectedFolder)}/$lecturefileId/${path.basename(filePath)}');
      UploadTask uploadTask = storageRef.putFile(file);

      TaskSnapshot taskSnapshot = await uploadTask;
      String keywordsFileUrl = await taskSnapshot.ref.getDownloadURL();
      print('Keywords file stored at URL: $keywordsFileUrl');

      // Delete the temporary file
      await file.delete();

      // DB에 lecturefile_id와 keywords_url 저장
      await insertKeywordsIntoDB(lecturefileId!, keywordsFileUrl);

      return uniqueKeywords;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

// Keywords_table에 lecturefile_id와 keywords_url 삽입
  Future<void> insertKeywordsIntoDB(
      int lecturefileId, String keywordsFileUrl) async {
    try {
      final response = await http.post(
        Uri.parse('${API.baseUrl}/api/insert-keywords'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'lecturefileId': lecturefileId,
          'keywordsFileUrl': keywordsFileUrl,
        }),
      );

      if (response.statusCode == 200) {
        print('Keywords successfully inserted into DB.');
      } else {
        print('Failed to insert keywords into DB.');
      }
    } catch (e) {
      print('Error inserting keywords into DB: $e');
    }
  }

  Future<List<String>> handlePdfUpload(Uint8List pdfBytes, int userKey) async {
    try {
      // PDF를 이미지로 변환
      print('Starting PDF to image conversion...');
      List<Uint8List> images = await convertPdfToImages(pdfBytes);
      print(
          'PDF to image conversion completed. Number of images: ${images.length}');

      // 이미지를 Firebase에 업로드
      print('Starting image upload to Firebase...');
      List<String> imageUrls = await uploadImagesToFirebase(images, userKey);
      print(
          'Image upload to Firebase completed. Number of image URLs: ${imageUrls.length}');

      // 이미지 URL 리스트 반환
      return imageUrls;
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  void _onLearningTypeChanged(bool? isAlternativeText) {
    if (isAlternativeText != null) {
      setState(() {
        isAlternativeTextEnabled = isAlternativeText;
        isRealTimeSttEnabled = !isAlternativeText;
      });
    }
  }

//데베에 폴더id,파일이름을 삽입하는 함수
  Future<int> saveLectureFile(
      {required int folderId, required String noteName}) async {
    final response = await http.post(
      Uri.parse('${API.baseUrl}/api/lecture-files'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'folder_id': folderId,
        'file_name': noteName,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['id'];
    } else {
      throw Exception('Failed to save lecture file');
    }
  }

// 데베 업데이트 file URL,lecture name,type
  Future<void> updateLectureDetails(
      int lecturefileId, String fileUrl, String lectureName, int type) async {
    final response = await http.post(
      Uri.parse('${API.baseUrl}/api/update-lecture-details'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'lecturefileId': lecturefileId,
        'file_url': fileUrl,
        'lecture_name': lectureName,
        'type': type,
      }),
    );

    if (response.statusCode == 200) {
      print('Lecture details updated successfully');
    } else {
      throw Exception('Failed to update lecture details');
    }
  }

  //쪼개 대체 데베 삽입
  Future<void> insertIntoAltTable(
      int lecturefileId, String url, int page) async {
    final response = await http.post(
      Uri.parse('${API.baseUrl}/api/alt-table2'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'lecturefile_id': lecturefileId,
        'alternative_text_url': url,
        'page': page,
      }),
    );

    if (response.statusCode == 200) {
      print('Successfully inserted into Alt_table2');
    } else {
      print('Failed to insert into Alt_table2');
    }
  }

  Future<void> _processFile() async {
  // 특정 값이 null인 경우 상태 초기화 및 리셋
  if (_selectedFileName == null || _downloadURL == null || lecturefileId == null) {
    print("Error: File name, URL, or lecture file ID is null. Please upload the lecture material first.");
    
    // 상태 초기화
    setState(() {
      _isMaterialEmbedded = false;
      _selectedFileName = null;
      _downloadURL = null;
      _fileBytes = null;
      _isIconVisible = true;
      _isPDF = false;
      lecturefileId = null;

    });

    // 초기화 후 안내 메시지 출력
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Please select the file again.")),
    );
    return;
  }
}

  @override
Widget build(BuildContext context) {
  final theme = Theme.of(context);

    // 유저의 dis_type 가져오기
  final userProvider = Provider.of<UserProvider>(context);
  final userDisType = userProvider.user?.dis_type;

   // userDisType이 null인 경우 처리
  if (userDisType == null) {
    return Center(
      child: Text(
        "No user information found, please try again.",
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  // 학습 유형에 따라 제목 설정
  String titleText = ' Get ready to learn';
  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    appBar: AppBar(toolbarHeight: 0),
    body: ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const ResponsiveSizedBox(height: 15),
        Focus(
          focusNode: _focusNode, // 추가된 부분
          child: Semantics(
            focusable: true,
            child: Text(
              titleText,
               style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
            ),
          ),
        ),
        const ResponsiveSizedBox(height: 50),
        Text(
          'Set the lecture folder and file name.',
          style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSecondary,
          fontWeight: FontWeight.bold,
      ),
        ),
        const ResponsiveSizedBox(height: 15),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: 'Choose a folder to save to',
                child: GestureDetector(
                  onTap: () {
                    int currentFolderId =
                        folderList.isNotEmpty ? folderList.first['id'] : 0;
                    // showQuickMenu 호출
                    showQuickMenu2(
                      context,
                      () => fetchOtherFolders('lecture', currentFolderId),
                      folderList,
                      _selectFolder,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_open,
                        color: theme.colorScheme.onSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Folders > $_selectedFolder',
                          style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const ResponsiveSizedBox(height: 10),
              Semantics(
                label: 'Set a file name',
                child: GestureDetector(
                  onTap: () {
                    showRenameDialog2(
                      context,
                      _noteName,
                      renameItem,
                      setState,
                      "Rename a file", // 다이얼로그 제목
                      "file_name", // 변경할 항목 타입
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book_outlined,
                        color: theme.colorScheme.onSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _noteName,
                         style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const ResponsiveSizedBox(height: 50),
        Center(
          child: ClickButton(
            text: _isMaterialEmbedded ? 'Start learning lecture material' : 'Embed lecture materials',
            onPressed: () async {
              if (!_isMaterialEmbedded) {
                print("Starting file upload");
                // `lectureFolderId` 설정
                lectureFolderId = getFolderIdByName(_selectedFolder);
                print('${lectureFolderId}');

                try {
                  final userProvider =
                      Provider.of<UserProvider>(context, listen: false);
                  // API 호출
                  lecturefileId = await saveLectureFile(
                    folderId: lectureFolderId!,
                    noteName: _noteName, //노트이름
                  );
                  print("Lecture file saved with ID: $lecturefileId");
                  await _pickFile(); // 파일 선택 후 업로드
                  // null check - 파일이 임베드 되었을때만 true가 되도록 변경
                  // setState(() {
                  //   _isMaterialEmbedded = true;
                  // });
                } catch (e) {
                  print('Error: $e');
                }
              } else {
                print("Starting learning with file: $_selectedFileName");
                print("alt text enabled: $isAlternativeTextEnabled");
                print("Real-time captions enabled: $isRealTimeSttEnabled");

               if (_selectedFileName == null || _downloadURL == null || lecturefileId == null) {
              _processFile();
  
                return;
              }

                if (_selectedFileName != null &&
                    _downloadURL != null &&
                    _isMaterialEmbedded) {
                  showLearningDialog(context, _selectedFileName!,
                      _downloadURL!, _progressNotifier);

                  try {
                    final userProvider =
                        Provider.of<UserProvider>(context, listen: false);
                    int type =
                        isAlternativeTextEnabled ? 0 : 1; // 대체면 0, 실시간이면 1
                    //데베에 fileUrl, lecturename, type
                    print(lecturefileId!);
                    print(type);
                    await updateLectureDetails(lecturefileId!, _downloadURL!,
                        _selectedFileName!, type);

                    if (_fileBytes != null) {
                      if (_isPDF) {
                        handlePdfUpload(
                            _fileBytes!, userProvider.user!.userKey)
                            .then((imageUrls) async {
                          await processFileWithGpt(imageUrls, type);
                        });
                      } else {
                        // PDF가 아닌 경우 직접 파일 URL을 사용하여 GPT-4 API 호출
                        List<String> fileUrls = [_downloadURL!];
                        await processFileWithGpt(fileUrls, type);
                      }
                    }
                  } catch (e) {
                    if (Navigator.canPop(context)) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                    print('Error: $e');
                  }
                } else {
                  print(
                      'Error: File name, URL, or embedded material is missing.');
                }
              }
            },
            // width: MediaQuery.sizeOf(context).width * 0.7,
            // height: 50.0,
            iconPath: _isIconVisible ? 'assets/Vector.png' : null,
          ),
        ),
        if (_isMaterialEmbedded && _selectedFileName != null)
          Column(
            children: [
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Icon(_isPDF ? Icons.picture_as_pdf : Icons.image,
                        color: _isPDF ? Colors.red : Colors.blue, size: 40),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSecondary,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        if (_downloadURL != null)
          _isPDF
              ? SizedBox(
            height: 600,
            child: pdfx.PdfView(
              controller: _pdfController,
            ),
          )
              : Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Image.network(
              _downloadURL!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading image: $error');
                print('Stack trace: $stackTrace');
                print('Image URL: $_downloadURL');

                return Center(
                  child: Text(
                    'Unable to load images.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.tertiary,
                      ),
                  ),
                );
              },
            ),
          ),
      ],
    ),
    bottomNavigationBar:
    buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
  );
}
}
