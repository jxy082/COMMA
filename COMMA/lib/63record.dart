import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_plugin/60prepare.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:web_socket_channel/io.dart';
import 'dart:async';
import 'dart:io';

import 'components.dart';
import 'api/api.dart';
import 'model/user_provider.dart';
import '62lecture_start.dart';
import '66colon.dart';
import 'env/env.dart';
import 'folder/37_folder_files_screen.dart';
import 'mypage/44_font_size_page.dart';

enum RecordingState { initial, recording, recorded }

const serverUrl =
    'wss://api.deepgram.com/v1/listen?model=nova-2&encoding=linear16&sample_rate=16000&language=ko-KR&punctuate=true';
const apiKey = 'e8f1fe0d8f088e4cf2e01a1f11dc190d60b37b2b';

class RecordPage extends StatefulWidget {
  final int? lecturefileId;
  final int? lectureFolderId;
  final String noteName;
  final String fileUrl;
  final String folderName;
  final RecordingState recordingState;
  final String lectureName;
  final String? responseUrl;
  final int type;
  final List<String>? keywords;

  const RecordPage(
      {super.key,
      this.lecturefileId,
      required this.lectureFolderId,
      required this.noteName,
      required this.fileUrl,
      required this.folderName,
      required this.recordingState,
      required this.lectureName,
      this.responseUrl,
      required this.type,
      this.keywords});

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late RecordingState _recordingState;
  int _selectedIndex = 2;
  dynamic _createdAt;
  bool _isPDF = false;
  PdfController? _pdfController;
  Uint8List? _fileBytes;
  int _currentPage = 1;
  final Set<int> _blurredPages = {};
  Map<int, String> pageTexts = {};
  bool _isColonCreated = false;
  int? _existColon;
  final ValueNotifier<double> progressNotifier = ValueNotifier<double>(0.0);
  List<Map<String, dynamic>> folderList = [];

  bool _isListening = false;
  String _recognizedText = '';
  String _interimText = '';
  int _currentLength = 0; // 자막 길이
  String combineText = ''; // 문단 구분 위한 변수
  int _recordCount = 0; // 자막 개수
  int _upgradeRecordCount = 0; // 업그레이드 자막 개수
  double scaleFactor = 1.0;

