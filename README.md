## Modification
<br>
- Fixed an issue with the main page -> Recent Lessons file looking strange in light mode<br>
- Fixed Folder Page -> Failed to fetch when selecting a folder.<br>
<br>
- Accessibility settings -> Add light/dark mode settings<br>
- Adjust font size -> Modify radio button to fit light/dark mode<br><br>



## Changes to entering a classroom

### Screen flow

- **Click Enter Classroom O**
  - Folder → File → `RecordPage`
  - Home → File → `RecordPage`
  - Home → View all → File → `RecordPage`

- **Click Enter Classroom X**
  - Folder → File → `LectureStartPage`
  - Home → File → `LectureStartPage`
  - Home → View all → File → `LectureStartPage`

### Code flow

#### 1. **60prepare.dart**
   - `callChatGPT4APIForKeywords()`: Added the ability to upload keyword extractions to Firebase
   - `insertKeywordsIntoDB()`: Save keyword firebase upload URL to DB
   - **Firebase file structure**: `Keywords/userKey/folderId/fileId/~~_.keywords.txt`
   - **DB table structure**:

     ```sql
     CREATE TABLE `Keywords_table` (
       `id` int NOT NULL AUTO_INCREMENT,
       `lecturefile_id` int DEFAULT NULL,
       `keywords_url` varchar(2048) DEFAULT NULL,
       PRIMARY KEY (`id`),
       KEY `fk4_lecturefile` (`lecturefile_id`),
       CONSTRAINT `fk4_lecturefile` FOREIGN KEY (`lecturefile_id`) REFERENCES `LectureFiles` (`id`) ON DELETE CASCADE
     );
     ```

#### 2. **62lecture_start.dart**
   - **강의실 입장하기 버튼 클릭**: `LectureFiles` 테이블의 `existLecture` 값을 1로 업데이트

#### 3. **37_folder_files_screen**, **16_homepage_move**, **17_allFilesPage**
   - `fetchFolderAndNavigate()`: `existLecture` 값이 1이면 `LectureStartPage`로 이동
   - `fetchKeywords()`: `LectureStartPage`로 이동할 때 DB에서 키워드를 불러오는 함수

#### 4. **index.js**
   - `existLecture` 값을 1로 업데이트하는 기능
   - `lecturefileId`로 `existLecture` 값을 확인하는 기능
   - 키워드 데이터를 DB에 삽입
   - `Keywords_table`에서 `lecturefile_id`로 키워드를 조회하는 API

---

## 10_typeselect 디자인 수정



# 수정 및 변경 사항
*- dis_type : 0(시각장애인용, 대체텍스트 생성) / 1(청각장애인용, 실시간자막 생성)*<br>
*- GPT API KEY는 최신 키로 바꿔서 사용하세요*<br>
*- api/api.dart 는 서버 업데이트 되면 바꿔서 사용, 현재는 로컬*<br>


<br><br>

## 사용자 타입 관련 수정
**/lib**<br>
- main.dart : 코드 밑에 있던 SplashScreen 삭제
- 1_SplashScreen : 유저 아이디 유무에 따라 main/onboarding 페이지로 이동하는 코드 수정
- 10_typeselect(추가) :<br>
    대체텍스트 선택 --> db, provider, sharedpreferences 에 0 추가<br>
    실시간자막 선택 --> db, provider, sharedpreferences 에 1 추가<br>
- 60prepare : 대체텍스트/실시간생성 버튼 삭제, 사용자 타입에 따라 제목 변경, 사용자 타입에 따라 이후 화면 갈림
<br>

**/lib/model**<br>
- user : dis_type 추가
- user_provider : dis_type, 관련 메서드 추가
<br>

**흐름**
1. 로고화면에서 유저키 확인<br>
2-1. 없는 경우 온보딩 화면으로 --> 온보딩화면에서 '바로 시작하기' 버튼 누르면 유저 생성 --> 타입 선택 화면 --> 메인 화면<br>
2-2. 있는 경우 메인 화면으로
<br>


**SERVER**
- index.js : 사용자 학습 유형(장애 타입) 업데이트 코드 추가
<br>
<br>

