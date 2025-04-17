import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_plugin/folder/37_folder_files_screen.dart';
import 'package:flutter_plugin/mypage/44_font_size_page.dart';
import 'package:get/get_state_manager/src/simple/get_responsive.dart';
import 'package:intl/intl.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import '60prepare.dart';
import '63record.dart';
import 'components.dart';
import 'api/api.dart';
import 'dart:typed_data';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:charset_converter/charset_converter.dart';

class ColonPage extends StatefulWidget {
  final String folderName;
  final String noteName;
  final String lectureName;
  final dynamic createdAt;
  final String? fileUrl;
  final int? colonFileId;
  final int? folderId;

  const ColonPage(
      {Key? key,
      required this.folderName,
      required this.noteName,
      required this.lectureName,
      required this.createdAt,
      this.fileUrl,
      this.colonFileId,
      this.folderId})
      : super(key: key);

  @override
  _ColonPageState createState() => _ColonPageState();
}

class _ColonPageState extends State<ColonPage> {
  bool isLoading = true;
  List<PdfPageImage> pages = [];
  Uint8List? imageData;
  int _selectedIndex = 2;
  Map<int, List<String>> pageScripts = {}; // 페이지별 텍스트를 저장할 Map
  Map<int, String> pageTexts = {}; // 페이지별 대체 텍스트를 저장할 Map
  final Set<int> _blurredPages = {}; // 블러 처리된 페이지를 추적하는 Set
  late int colonFileId;
  int type = -1; // colonDetails에서 type을 가져와 저장할 변수
  //Texts가 붙으면 대체텍스트
  //Scripts가 붙으면 자막