  final RecorderStream _recorder = RecorderStream();
  late StreamSubscription _recorderStatus;
  late StreamSubscription _audioStream;
  late IOWebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    _recordingState = widget.recordingState;
    if (_recordingState == RecordingState.recorded) {
      _fetchCreatedAt();
      _checkExistColon();
      _loadRecordedTexts(); // 녹음된 자막 로드
    }
    if (_recordingState == RecordingState.initial) {
      // _insertInitialData();
    }
    _checkFileType();
    if (widget.type == 0) {
      // 대체 텍스트인 경우에만 호출
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        await loadPageTexts(lectureFileId: widget.lecturefileId); // 비동기 함수 호출
      });
    }
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  @override
  void dispose() {
    _recorderStatus.cancel();
    _audioStream.cancel();
    channel.sink.close();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
  }

  String buildServerUrlWithKeywords(String baseUrl, List<String> keywordList) {
    final List<String> keywords = keywordList
        .expand((keyword) => keyword.split(','))
        .map((keyword) => keyword.trim())
        .toList();
    final keywordQuery =
        keywords.map((keyword) => 'keywords=$keyword').join('&');
    return '$baseUrl&$keywordQuery';
  }

  Future<void> _initStream() async {
    // 키워드가 있을 경우 serverUrl에 키워드 추가
    final List<String> keywords = widget.keywords ?? [];
    final String urlWithKeywords =
        buildServerUrlWithKeywords(serverUrl, keywords);
    print(urlWithKeywords);

    channel = IOWebSocketChannel.connect(Uri.parse(urlWithKeywords),
        headers: {'Authorization': 'Token $apiKey'});

    channel.stream.listen((event) async {
      final parsedJson = jsonDecode(event);

      if (parsedJson.containsKey('is_final') && parsedJson['is_final']) {
        updateText(parsedJson['channel']['alternatives'][0]['transcript']);
      } else if (parsedJson.containsKey('channel')) {
        interimUpdateText(
            parsedJson['channel']['alternatives'][0]['transcript']);
      }
    });

    _audioStream = _recorder.audioStream.listen((data) {
      channel.sink.add(data);
    });

    _recorderStatus = _recorder.status.listen((status) {
      if (mounted) {
        setState(() {});
      }
    });

    await _recorder.initialize();
  }

  void onLayoutDone(Duration timeStamp) async {
    await Permission.microphone.request();
    setState(() {});
  }

  void interimUpdateText(newText) {
    setState(() {
      _interimText = newText;
    });
  }

  void updateText(String newText) {
    setState(() {
      _interimText = '';
      final processedText = processParagraphs(newText);
      _recognizedText =
          _recognizedText + ' ' + processedText; // 처리된 텍스트를 기존 텍스트에 추가
    });
  }

  String processParagraphs(String newText, {bool? isFinal}) {
    const int maxLength = 200; // 단락을 나눌 텍스트의 최대 길이
    StringBuffer buffer = StringBuffer();

    combineText += newText;
    _currentLength = combineText.length;

    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      if (_currentLength >= maxLength &&
          (newText[i] == '.' || newText[i] == '?' || newText[i] == '!')) {
        buffer.write('\n\n'); // 단락을 나눌 때 개행 문자를 추가

        // Firebase에 저장
        String paragraph = combineText.replaceAll('\n\n', ' ');
        saveTranscriptPart(paragraph);

        _currentLength = 0; // 카운트 초기화
        combineText = ''; // combineText 초기화
        // 새로운 단락 시작
        // buffer.clear();
      }
    }

    // 마지막 남은 텍스트 저장
    if (isFinal != null && isFinal == true && combineText.trim().isNotEmpty) {
      String finalParagraph = combineText.replaceAll('\n\n', ' ');
      saveTranscriptPart(finalParagraph);
      combineText = ''; // 저장 후 초기화
      _currentLength = 0; // 초기화
    }

    return buffer.toString();
  }

  Future<void> saveTranscriptPart(String text) async {
    try {
      Uint8List fileBytes = Uint8List.fromList(utf8.encode(text));
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userKey = userProvider.user?.userKey;

      if (userKey != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
            'record/$userKey/${widget.lectureFolderId}/${widget.lecturefileId}/record-$_recordCount.txt');
        _recordCount++; // 파일 번호 증가

        UploadTask uploadTask = storageRef.putData(fileBytes,
            SettableMetadata(contentType: 'text/plain; charset=utf-8'));

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();
        print('Transcript part uploaded: $downloadURL');

        await _insertRecordData(widget.lecturefileId, null, downloadURL);
      } else {
        print('User ID is null, cannot save transcript.');
      }
    } catch (e) {
      print('Error saving transcript: $e');
    }
  }

  // 자막 업그레이드 관련 메서드 시작

  Future<void> processTranscripts(
      int lecturefileId, List<String> keywords) async {
    // 1. 데이터베이스에서 자막 URL 가져오기
    List<String> transcriptUrls = await fetchTranscriptUrls(lecturefileId);

    for (String url in transcriptUrls) {
      // 2. URL로 파이어베이스에서 자막 파일 불러오기
      String transcriptText = await fetchTranscriptText(url);

      // 3. GPT로 자막 수정 (keywords는 이미 정해져 있다고 가정)
      String upgradedText =
          await callGptRecordUpgrade(keywords, transcriptText);

      // 4. 수정된 자막을 다시 파이어베이스에 업로드하고 새로운 URL 받기, 데베에 저장
      await saveUpgradeTranscriptPart(upgradedText, lecturefileId);
    }
  }

  Future<List<String>> fetchTranscriptUrls(int? lecturefileId) async {
    final url =
        '${API.baseUrl}/api/get-transcript-urls?lecturefile_id=$lecturefileId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = jsonDecode(response.body);
        return List<String>.from(jsonResponse.map((item) => item['url']));
      } else {
        throw Exception(
            'Failed to fetch transcript URLs: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching transcript URLs: $e');
      return [];
    }
  }

  Future<String> fetchTranscriptText(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return utf8.decode(response.bodyBytes); // 파이어베이스에서 텍스트 가져오기
      } else {
        throw Exception(
            'Failed to load transcript text: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching transcript text: $e');
      return '';
    }
  }

  // GPT API 호출을 통한 자막 수정
  Future<String> callGptRecordUpgrade(
      List<String> keywords, String transcriptText) async {
    const String apiKey = Env.apiKey;
    final Uri apiUrl = Uri.parse('https://api.openai.com/v1/chat/completions');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    };

    String prompt = '''
  You are an expert in speech-to-text correction.
  I will provide you with a transcript and a list of keywords. 
  Please correct any errors in the transcript while ensuring the keywords are accurately reflected.
  Please change the words in the keyword exactly and do not change anything else. Please keep the original subtitles as much as possible, but correct strange words, spaces, and incorrect punctuation marks.
  Please do not answer anything other than the revised subtitles. 
  Please tell me only the revised subtitles for the answers.

  Keywords: ${keywords.join(', ')}
  Transcript: $transcriptText
  ''';

    String body = jsonEncode({
      'model': 'gpt-4o', // GPT 모델 선택
      'messages': [
        {
          'role': 'system',
          'content': 'You are an expert in speech-to-text correction.'
        },
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 1000
    });

    final response = await http.post(apiUrl, headers: headers, body: body);
    if (response.statusCode == 200) {
      // UTF-8로 디코딩
      var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes));

      // GPT API 응답에서 필요한 내용 추출
      var upgradedText =
          decodedResponse['choices'][0]['message']['content'].trim();

      return upgradedText; // 수정된 자막 반환
    } else {
      throw Exception('Failed to call GPT API: ${response.statusCode}');
    }
  }

  Future<void> saveUpgradeTranscriptPart(
      String text, int? lecturefileId) async {
    try {
      // 텍스트를 바이트로 변환
      Uint8List fileBytes = Uint8List.fromList(utf8.encode(text));
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userKey = userProvider.user?.userKey;

      if (userKey != null) {
        // Firebase 스토리지 경로 설정 (업그레이드된 자막 저장)
        final storageRef = FirebaseStorage.instance.ref().child(
            'record_upgrade/$userKey/${widget.lectureFolderId}/${widget.lecturefileId}/record_upgrade-$_upgradeRecordCount.txt');

        _upgradeRecordCount++; // 파일 번호 증가

        // Firebase에 업로드
        UploadTask uploadTask = storageRef.putData(fileBytes,
            SettableMetadata(contentType: 'text/plain; charset=utf-8'));

        TaskSnapshot taskSnapshot = await uploadTask;
        String downloadURL = await taskSnapshot.ref.getDownloadURL();
        print('Upgraded transcript part uploaded: $downloadURL');

        // 업로드된 URL을 데이터베이스에 저장
        await _insertUpgradeRecordData(lecturefileId, null, downloadURL);
      } else {
        print('User ID is null, cannot save upgraded transcript.');
      }
    } catch (e) {
      print('Error saving upgraded transcript: $e');
    }
  }