  @override
  void initState() {
    super.initState();
    if (widget.colonFileId != null) {
      colonFileId = widget.colonFileId!;
      _loadFile();
      _loadPageScripts();
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        await loadPageTexts(
            colonFileId: widget.colonFileId); // widget.lectureFileId로 수정
      });
      // _loadAltTableUrl(); // Alt_table URL 로드
      _fetchColonType(); // 콜론 타입 로드
    } else {
      setState(() {
        isLoading = false;
      });
      print('Error: colonFileId is null.');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

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

  Future<void> _fetchColonType() async {
    try {
      Map<String, dynamic> colonDetails = await _fetchColonDetails(colonFileId);
      setState(() {
        type = colonDetails['type'];
      });
    } catch (e) {
      print('Error fetching colon details: $e');
    }
  }

  Future<Map<int, List<String>>> fetchPageScripts(int? colonFileId) async {
    final apiUrl =
        '${API.baseUrl}/api/get-page-scripts?colonfile_id=$colonFileId';

    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse =
          jsonDecode(utf8.decode(response.bodyBytes));
      Map<int, List<String>> pageScripts = {};
      for (var script in jsonResponse) {
        int page = script['page'];
        String url = script['record_url'];
        if (!pageScripts.containsKey(page)) {
          pageScripts[page] = [];
        }
        pageScripts[page]?.add(url);
      }
      return pageScripts;
    } else {
      throw Exception('Failed to load page scripts');
    }
  }

  Future<void> _loadPageScripts() async {
    try {
      pageScripts = await fetchPageScripts(widget.colonFileId);
      print('Loaded page scripts: $pageScripts'); // 로드된 스크립트 출력
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Failed to load page scripts: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadFile() async {
    if (widget.fileUrl != null) {
      final response = await http.get(Uri.parse(widget.fileUrl!));
      if (response.statusCode == 200) {
        if (widget.lectureName.endsWith('.pdf')) {
          final document = await PdfDocument.openData(response.bodyBytes);
          for (int i = 1; i <= document.pagesCount; i++) {
            final page = await document.getPage(i);
            final pageImage = await page.render(
              width: page.width,
              height: page.height,
              format: PdfPageImageFormat.jpeg,
            );
            pages.add(pageImage!);
            await page.close();
          }
        } else if (widget.lectureName.endsWith('.png') ||
            widget.lectureName.endsWith('.jpg') ||
            widget.lectureName.endsWith('.jpeg')) {
          imageData = response.bodyBytes;
        }
        setState(() {
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load file');
      }
    }
  }

  String _formatDate(dynamic createdAt) {
    DateTime dateTime = DateTime.parse(createdAt);
    return DateFormat('yyyy/MM/dd hh:mm a').format(dateTime);
  }

  Future<Map<String, dynamic>> _fetchColonDetails(int colonId) async {
    var url = '${API.baseUrl}/api/get-colon-details?colonId=$colonId';
    var response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      return jsonResponse;
    } else {
      throw Exception('Failed to load colon details');
    }
  }

  void _toggleBlur(int page) {
    setState(() {
      if (_blurredPages.contains(page)) {
        _blurredPages.remove(page);
      } else {
        _blurredPages.add(page);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print(colonFileId);
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
                  folderId: widget.folderId!,
                  folderType: 'colon',
                ),
              ),
            );
          });
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  if (widget.colonFileId != null) {
                                    print(
                                        'colonFileId: ${widget.colonFileId}'); // colonFileId 로그 출력
                                  } else {
                                    print('Error: colonFileId is null.');
                                  }
                           
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => FolderFilesScreen(
                                        folderName: widget
                                            .folderName, // 현재 콜론 파일의 폴더 이름
                                        folderId:
                                            widget.folderId!, // 현재 콜론 파일의 폴더 ID
                                        folderType:
                                            'colon', // 폴더 타입은 'colon'으로 지정
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Exit',
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
                                'Folders > ${widget.folderName}', // 폴더 이름 사용
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          ),
                          const ResponsiveSizedBox(height: 5),
                          Text(
                            widget.noteName, // 노트 이름 사용
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.onSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const ResponsiveSizedBox(height: 5),
                          Text(
                            'Lecture materials : ${widget.lectureName}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondary,
                            ),
                          ),
                          const ResponsiveSizedBox(
                              height: 5), // 추가된 날짜와 시간을 위한 공간
                          Text(
                            _formatDate(
                                widget.createdAt), // 데이터베이스에서 가져온 생성 날짜 및 시간 사용
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSecondary,
                            ),
                          ),
                          const SizedBox(height: 10), // 강의 자료 밑에 여유 공간 추가
                          // 콜론(:) 다운하기 버튼 없애 놓음
                          // Row(
                          //   children: [
                          //     ClickButton(
                          //       text: '콜론(:) 다운하기',
                          //       onPressed: () {},
                          //       // height: 40.0,
                          //     ),
                          //   ],
                          // ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  
                    if (widget.lectureName.endsWith('.pdf') &&
                        widget.fileUrl != null)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: pages.length * 2,
                        itemBuilder: (context, index) {
                          if (index.isEven) {
                            final pageIndex = index ~/ 2;
                            final pageImage = pages[pageIndex];
                            return GestureDetector(
                              onTap: () {
                                if (type == 0) {
                                  _toggleBlur(pageIndex + 1);
                                }
                              },
                              child: Semantics(
                                label: 'PDF page ${pageIndex + 1}', // PDF 페이지에 대한 설명 추가
                              child: Stack(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: MediaQuery.sizeOf(context).height -
                                        200, // 화면 높이에 맞춤
                                    child: Image.memory(
                                      pageImage.bytes,
                                      // 수정
                                      //fit: BoxFit.cover, // 이미지를 전체 화면에 맞춤
                                    ),
                                  ),
                                  // Widget build의 부분 수정
                                if (_blurredPages.contains(pageIndex + 1) && type == 0)
                                  Container(
                                    width: double.infinity,
                                    constraints: BoxConstraints(
                                      minHeight: MediaQuery.sizeOf(context).height - 200,
                                    ), // 높이를 화면에 맞춰 조정
                                    color: Colors.black.withOpacity(0.5),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Text(
                                      pageTexts[pageIndex + 1] ?? 'No text.',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ),
                            );
                          } else {
                            final pageIndex = index ~/ 2;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: FutureBuilder<List<String>>(
                                future: _fetchPageTexts(pageIndex),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    final pageTexts = snapshot.data ?? [];
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: pageTexts.map((text) {
                                        return Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              20, 10, 20, 10),
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                                color: theme
                                                    .colorScheme.onSecondary,
                                                fontSize: 17,
                                                fontWeight: FontWeight.w500,
                                                height: 1.8,
                                                fontFamily:
                                                    GoogleFonts.ibmPlexSansKr()
                                                        .fontFamily),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  }
                                },
                              ),
                            );
                          }
                        },
                      ),
                    if ((widget.lectureName.endsWith('.png') ||
                            widget.lectureName.endsWith('.jpg') ||
                            widget.lectureName.endsWith('.jpeg')) &&
                        imageData != null)
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (type == 0) {
                                _toggleBlur(1);
                              }
                            },
                            child: Stack(
                              children: [
                                Image.memory(
                                  imageData!,
                                  fit: BoxFit.cover, // 이미지를 전체 화면에 맞춤
                                  width: double.infinity,
                                ),
                                if (_blurredPages.contains(1) && type == 0)
                                  Container(
                                    width: double.infinity,
                                    height: MediaQuery.sizeOf(context).height -
                                        200, // 화면 높이에 맞춤
                                    color: Colors.black.withOpacity(0.5),
                                    child: Center(
                                      child: Text(
                                        pageTexts[1] ?? 'No text in the image.',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: FutureBuilder<List<String>>(
                              future: _fetchPageTexts(0), // 이미지 파일은 1 페이지로 간주
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  final pageTexts = snapshot.data ?? [];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: pageTexts.map((text) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8.0),
                                        child: Text(
                                          text,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            color:
                                                theme.colorScheme.onSecondary,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                  ],
                
                ),
              ),
        bottomNavigationBar:
            buildBottomNavigationBar(context, _selectedIndex, _onItemTapped),
      ),
    );
  }

//대체 텍스트
  Future<List<String>> _fetchPageTexts(int pageIndex) async {
    if (pageScripts.containsKey(pageIndex)) {
      final urls = pageScripts[pageIndex]!;
      List<String> texts = [];
      for (var url in urls) {
        //print('Fetching text from URL: $url'); // URL 출력
        try {
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            try {
              // UTF-8로 시도
              final text = utf8.decode(response.bodyBytes);
              //print('Loaded text for page $pageIndex: $text'); // 로드된 텍스트 출력
              texts.add(text);
            } catch (e) {
              //print('Error decoding text as UTF-8 for page $pageIndex: $e');
              try {
                // EUC-KR로 수동으로 디코딩
                final eucKrBytes = response.bodyBytes;
                final text = eucKrBytes
                    .map((e) => e & 0xFF)
                    .map((e) => e.toRadixString(16))
                    .join(' ');
                print(
                    'Loaded text with manual EUC-KR decoding for page $pageIndex: $text');
                texts.add(text);
              } catch (e) {
                print(
                    'Error decoding text with manual EUC-KR decoding for page $pageIndex: $e');
                texts.add('Error decoding page text');
              }
            }
          } else {
            print('Failed to load page text: ${response.statusCode}');
            texts.add('Failed to load page text');
          }
        } catch (e) {
          print('Error loading page text: $e');
          texts.add('Error loading page text');
        }
      }
      return texts;
    } else {
      return ['No text on page ${pageIndex + 1}.'];
    }
  }
}