// Record_table2에 업그레이드된 자막 데이터 저장
  Future<void> _insertUpgradeRecordData(
      int? lecturefileId, int? colonfileId, String downloadURL) async {
    final url = '${API.baseUrl}/api/insertUpgradeRecordData';
    final body = {
      'lecturefile_id': lecturefileId,
      'colonfile_id': colonfileId,
      'record_url': downloadURL,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Upgraded record added successfully to Record_table2');
      } else {
        print('Failed to add upgraded record: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('Error adding upgraded record to Record_table2: $e');
    }
  }

  // 자막 업그레이드 관련 메서드 끝

  Future<void> _checkExistColon() async {
    var url =
        '${API.baseUrl}/api/check-exist-colon?lecturefileId=${widget.lecturefileId}';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      var existColon = jsonResponse['existColon'];

      setState(() {
        _isColonCreated = existColon != null;
        _existColon = existColon;
        print(_existColon);
      });

      if (existColon != null) {
        print('A colon already exists. Convert it to a colon move button.');
      }
    } else {
      print('Failed to check existColon: ${response.statusCode}');
      print(response.body);
    }
  }

  Future<Map<String, dynamic>> _fetchColonDetails(int? colonId) async {
    var url = '${API.baseUrl}/api/get-colon-details?colonId=$colonId';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load colon details');
    }
  }

  Future<String> _fetchColonFolderName(int folderId) async {
    var url = '${API.baseUrl}/api/get-Colonfolder-name?folderId=$folderId';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse['folder_name'];
    } else {
      throw Exception('Failed to load folder name');
    }
  }

  Future<void> _loadRecordedTexts() async {
    try {
      final response = await http.get(Uri.parse(
          '${API.baseUrl}/api/get-record-urls?lecturefileId=${widget.lecturefileId}'));

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');

        final fileData = jsonDecode(response.body);
        final recordedTextUrls = fileData['record_urls'];

        for (String url in recordedTextUrls) {
          final textResponse = await http.get(Uri.parse(url));
          if (textResponse.statusCode == 200) {
            setState(() {
              _recognizedText +=
                  utf8.decode(textResponse.bodyBytes).replaceAll('\n\n', ' ') +
                      "\n\n"; // 문단 구분 추가
            });
          } else {
            print('Failed to fetch text file: ${textResponse.statusCode}');
          }
        }
      } else {
        print('Failed to fetch recorded text URLs: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  // 페이지 텍스트를 로드하는 함수
// lecturefileId와 colonFileId를 구분하여 처리
  Future<void> loadPageTexts({int? lectureFileId, int? colonFileId}) async {
    try {
      // 1. lectureFileId가 있는 경우 먼저 처리
      if (lectureFileId != null) {
        print('Using lectureFileId to fetch alternative text URLs');

        // lectureFileId로 대체 텍스트 URL 리스트 가져오기
        final response = await http.get(Uri.parse(
            '${API.baseUrl}/api/get-alternative-text-urls?lecturefileId=$lectureFileId'));

        if (response.statusCode == 200) {
          // JSON 응답을 디코딩하여 alternative_text_urls 리스트 추출
          final fileData = jsonDecode(response.body);
          final List<dynamic> alternativeTextUrls =
              fileData['alternative_text_urls'];

          if (alternativeTextUrls.isNotEmpty) {
            Map<int, String> allTexts = {};

            // 각 URL에서 텍스트 데이터를 가져와 페이지별로 저장
            for (int urlIndex = 0;
                urlIndex < alternativeTextUrls.length;
                urlIndex++) {
              final textResponse =
                  await http.get(Uri.parse(alternativeTextUrls[urlIndex]));

              if (textResponse.statusCode == 200) {
                // URL에서 받은 텍스트를 페이지에 대응하여 저장
                final text = utf8.decode(textResponse.bodyBytes);
                allTexts[urlIndex + 1] = text;
              } else {
                print('Failed to fetch text file from URL $urlIndex');
              }
            }

            // 모든 텍스트 데이터를 setState로 업데이트
            setState(() {
              pageTexts = allTexts;
            });
          } else {
            print('Alternative text URLs list is empty');
          }
        } else {
          print(
              'Failed to fetch alternative text URLs: ${response.statusCode}');
        }
      }
      // 2. lectureFileId가 없고 colonFileId가 제공된 경우 처리
      else if (colonFileId != null) {
        print('Using colonFileId to fetch alternative text URLs');
        // colonFileId로 대체 텍스트 URL 리스트 가져오기
        var url = '${API.baseUrl}/api/get-alt-url/$colonFileId';
        var response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          // JSON 응답을 디코딩하여 alternative_text_urls 리스트 추출
          var jsonResponse = jsonDecode(response.body);
          final List<dynamic> alternativeTextUrls =
              jsonResponse['alternative_text_urls'];

          if (alternativeTextUrls.isNotEmpty) {
            Map<int, String> allTexts = {};

            // 각 URL에서 텍스트 데이터를 가져와 페이지별로 저장
            for (int urlIndex = 0;
                urlIndex < alternativeTextUrls.length;
                urlIndex++) {
              final textResponse =
                  await http.get(Uri.parse(alternativeTextUrls[urlIndex]));

              if (textResponse.statusCode == 200) {
                // URL에서 받은 텍스트를 페이지에 대응하여 저장
                final text = utf8.decode(textResponse.bodyBytes);
                allTexts[urlIndex + 1] = text;
              } else {
                print('Failed to fetch text file from URL $urlIndex');
              }
            }

            // 모든 텍스트 데이터를 setState로 업데이트
            setState(() {
              pageTexts = allTexts;
            });
          } else {
            print('Alternative text URLs list is empty');
          }
        } else {
          print('Failed to fetch alternative text URLs using colonFileId');
        }
      } else {
        // lectureFileId와 colonFileId가 둘 다 제공되지 않은 경우 처리
        print('Neither lectureFileId nor colonFileId is provided');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  // Future<String> fetchRecordUrl(int colonFileId) async {
  //   try {
  //     final response = await http.get(Uri.parse(
  //         '${API.baseUrl}/api/get-record-url?colonfileId=$colonFileId'));

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       print('스크립트 잘 찾았어요 ${data['record_url']}');
  //       return data['record_url'];
  //     } else {
  //       throw Exception('Failed to fetch record URL');
  //     }
  //   } catch (e) {
  //     print('Error occurred: $e');
  //     throw e;
  //   }
  // }

  void _toggleBlur(int page) {
    setState(() {
      if (_blurredPages.contains(page)) {
        _blurredPages.remove(page);
      } else {
        _blurredPages.add(page);
      }
    });
  }

  void _checkFileType() {
    final fileName = widget.lectureName.toLowerCase();
    if (fileName.endsWith('.pdf')) {
      setState(() {
        _isPDF = true;
        _loadPdfFile(widget.fileUrl);
      });
    } else if (fileName.endsWith('.png') ||
        fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg')) {
      setState(() {
        _isPDF = false;
        _loadImageFile(widget.fileUrl);
      });
    } else {
      setState(() {
        _isPDF = false;
      });
    }
  }

  void _loadPdfFile(String url) async {
    final response = await http.get(Uri.parse(widget.fileUrl));
    if (response.statusCode == 200) {
      setState(() {
        _fileBytes = response.bodyBytes;
        if (_fileBytes != null) {
          _pdfController = PdfController(
            document: PdfDocument.openData(_fileBytes!),
          );
          _isPDF = true; // PDF가 성공적으로 로드되었음을 표시
        }
      });
    } else {
      print('Failed to load PDF file: ${response.statusCode}');
    }
  }

  void _loadImageFile(String url) async {
    final response = await http.get(Uri.parse(widget.fileUrl));
    if (response.statusCode == 200) {
      setState(() {
        _fileBytes = response.bodyBytes;
      });
    } else {
      print('Failed to load image file: ${response.statusCode}');
    }
  }

  // Future<void> _insertInitialData() async {
  //   final userProvider = Provider.of<UserProvider>(context, listen: false);
  //   final userKey = userProvider.user?.userKey;

  //   print('Alt_table에 대체텍스트 url 저장하겠습니다');

  //   var altTableUrl = '${API.baseUrl}/api/alt-table';
  //   var altTableBody = {
  //     'lecturefile_id': widget.lecturefileId,
  //     'colonfile_id': null,
  //     'alternative_text_url': widget.responseUrl ?? '',
  //   };

  //   var altTableResponse = await http.post(
  //     Uri.parse(altTableUrl),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode(altTableBody),
  //   );

  //   if (altTableResponse.statusCode == 200) {
  //     print('Alt_table에 대체텍스트 url 저장 완료');
  //     print('대체텍스트 url 로드하겠습니다');
  //     await _loadPageTexts();
  //     print('대체텍스트 url 로드 완료');
  //   } else {
  //     print('Failed to add alt table entry: ${altTableResponse.statusCode}');
  //     print(altTableResponse.body);
  //   }
  // }

  Future<void> _fetchCreatedAt() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;

    if (userKey != null) {
      var url = Uri.parse(
          '${API.baseUrl}/api/get-file-created-at?folderId=${widget.lectureFolderId}&fileName=${widget.noteName}');
      try {
        var response = await http.get(url);
        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          setState(() {
            _createdAt = jsonResponse['createdAt'];
          });
        } else {
          print('Failed to fetch created_at: ${response.statusCode}');
        }
      } catch (e) {
        print('Error during HTTP request: $e');
      }
    } else {
      print('User ID is null, cannot fetch created_at.');
    }
  }

  String _formatDate(dynamic dateStr) {
    DateTime dateTime = DateTime.parse(dateStr);
    return DateFormat('yyyy/MM/dd hh:mm a').format(dateTime);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _startRecording() async {
    setState(() {
      _recordingState = RecordingState.recording;
      _recognizedText = '';
      _interimText = '';
    });
    await _initStream();
    await _recorder.start();
    setState(() {
      _isListening = true;
    });
  }

  void _stopRecording() async {
    await _recorder.stop();
    setState(() {
      _recordingState = RecordingState.recorded;
      _isListening = false;
      _recognizedText += ' ' + _interimText;

      // 남은 텍스트를 최종적으로 저장
      processParagraphs(_interimText.trim(), isFinal: true);

      _interimText = '';
    });
    await _fetchCreatedAt();
  }

  // Future<void> _saveTranscript() async {
  //   try {
  //     Uint8List fileBytes = Uint8List.fromList(utf8.encode(_recognizedText));

  //     final userProvider = Provider.of<UserProvider>(context, listen: false);
  //     final userKey = userProvider.user?.userKey;
  //     if (userKey != null) {
  //       final storageRef = FirebaseStorage.instance.ref().child(
  //           'record/$userKey/${widget.lectureFolderId}/${widget.lecturefileId}/자막.txt');

  //       UploadTask uploadTask = storageRef.putData(fileBytes,
  //           SettableMetadata(contentType: 'text/plain; charset=utf-8'));

  //       TaskSnapshot taskSnapshot = await uploadTask;
  //       String downloadURL = await taskSnapshot.ref.getDownloadURL();
  //       print('Transcript uploaded: $downloadURL');

  //       await _insertRecordData(widget.lecturefileId, null, downloadURL);
  //     } else {
  //       print('User ID is null, cannot save transcript.');
  //     }
  //   } catch (e) {
  //     print('Error saving transcript: $e');
  //   }
  // }

  Future<void> _insertRecordData(
      int? lecturefileId, int? colonfileId, String downloadURL) async {
    final url = '${API.baseUrl}/api/insertRecordData';
    final body = {
      'lecturefile_id': lecturefileId,
      'colonfile_id': colonfileId,
      'record_url': downloadURL,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Record added successfully');
      } else {
        print('Failed to add record: ${response.statusCode}');
        print(response.body);
      }
    } catch (e) {
      print('Error adding record: $e');
    }
  }

  Future<int> createColonFolder(String folderName, String noteName,
      String fileUrl, String lectureName, int type, int? userKey) async {
    var url = '${API.baseUrl}/api/create-colon';

    var body = {
      'folderName': folderName,
      'noteName': noteName,
      'fileUrl': fileUrl,
      'lectureName': lectureName,
      'type': type,
      'userKey': userKey,
    };

    try {
      print('Sending request to $url with body: $body');

      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print('Folder and file created successfully');
        print('Colon File ID: ${jsonResponse['colonFileId']}');
        return jsonResponse['colonFileId'];
      } else {
        print('Failed to create folder and file: ${response.statusCode}');
        print('Response body: ${response.body}');
        return -1;
      }
    } catch (e) {
      print('Error during HTTP request: $e');
      return -1;
    }
  }

  Future<void> updateLectureFileWithColonId(
      int? lectureFileId, int colonFileId) async {
    var url = '${API.baseUrl}/api/update-lecture-file';

    var body = {
      'lectureFileId': lectureFileId,
      'colonFileId': colonFileId,
    };

    try {
      var response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print('Lecture file updated successfully with colonFileId');
      } else {
        print('Failed to update lecture file: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error during HTTP request: $e');
    }
  }

  Future<void> _updateRecordTableWithColonId(
      int? lecturefileId, int colonfileId) async {
    // lecturefileId가 null이 아닌지 확인
    if (lecturefileId == null) {
      print('Error: lecturefileId is null');
      return; // 업데이트 요청을 진행하지 않음
    }

    final updateUrl = '${API.baseUrl}/api/update-record-table2';
    final updateBody = {
      'lecturefile_id': lecturefileId,
      'colonfile_id': colonfileId,
    };

    try {
      final updateResponse = await http.post(
        Uri.parse(updateUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateBody),
      );

      if (updateResponse.statusCode == 200) {
        print('Record table updated successfully with colon file ID');
      } else {
        print('Failed to update record table: ${updateResponse.statusCode}');
        print('Response body: ${updateResponse.body}');
      }
    } catch (e) {
      print('Error updating record table: $e');
    }
  }

  void _navigateToColonPage(
      BuildContext context,
      String folderName,
      String noteName,
      String lectureName,
      String createdAt,
      String fileUrl,
      int colonFileId,
      int colonFolderId) {
    try {
      print('Navigating to ColonPage'); // 로그 추가
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ColonPage(
              folderName: "$folderName",
              noteName: "$noteName",
              lectureName: lectureName,
              createdAt: createdAt,
              fileUrl: fileUrl,
              colonFileId: colonFileId,
              folderId: colonFolderId,),
        ),
      );
    } catch (e) {
      print('Navigation error: $e');
    }
  }

  // 콜론 생성 다이얼로그 함수
  void showColonCreatedDialog(
      BuildContext context,
      String folderName,
      String noteName,
      String lectureName,
      String fileUrl,
      int? lectureFileId,
      int colonFileId) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final theme = Theme.of(context);

    if (userKey != null) {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Column(
              children: [
                Text(
                  'A colon has been created.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Folder name: $folderName (:)', // 기본폴더 대신 folderName 사용
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.surfaceBright,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Want to move to?',
                  style: theme.textTheme.bodySmall?.copyWith(
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
                    Expanded(
                      // Expanded로 감싸서 오버플로우 방지
                      child: TextButton(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      // Expanded로 감싸서 오버플로우 방지
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(dialogContext).pop();

                          // `ColonPage`로 이동전 콜론 정보 가져오기
                          var colonDetails =
                              await _fetchColonDetails(colonFileId);
                          print("On alternate save ");
                          print(widget.lecturefileId);
                          print(colonFileId);
                          await _insertColonFileIdToAltTable(
                              widget.lecturefileId ?? -1, colonFileId);

                          //ColonFiles에 folder_id로 폴더 이름 가져오기
                          var colonFolderName = await _fetchColonFolderName(
                              colonDetails['folder_id']);

                          // 다이얼로그가 닫힌 후에 네비게이션을 실행
                          Future.delayed(const Duration(milliseconds: 200), () {
                            _navigateToColonPage(
                              context,
                              colonFolderName,
                              colonDetails['file_name'],
                              colonDetails['lecture_name'],
                              colonDetails['created_at'],
                              colonDetails['file_url'],
                              colonFileId,
                              colonDetails['folder_id']
                              
                            );
                          });
                        },
                        child: Text(
                          'Confirm',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondary,
                            fontWeight: FontWeight.bold,
                          ),
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

  Future<void> _insertColonFileIdToAltTable(
      int lecturefileId, int colonFileId) async {
    print('Save colonfile_id to Alt_table2');

    var altTableUrl = '${API.baseUrl}/api/update-alt-table';
    var altTableBody = {
      'lecturefileId': lecturefileId,
      'colonFileId': colonFileId,
    };

    var altTableResponse = await http.post(
      Uri.parse(altTableUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(altTableBody),
    );

    if (altTableResponse.statusCode == 200) {
      print('Finished saving colonfile_id to Alt_table2');
    } else {
      print(
          'Failed to add colonfile_id to alt table: ${altTableResponse.statusCode}');
      print(altTableResponse.body);
    }
  }

  //분리된 강의 스크립트를 sql에서 찾아옴
  Future<List<String>> fetchRecordUrls(int? lectureFileId) async {
    final response = await http.get(Uri.parse(
        '${API.baseUrl}/api/get-upgraderecord-urls?lecturefileId=$lectureFileId'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<String> recordUrls = List<String>.from(jsonResponse['record_urls']);
      return recordUrls;
    } else {
      throw Exception('Failed to load record URLs');
    }
  }

//분리된 대체텍스트를 sql에서 찾아옴
  Future<List<String>> fetchAlternativeTextUrls(int? lectureFileId) async {
    final response = await http.get(Uri.parse(
        '${API.baseUrl}/api/get-alternative-text-urls?lecturefileId=$lectureFileId'));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<String> alternativeTextUrls =
          List<String>.from(jsonResponse['alternative_text_urls']);
      return alternativeTextUrls;
    } else {
      throw Exception('Failed to load alternative text URLs');
    }
  }

// gpt의 답변을 토대로 각 스크립트 조각의 page 값을 sql에 업데이트
  Future<void> updateRecordPage(String recordUrl, int page) async {
    final response = await http.post(
      Uri.parse('${API.baseUrl}/api/update-record-page'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'recordUrl': recordUrl, 'page': page}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update record page');
    }
  }

  // GPT-4 API 호출 함수
  Future<bool> callChatGPT4API(
      String pageText1, String pageText2, String scriptText) async {
    const String apiKey = Env.apiKey;
    final Uri apiUrl = Uri.parse('https://api.openai.com/v1/chat/completions');

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey'
    };

    String prompt = '''
  You are an expert in analyzing lecture scripts. I will provide you with the text of two consecutive lecture material pages and a script segment. 
  Your task is to determine whether the provided script segment belongs to the first or the second page of the lecture material.
  Please follow these instructions:
  1. Do not modify any text in the script segment.
  2. Simply respond with "isNext" if the script belongs to the second page, or "isNotNext" if it belongs to the first page.
  3. Ensure that the response contains only "isNext" or "isNotNext". Your response must be either "isNext" or "isNotNext" only, and no other responses are allowed.
  4. If you are uncertain or it is difficult to determine, you must respond with "isNotNext".
  Page 1 Text: $pageText1
  Page 2 Text: $pageText2
  Script Text: $scriptText
  Which page does this script belong to? 
  ''';

    String body = jsonEncode({
      'model': 'gpt-4o',
      'messages': [
        {
          'role': 'system',
          'content': 'You are an expert in analyzing lecture scripts.'
        },
        {'role': 'user', 'content': prompt}
      ],
      'max_tokens': 50
    });

    final response = await http.post(apiUrl, headers: headers, body: body);
    if (response.statusCode == 200) {
      var decodedResponse = jsonDecode(response.body);
      var gptResponse =
          decodedResponse['choices'][0]['message']['content'].trim();

      if (gptResponse == 'isNext') {
        print('isNext');
        return true;
      } else if (gptResponse == 'isNotNext') {
        print('isNotNext');
        return false;
      } else {
        throw Exception('Unexpected GPT-4 response: $gptResponse');
      }
    } else {
      throw Exception('Failed to call GPT-4 API: ${response.statusCode}');
    }
  }

// GPT-4 API 호출을 통해 스크립트를 페이지별로 분할하는 함수
  Future<Map<String, List<String>>> divideScriptsByPages(List<String> pageTexts,
      List<String> scriptTexts, List<String> scriptUrls) async {
    Map<String, List<String>> result = {};
    int currentPageIndex = 0;

    // 대체 텍스트 .txt 파일은 두 개, 스크립트 .txt 파일은 한 개씩 전달
    for (int scriptIndex = 0; scriptIndex < scriptTexts.length; scriptIndex++) {
      String script = scriptTexts[scriptIndex];
      String scriptUrl = scriptUrls[scriptIndex];

      // 페이지 인덱스가 마지막 페이지를 넘어가지 않도록 수정
      String pageText1 = currentPageIndex < pageTexts.length
          ? pageTexts[currentPageIndex]
          : '';
      String pageText2 = currentPageIndex + 1 < pageTexts.length
          ? pageTexts[currentPageIndex + 1]
          : '';

      if (pageText1.isEmpty) {
        // currentPageIndex가 유효한지 확인
        print(
            'Error: pageText1 is empty. Invalid currentPageIndex: $currentPageIndex');
        break; // or continue, depending on how you want to handle this
      }

      // 마지막 페이지에 도달한 경우 더 이상 페이지 인덱스를 증가시키지 않음
      if (currentPageIndex < pageTexts.length - 1) {
        bool isNextPage = await callChatGPT4API(pageText1, pageText2, script);
        if (isNextPage) {
          currentPageIndex++;
        }
      } else {
        // 마지막 페이지에 대한 처리
        pageText1 = pageTexts[pageTexts.length - 1];
        pageText2 = '';
      }

      result.putIfAbsent("Page $currentPageIndex", () => []).add(script);

      if (scriptUrl.isNotEmpty) {
        // gpt의 답변에 따라 Record_table의 page 값 수정
        await updateRecordPage(scriptUrl, currentPageIndex);
      } else {
        print('Error: scriptUrl is empty for scriptIndex: $scriptIndex');
      }
    }
    // 5초 대기
    await Future.delayed(Duration(seconds: 5));

    return result;
  }

  // 대체텍스트 .txt 리스트 & 스크립트 .txt 리스트 로드해서 함께 divide 함수로 보냄
  Future<void> loadAndProcessLectureData(int? lecturefileId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    // progressNotifier 초기화
  progressNotifier.value = 0.0;

    // 대체텍스트 파일 불러오기
    List<String> pageTexts = [];
    print('Wait for alt text to load');
    List<String> alternativeTextUrls =
        await fetchAlternativeTextUrls(lecturefileId);
    print('Finished loading alt text');

      // 전체 파일 개수
  int totalFiles = alternativeTextUrls.length + (await fetchRecordUrls(lecturefileId)).length;
  double step = 1.0 / totalFiles; // progress 증가 단위 계산

    for (String url in alternativeTextUrls) {
      try {
        String pageText = await http
            .get(Uri.parse(url))
            .then((response) => utf8.decode(response.bodyBytes));
        pageTexts.add(pageText);
         progressNotifier.value += step; // progress 값 증가
    
      } catch (e) {
        print('Error loading alternative text: $e');
      }
    }
    print('Loaded page texts: $pageTexts');

    // 강의 스크립트 파일 불러오기
    List<String> scriptTexts = [];
    List<String> scriptUrls = await fetchRecordUrls(lecturefileId);


    for (String url in scriptUrls) {
      try {
        String scriptText =
            await http.get(Uri.parse(url)).then((response) => response.body);
        scriptTexts.add(scriptText);
       progressNotifier.value += step; // progress 값 증가

      } catch (e) {
        print('Error loading script text: $e');
      }
    }
    // print('Loaded script texts: $scriptTexts');

    // 각 페이지별 스크립트 분할 작업
    Map<String, List<String>> pageScripts =
        await divideScriptsByPages(pageTexts, scriptTexts, scriptUrls);
     progressNotifier.value = 1; // 작업 완료 시 progress 100 설정

    // 결과 출력 (또는 필요한 처리) - TODO
    pageScripts.forEach((page, scripts) {
      print("Page $page:");
      scripts.forEach((script) {
        print(script);
      });
    });
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

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userKey = userProvider.user?.userKey;
    final theme = Theme.of(context);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FolderFilesScreen(
                  folderName: widget.folderName,
                  folderId: widget.lectureFolderId!,
                  folderType: 'lecture',
                ),
              ),
            );
          });
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(toolbarHeight: 0),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (_recordingState == RecordingState.recording) {
                          showConfirmationDialog(
                            context,
                            "Are you sure you want to end the recording?",
                            "Once you end a recording, it cannot be resumed.",
                            () {
                              _stopRecording();
                            },
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FolderFilesScreen(
                                folderName: widget.folderName,
                                folderId: widget.lectureFolderId!,
                                folderType: 'lecture', // 예시 폴더 유형
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        _recordingState == RecordingState.initial ? 'Cancel' : 'Exit',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(
                      Icons.folder_open,
                      color: theme.colorScheme.onSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Folders > ${widget.folderName}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
                const ResponsiveSizedBox(height: 5),
                Text(
                  widget.noteName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const ResponsiveSizedBox(height: 5),
                Text(
                  'Lecture materials: ${widget.lectureName}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSecondary,
                  ),
                ),
                if (_recordingState == RecordingState.recorded &&
                    _createdAt != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ResponsiveSizedBox(height: 5),
                      Text(
                        _formatDate(_createdAt!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ],
                  ),
                const ResponsiveSizedBox(height: 20),
                Row(
                  children: [
                    if (_recordingState == RecordingState.initial)
                      ClickButton(
                        text: 'Record',
                        onPressed: () {
                          _startRecording();
                        },
                        // width: MediaQuery.of(context).size.width * 0.25,
                        // height: 40.0,
                        iconData: Icons.mic,
                      ),
                    if (_recordingState == RecordingState.recording)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClickButton(
                            text: 'End recording',
                            onPressed: () {
                              showConfirmationDialog(
                                context,
                                "Are you sure you want to end the recording?",
                                "Once you end a recording, it cannot be resumed.",
                                () {
                                  _stopRecording();
                                },
                              );
                            },
                            // width: MediaQuery.of(context).size.width * 0.3,
                            // height: 40.0,
                            iconData: Icons.mic,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            children: [
                              const ResponsiveSizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.fiber_manual_record,
                                      color: theme.colorScheme.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Recording',
                                    style: TextStyle(
                                      color: theme.colorScheme.tertiary,
                                      fontSize: 14 * scaleFactor,
                                      fontFamily: 'DM Sans',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        ],
                      ),
                    if (_recordingState == RecordingState.recorded)
                      Row(
                        children: [
                          ClickButton(
                            text: 'Recording ended',
                            onPressed: () {},
                            // width: MediaQuery.of(context).size.width * 0.3,
                            // height: 40.0,
                            iconData: Icons.mic_off,
                            iconColor: Colors.white,
                            backgroundColor: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          ClickButton(
                            text: _isColonCreated ? 'Move colon (:)' : 'Generate a colon (:)',
                            backgroundColor:
                                _isColonCreated ? Colors.grey : null,
                            onPressed: () async {
                              if (_isColonCreated) {
                                //이미 콜론 있는 경우
                                print('existcolon Value: ${_existColon}');

                                if (_existColon != null) {
                                  var colonDetails =
                                      await _fetchColonDetails(_existColon);
                                  var colonFolderName =
                                      await _fetchColonFolderName(
                                          colonDetails['folder_id']);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ColonPage(
                                        folderName: colonFolderName,
                                        noteName: colonDetails['file_name'],
                                        lectureName:
                                            colonDetails['lecture_name'],
                                        createdAt: colonDetails['created_at'],
                                        fileUrl: colonDetails['file_url'],
                                        colonFileId : _existColon,
                                        folderId: colonDetails['folder_id'],
                                      ),
                                    ),
                                  );
                                }
                              } else {
                                print('Create Colon button clicked');
                                var url =
                                    '${API.baseUrl}/api/check-exist-colon?lecturefileId=${widget.lecturefileId}';
                                var response = await http.get(Uri.parse(url));

                                if (response.statusCode == 200) {
                                  var jsonResponse = jsonDecode(response.body);
                                  var existColon = jsonResponse['existColon'];

                                  if (existColon == null) {
                                    print("No colon");

                                    int colonFileId = await createColonFolder(
                                        "${widget.folderName} (:)",
                                        "${widget.noteName} (:)",
                                        widget.fileUrl,
                                        widget.lectureName,
                                        widget.type,
                                        userKey);
                                    if (colonFileId != -1) {
                                      await updateLectureFileWithColonId(
                                          widget.lecturefileId, colonFileId);
                                    
                                        var colonDetails = await _fetchColonDetails(colonFileId);
                                        //var colonFolderName = await _fetchColonFolderName(colonDetails['folder_id']);
                                        List<String> keywords = await fetchKeywords(widget.lecturefileId!);

                                        showColonCreatingDialog(
                                            context,
                                            colonDetails['file_name'],
                                            colonDetails['file_url'],
                                            progressNotifier);

                                      print(keywords);
                                      print(widget.lecturefileId);
                                      
                                      // 자막 업그레이드 시작
                                      if (keywords != null &&
                                          keywords!.isNotEmpty) {
                                        print("Start upgrading subtitles");

                                        await processTranscripts(
                                            widget.lecturefileId!,
                                            keywords!);
                                      } else {
                                        print('Error: Keyword not found');
                                      }
                                      print("Finish upgrading subtitles");

                                      await _updateRecordTableWithColonId(
                                          widget.lecturefileId, colonFileId);

                                      // 자막 업그레이드 끝

                                      // 강의자료 대체텍스트, 스크립트 덩어리들 load
                                      // gpt에게 대체텍스트 & 스크립트 보내서 스크립트를 페이지별로 분할
                                      // 분할한 값 따라 Record_table에 page 값 수정
                                      await loadAndProcessLectureData(
                                          widget.lecturefileId);

                                      // (5)-1 CreatingDialog pop 하기
                                      Navigator.of(context, rootNavigator: true)
                                          .pop();

                                      // (5)-2 CreatedDialog 호출하기
                                      //     이 안에서 생성된 콜론 화면으로 navigate
                                      showColonCreatedDialog(
                                          context,
                                          widget.folderName,
                                          widget.noteName,
                                          widget.lectureName,
                                          widget.fileUrl,
                                          widget.lecturefileId ?? -1,
                                          colonFileId);
                                    } else {
                                      print('Colon file and folder creation failed...');
                                    }
                                  } else {
                                    print(
                                        'An already generated colon exists. Does not run the dialogue to create a colon.');
                                  }
                                } else {
                                  print(
                                      'Failed to check existColon: ${response.statusCode}');
                                  print(response.body);
                                }
                              }
                            },
                            // width: MediaQuery.of(context).size.width * 0.3,
                            // height: 40.0,
                          ),
                        ],
                      ),
                  ],
                ),
                const ResponsiveSizedBox(height: 20),
                if (isAlternativeTextEnabled)
                  GestureDetector(
                    onTap: () {
                      _toggleBlur(_currentPage);
                    },
                    child: Stack(
                      children: [
                        if (_isPDF &&
                            _pdfController != null &&
                            widget.type != 1)
                          Semantics(
                            label: 'PDF page $_currentPage',
                          child :SizedBox(
                            height: 600,
                            child: PdfView(
                              controller: _pdfController!,
                              onPageChanged: (page) {
                                setState(() {
                                  _currentPage = page;
                                  print(
                                      'Current Page: $_currentPage'); // 페이지 전환 시 로그
                                });
                              },
                            ),
                          ),
                          ), 
                        if (!_isPDF && _fileBytes != null)
                        Semantics(
                        label: 'PDF page $_currentPage', // 이미지 파일에 대한 설명 추가
                          child : Image.memory(_fileBytes!),
                        ),
                        if (_blurredPages.contains(_currentPage))
                        Container(
                          width: double.infinity,
                          color: Colors.black.withOpacity(0.5),
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              pageTexts.isNotEmpty
                                  ? pageTexts[_currentPage] ?? 'Missing text on page $_currentPage.'
                                  : 'No text.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const ResponsiveSizedBox(height: 20),
                if (_recordingState == RecordingState.recording)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        _recognizedText + ' ' + _interimText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.w500,
                          height: 1.8,
                        ),
                      ),
                      const ResponsiveSizedBox(height: 20),
                    ],
                  ),
                if (_recordingState == RecordingState.recorded)
                  Column(
                    children: [
                      const ResponsiveSizedBox(height: 10),
                      Text(
                        _recognizedText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onTertiary,
                          fontWeight: FontWeight.w500,
                          height: 1.8,
                        ),
                      ),
                      const ResponsiveSizedBox(height: 20),
                    ],
                  ),
              ],
            ),
          ),
        ),
        bottomNavigationBar:
            buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
      ),
    );

    // return WillPopScope(
    //   onWillPop: () async {
    //     return false; // 뒤로 가기 버튼을 눌렀을 때 아무 반응도 하지 않도록 설정
    //   },

    // );
  }
}
