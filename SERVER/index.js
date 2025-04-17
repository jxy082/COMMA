const express = require('express');
//const mysql = require('mysql');
const mysql = require('mysql2');
const bodyParser = require('body-parser');
const cors = require('cors');
const crypto = require('crypto');
const nodemailer = require('nodemailer');
const mysqlPromise = require('mysql2/promise');

const app = express();
const port = 3000;

app.use(bodyParser.json());
app.use(cors());

const db = mysql.createPool({
    host: 'wem-comma-db.c724coieckpw.ap-northeast-2.rds.amazonaws.com',
    user: 'admin',
    password: 'comma0812!',
    database: 'comma'
});

// Promise 기반 풀
const dbPromise = mysqlPromise.createPool({
    host: 'wem-comma-db.c724coieckpw.ap-northeast-2.rds.amazonaws.com',
    user: 'admin',
    password: 'comma0812!',
    database: 'comma'
});

// 확인용 연결 테스트 (쿼리를 사용하여 연결 확인)
db.getConnection((err, connection) => {
    if (err) {
        console.error('Error connecting to MySQL:', err);
        return;
    }
    console.log('MySQL Connected...');
    connection.release(); // 연결 해제
});


// 기기에 저장된 userKey 해당하는 dis_type과 닉네임 불러오기
app.get('/api/user-details/:userKey', (req, res) => {
    const userKey = req.params.userKey;
    const sql = 'SELECT user_nickname, dis_type FROM user_table WHERE userKey = ?';
    db.query(sql, [userKey], (err, result) => {
        if (err) throw err;
        if (result.length > 0) {
            res.send(result[0]); // 유저 정보를 반환
        } else {
            res.status(404).send('User not found');
        }
    });
});



// 사용자 학습 유형(장애 타입) 업데이트 API => typeselect 페이지에서 최초에 설정 시
app.post('/api/user/:userKey/update-type', (req, res) => {
    const userKey = req.params.userKey;
    const { type } = req.body;

    const sql = 'UPDATE user_table SET dis_type = ? WHERE userKey = ?';

    // 콜백 방식으로 쿼리 실행
    db.query(sql, [type, userKey], (error, result) => {
        if (error) {
            console.error('DB errors:', error.message);
            return res.status(500).json({ success: false, message: `DB errors: ${error.message}` });
        }

        // 업데이트 성공 시
        if (result.affectedRows > 0) {
            return res.status(200).json({ success: true, message: 'Learning types have been updated.' });
        } else {
            return res.status(404).json({ success: false, message: 'User not found.' });
        }
    });
});


// 학습 모드(dis_type) 변경하기 => 마이페이지에서 스위치 당겨서 변경 시

app.put('/api/update_dis_type', (req, res) => {
    const userKey = req.body.userKey;
    const newDisType = req.body.dis_type;

    console.log(`Received request to update dis_type for userKey: ${userKey} to dis_type: ${newDisType}`);

    // 데이터베이스 업데이트 쿼리
    const query = 'UPDATE user_table SET dis_type = ? WHERE userKey = ?';
    db.query(query, [newDisType, userKey], (err, result) => {
        if (err) {
            console.error(`Error updating dis_type for userKey: ${userKey} - ${err.message}`);
            return res.status(500).send({ success: false, error: err.message });
        }

        console.log(`Query Result: `, result);  // 쿼리 결과 로그 추가
        if (result.affectedRows === 0) {
            console.log(`No rows updated for userKey: ${userKey}`);
            return res.status(404).send({ success: false, error: 'User not found' });
        }

        console.log(`dis_type updated successfully for userKey: ${userKey}`);
        res.send({ success: true });
    });
});



// 사용자 ID 기반으로 강의 폴더 목록 가져오기
app.get('/api/lecture-folders/:userKey', (req, res) => {
    const userKey = req.params.userKey;
    const sql = 'SELECT id, folder_name FROM LectureFolders WHERE userKey = ?';
    db.query(sql, [userKey], (err, result) => {
        if (err) throw err;
        res.send(result);
    });
});

// 사용자 ID 기반으로 콜론 폴더 목록 가져오기
app.get('/api/colon-folders/:userKey', (req, res) => {
    const userKey = req.params.userKey;
    const sql = 'SELECT id, folder_name FROM ColonFolders WHERE userKey = ?';
    db.query(sql, [userKey], (err, result) => {
        if (err) throw err;
        res.send(result);
    });
});

// 강의 폴더 추가
app.post('/api/lecture-folders', (req, res) => {
    const { folder_name, userKey } = req.body;
    const sql = 'INSERT INTO LectureFolders (folder_name, userKey) VALUES (?, ?)';
    db.query(sql, [folder_name, userKey], (err, result) => {
        if (err) throw err;
        res.send({ id: result.insertId, folder_name, userKey });
    });
});

// 콜론 폴더 추가
app.post('/api/colon-folders', (req, res) => {
    const { folder_name, userKey } = req.body;
    const sql = 'INSERT INTO ColonFolders (folder_name, userKey) VALUES (?, ?)';
    db.query(sql, [`${folder_name} (:)`, userKey], (err, result) => {
        if (err) throw err;
        res.send({ id: result.insertId, folder_name: `${folder_name} (:)`, userKey });
    });
});

// 폴더 이름 변경하기
app.put('/api/:folderType-folders/:id', (req, res) => {
    const folderType = req.params.folderType;
    const folderId = req.params.id;
    const newName = req.body.folder_name;
    const tableName = folderType === 'lecture' ? 'LectureFolders' : 'ColonFolders';
    const sql = `UPDATE ${tableName} SET folder_name = ? WHERE id = ?`;

    db.query(sql, [newName, folderId], (err, result) => {
        if (err) throw err;
        res.status(200).send({
            id: folderId,
            folder_name: newName,
        });
    });
});

// 폴더 삭제하기
app.delete('/api/:folderType-folders/:id', (req, res) => {
    const folderType = req.params.folderType;
    const id = req.params.id;
    const table = folderType === 'lecture' ? 'LectureFolders' : 'ColonFolders';
    const sql = `DELETE FROM ${table} WHERE id = ?`;
    db.query(sql, [id], (err, result) => {
        if (err) throw err;
        res.status(200).send('Folder deleted');
    });
});

// 강의 폴더 목록 가져오기 (특정 사용자)
app.get('/api/lecture-folders', (req, res) => {
    const userKey = req.query.userKey;
    const sql = `
        SELECT 
            LectureFolders.id, 
            LectureFolders.folder_name, 
            COUNT(LectureFiles.id) AS file_count 
        FROM LectureFolders
        LEFT JOIN LectureFiles 
            ON LectureFolders.id = LectureFiles.folder_id 
        JOIN user_table 
            ON user_table.userKey = LectureFolders.userKey
        WHERE LectureFolders.userKey = ?
            AND LectureFiles.type = user_table.dis_type
        GROUP BY LectureFolders.id;
    `;
    db.query(sql, [userKey], (err, result) => {
        if (err) throw err;
        res.send(result);
    });
});

// 콜론 폴더 목록 가져오기 (특정 사용자)
app.get('/api/colon-folders', (req, res) => {
    const userKey = req.query.userKey;
    const sql = `
        SELECT 
            ColonFolders.id, 
            ColonFolders.folder_name, 
            COUNT(ColonFiles.id) AS file_count 
        FROM ColonFolders
        LEFT JOIN ColonFiles 
            ON ColonFolders.id = ColonFiles.folder_id
        JOIN user_table 
            ON user_table.userKey = ColonFolders.userKey
        WHERE ColonFolders.userKey = ?
            AND ColonFiles.type = user_table.dis_type
        GROUP BY ColonFolders.id;
    `;
    db.query(sql, [userKey], (err, result) => {
        if (err) throw err;
        res.send(result);
    });
});


// 파일 이름 변경하기
app.put('/api/:fileType-files/:id', (req, res) => {
    const fileType = req.params.fileType;
    const fileId = req.params.id;
    const newName = req.body.file_name;
    const tableName = fileType === 'lecture' ? 'LectureFiles' : 'ColonFiles';
    const sql = `UPDATE ${tableName} SET file_name = ? WHERE id = ?`;

    db.query(sql, [newName, fileId], (err, result) => {
        if (err) throw err;
        res.status(200).send({
            id: fileId,
            file_name: newName,
        });
    });
});

// 파일 삭제하기
app.delete('/api/:fileType-files/:id', (req, res) => {
    const fileType = req.params.fileType;
    const id = req.params.id;
    const table = fileType === 'lecture' ? 'LectureFiles' : 'ColonFiles';
    const sql = `DELETE FROM ${table} WHERE id = ?`;
    db.query(sql, [id], (err, result) => {
        if (err) throw err;
        res.status(200).send('File deleted');
    });
});

// 파일 이동하기
app.put('/api/:fileType-files/move/:id', (req, res) => {
    const fileType = req.params.fileType;
    const fileId = req.params.id;
    const newFolderId = req.body.folder_id;
    const tableName = fileType === 'lecture' ? 'LectureFiles' : 'ColonFiles';
    const sql = `UPDATE ${tableName} SET folder_id = ? WHERE id = ?`;

    db.query(sql, [newFolderId, fileId], (err, result) => {
        if (err) throw err;
        res.status(200).send({
            id: fileId,
            folder_id: newFolderId,
        });
    });
});

// **** 특정 사용자의 특정 폴더 속 파일 목록 가져오기 --> type 특정해서 가져오는 걸로 수정
//37번 파일 fetchFiles()
// 특정 폴더의 파일 목록 가져오기 (특정 사용자)
app.get('/api/:fileType-files/:folderId', (req, res) => {
    const folderId = req.params.folderId;
    const fileType = req.params.fileType;
    const userKey = req.query.userKey;
    const disType = req.query.disType;
    const tableName = fileType === 'lecture' ? 'LectureFiles' : 'ColonFiles';
    const joinTable = fileType === 'lecture' ? 'LectureFolders' : 'ColonFolders';
    const sql = `SELECT ${tableName}.* FROM ${tableName} 
                 INNER JOIN ${joinTable} 
                 ON ${tableName}.folder_id = ${joinTable}.id 
                 WHERE ${joinTable}.userKey = ? 
                 AND ${tableName}.folder_id = ? 
                 AND ${tableName}.type = ?`; // dis_type 필터링 추가

    db.query(sql, [userKey, folderId, disType], (err, result) => {
        if (err) {
            console.error('Failed to fetch files:', err);
            return res.status(500).send('Failed to fetch files');
        }
        res.send(result);
    });
});



// 회원가입 (해당 userId로 최초접속 시 회원 등록하면서 userKey 반환)
app.post('/api/signup_info', async (req, res) => {
    try {
        const userId = req.body.user_id;
        const usernickname = req.body.user_nickname;

        console.log('Passed userId:', userId);
        console.log('Created nickname:', usernickname);
        
        if (!userId || !usernickname) {
            return res.status(400).json({ success: false, error: 'User ID and nickname are required.' });
        }

        const sqlQuery = 'INSERT INTO user_table (user_id, user_nickname) VALUES (?, ?);';

        // dbPromise.query에 await을 사용하여 결과를 받아옵니다.
        const [result] = await dbPromise.query(sqlQuery, [userId, usernickname]);
        const userKey = result.insertId; // 삽입된 사용자의 ID를 가져옴
        console.log('Generated userKey:', userKey);

        // Lecture 폴더 생성
        const lectureFolderQuery = 'INSERT INTO LectureFolders (folder_name, userKey) VALUES (?, ?)';
        const [lectureResult] = await dbPromise.query(lectureFolderQuery, ['Default Folder', userKey]);
        const newFolderId = lectureResult.insertId;
        console.log('New Lecture Folder ID:', newFolderId);

        const newLectureFileIds = [];
        const defaultLectureFileIds = [214,290,339,292,291,340]; // 복사할 여러 LectureFile의 ID 배열로 변경
        const defaultColonFileIds = [99,182,237,185,186,238];

        // LectureFile 복사
        for (let i = 0; i < defaultLectureFileIds.length; i++) {
            const defaultLectureFileId = defaultLectureFileIds[i];
            const copyLectureFileQuery = `
                INSERT INTO LectureFiles (folder_id, file_name, file_url, lecture_name, created_at, type, existColon, existLecture)
                SELECT ?, file_name, file_url, lecture_name, NOW(), type, existColon, existLecture
                FROM LectureFiles
                WHERE id = ?`;

            const [lectureFileResult] = await dbPromise.query(copyLectureFileQuery, [newFolderId, defaultLectureFileId]);
            const newLectureFileId = lectureFileResult.insertId;
            newLectureFileIds.push(newLectureFileId);
            console.log('New Lecture File ID:', newLectureFileId);

            // Record_table 복사
            const copyRecordTableQuery = `
                INSERT INTO Record_table (lecturefile_id, colonfile_id, record_url, page)
                SELECT ?, colonfile_id, record_url, page
                FROM Record_table
                WHERE lecturefile_id = ?`;
            await dbPromise.query(copyRecordTableQuery, [newLectureFileId, defaultLectureFileId]);
            console.log('Records from Record_table copied successfully.');

            // Record_table2 복사
            const copyRecordTable2Query = `
                INSERT INTO Record_table2 (lecturefile_id, colonfile_id, record_url, page)
                SELECT ?, colonfile_id, record_url, page
                FROM Record_table2
                WHERE lecturefile_id = ? AND colonfile_id = ?`;
            await dbPromise.query(copyRecordTable2Query, [newLectureFileId, defaultLectureFileId, defaultColonFileIds[i]]);
            console.log('Records from Record_table2 copied successfully.');

            // Alt_table2 복사
            const copyAltTableQuery = `
                INSERT INTO Alt_table2 (lecturefile_id, colonfile_id, alternative_text_url, page)
                SELECT ?, colonfile_id, alternative_text_url, page
                FROM Alt_table2
                WHERE lecturefile_id = ?`;
            await dbPromise.query(copyAltTableQuery, [newLectureFileId, defaultLectureFileId]);
            console.log('Records from Alt_table2 copied successfully.');
        }

        // Colon 폴더 생성
        const colonFolderQuery = 'INSERT INTO ColonFolders (folder_name, userKey) VALUES (?, ?)';
        const [colonResult] = await dbPromise.query(colonFolderQuery, ['Default Folder (:)', userKey]);
        const newColonFolderId = colonResult.insertId;
        console.log('New Colon Folder ID:', newColonFolderId);

        // ColonFile 복사 및 업데이트
        for (let i = 0; i < defaultColonFileIds.length; i++) {
            const defaultColonFileId = defaultColonFileIds[i];
            const newLectureFileId = newLectureFileIds[i];

            const copyColonFileQuery = `
                INSERT INTO ColonFiles (folder_id, file_name, file_url, lecture_name, created_at, type)
                SELECT ?, file_name, file_url, lecture_name, NOW(), type
                FROM ColonFiles
                WHERE id = ?`;
            const [colonFileResult] = await dbPromise.query(copyColonFileQuery, [newColonFolderId, defaultColonFileId]);
            const newColonFileId = colonFileResult.insertId;
            console.log('New Colon File ID:', newColonFileId);

            // Record_table2 업데이트
            const updateRecordTable2Query = `
                UPDATE Record_table2
                SET colonfile_id = ?
                WHERE lecturefile_id = ?`;
            await dbPromise.query(updateRecordTable2Query, [newColonFileId, newLectureFileId]);
            console.log('Updated colonfile_id in Record_table2 successfully.');

            // Alt_table2 업데이트
            const updateAltTable2Query = `
                UPDATE Alt_table2
                SET colonfile_id = ?
                WHERE lecturefile_id = ?`;
            await dbPromise.query(updateAltTable2Query, [newColonFileId, newLectureFileId]);
            console.log('Updated colonfile_id in Alt_table2 successfully.');

            // LectureFiles 테이블의 existColon 업데이트
            const updateLectureFileQuery = `
                UPDATE LectureFiles
                SET existColon = ?
                WHERE id = ?`;
            await dbPromise.query(updateLectureFileQuery, [newColonFileId, newLectureFileId]);
            console.log('Updated LectureFiles table with existcolon successfully.');
        }

        return res.status(200).json({ success: true, userKey: userKey });
    } catch (err) {
        console.error('Error processing signup:', err);
        return res.status(500).json({ success: false, error: err.message });
    }
});



// 회원 탈퇴
app.post('/api/delete_user', async (req, res) => {
    console.log('Receive API requests: /api/delete_user');

    const userKey = req.body.userKey;
    console.log('Received userKey:', userKey);

    if (!userKey) {
        console.log('No userKey provided');
        return res.status(400).json({ success: false, error: "User not found" });
    }

    try {
        // 트랜잭션 시작
        await db.promise().query('START TRANSACTION');

        // 관련 lecturefiles 삭제
        const [lectureFilesResult] = await db.promise().query(
            'DELETE FROM LectureFiles WHERE folder_id IN (SELECT id FROM LectureFolders WHERE userKey = ?)',
            [userKey]
        );
        console.log('Deleted lecturefiles:', lectureFilesResult.affectedRows);

        // 관련 colonfiles 삭제
        const [colonFilesResult] = await db.promise().query(
            'DELETE FROM ColonFiles WHERE folder_id IN (SELECT id FROM ColonFolders WHERE userKey = ?)',
            [userKey]
        );
        console.log('Deleted colonfiles:', colonFilesResult.affectedRows);

        // 관련 lecturefolders 삭제
        const [lectureFoldersResult] = await db.promise().query(
            'DELETE FROM LectureFolders WHERE userKey = ?',
            [userKey]
        );
        console.log('Deleted lecturefolders:', lectureFoldersResult.affectedRows);

        // 관련 colonfolders 삭제
        const [colonFoldersResult] = await db.promise().query(
            'DELETE FROM ColonFolders WHERE userKey = ?',
            [userKey]
        );
        console.log('Deleted colonfolders:', colonFoldersResult.affectedRows);

        // 사용자 삭제
        const [userResult] = await db.promise().query(
            'DELETE FROM user_table WHERE userKey = ?',
            [userKey]
        );
        console.log('Deleted user:', userResult.affectedRows);

        // 트랜잭션 커밋
        await db.promise().query('COMMIT');
        console.log('User and related data deleted successfully.');
        res.json({ success: true });
    } catch (error) {
        // 오류 발생 시 트랜잭션 롤백
        await db.promise().query('ROLLBACK');
        console.error('Transaction error:', error);
        res.status(500).json({ success: false, error: 'Database error' });
    }
});




//회원 닉네임 변경하기
app.put('/api/update_nickname', (req, res) => {
    const userKey = req.body.userKey;
    const newNickname = req.body.user_nickname;

    console.log(`Received request to update nickname for userKey: ${userKey} to newNickname: ${newNickname}`);

    // 데이터베이스 업데이트 쿼리
    const query = 'UPDATE user_table SET user_nickname = ? WHERE userKey = ?';
    db.query(query, [newNickname, userKey], (err, result) => {
        if (err) {
            console.error(`Error updating nickname for userKey: ${userKey} - ${err.message}`);
            return res.status(500).send({ success: false, error: err.message });
        }

        console.log(`Query Result: `, result);  // 쿼리 결과 로그 추가
        if (result.affectedRows === 0) {
            console.log(`No rows updated for userKey: ${userKey}`);
            return res.status(404).send({ success: false, error: 'User not found' });
        }

        console.log(`Nickname updated successfully for userKey: ${userKey}`);
        res.send({ success: true });
    });
});



// 파일 이름 변경하기
app.put('/api/:fileType-files/:id', (req, res) => {
    const fileType = req.params.fileType;
    const fileId = req.params.id;
    const newName = req.body.file_name;
    const tableName = fileType === 'lecture' ? 'LectureFiles' : 'ColonFiles';
    const sql = `UPDATE ${tableName} SET file_name = ? WHERE id = ?`;

    db.query(sql, [newName, fileId], (err, result) => {
        if (err) throw err;
        res.status(200).send({
            id: fileId,
            file_name: newName,
        });
    });
});

//파일 삭제
//colon 파일 삭제 시, 연관 lecturefile의 existcolon 값을 변경
app.delete('/api/:fileType-files/:id', (req, res) => {
    const fileType = req.params.fileType;
    const id = req.params.id;
    
    if (fileType === 'colon') {
        // LectureFiles 테이블에서 existColon 값 NULL로 업데이트
        const updateSql = `UPDATE LectureFiles SET existColon = NULL WHERE existColon = ?`;
        db.query(updateSql, [id], (updateErr, updateResult) => {
            if (updateErr) throw updateErr;

            // ColonFiles 테이블에서 파일 삭제
            const deleteSql = `DELETE FROM ColonFiles WHERE id = ?`;
            db.query(deleteSql, [id], (deleteErr, deleteResult) => {
                if (deleteErr) throw deleteErr;
                res.status(200).send('Colon file deleted and LectureFiles updated');
            });
        });
    } else if (fileType === 'lecture') {
        // Lecture 파일 삭제
        const sql = `DELETE FROM LectureFiles WHERE id = ?`;
        db.query(sql, [id], (err, result) => {
            if (err) throw err;
            res.status(200).send('Lecture file deleted');
        });
    } else {
        res.status(400).send('Invalid file type');
    }
});


// 파일 이동하기
app.put('/api/:fileType-files/move/:id', (req, res) => {
    const fileType = req.params.fileType;
    const fileId = req.params.id;
    const newFolderId = req.body.folder_id;
    const tableName = fileType === 'lecture' ? 'LectureFiles' : 'ColonFiles';
    const sql = `UPDATE ${tableName} SET folder_id = ? WHERE id = ?`;

    db.query(sql, [newFolderId, fileId], (err, result) => {
        if (err) throw err;
        res.status(200).send({
            id: fileId,
            folder_id: newFolderId,
        });
    });
});

// 다른 폴더 목록 가져오기
app.get('/api/getOtherFolders/:fileType/:currentFolderId', (req, res) => {
    const fileType = req.params.fileType;
    const currentFolderId = req.params.currentFolderId;
    const userKey = req.query.userKey; // 쿼리 파라미터로 userKey를 가져옴
    const tableName = fileType === 'lecture' ? 'LectureFolders' : 'ColonFolders';
    const sql = `SELECT id, folder_name FROM ${tableName} WHERE userKey = ?`;

    db.query(sql, [currentFolderId, userKey], (err, result) => {
        if (err) throw err;
        res.send(result);
    });
});

// 파일 검색 API
app.get('/api/searchFiles', (req, res) => {
    const query = req.query.query;
    const sql = `
    SELECT id, folder_id, file_name, file_url, lecture_name, created_at, 'lecture' AS file_type FROM LectureFiles WHERE file_name LIKE ? 
    UNION
    SELECT id, folder_id, file_name, file_url, lecture_name, created_at, 'colon' AS file_type FROM ColonFiles WHERE file_name LIKE ? 
    ORDER BY created_at DESC
`;
    const searchQuery = `%${query}%`;
    db.query(sql, [searchQuery, searchQuery], (err, results) => {
        if (err) {
            res.status(500).send(err);
        } else {
            res.json({ files: results });
        }
    });
});

// 강의 파일 생성 (실시간 자막, 대체텍스트 동일)
// id(PK), folder_id, file_name, file_url, lecture_name, created_at, type, existColon (id) 저장함
// type은 0이면 대체, 1이면 실시간 자막.
// existColon은 처음엔 무조건 NULL로 삽입함
app.post('/api/lecture-files', (req, res) => {
    console.log('POST /api/lecture-files called');
    const { folder_id, file_name, file_url, lecture_name, type } = req.body;

    if (!folder_id || !file_name) {
        return res.status(400).json({ success: false, error: 'You must provide folder_id and file_name.' });
    }

    const sql = 'INSERT INTO LectureFiles (folder_id, file_name, file_url, lecture_name, type) VALUES (?, ?, ?, ?, ?)';
    db.query(sql, [folder_id, file_name, file_url, lecture_name, type], (err, result) => {
        if (err) {
            // print(res.body);
            return res.status(500).json({ success: false, error: err.message });
        }
        res.json({ success: true, id: result.insertId, folder_id, file_name, file_url, lecture_name, type });
    });
});

// Lecture details 업데이트 엔드포인트
app.post('/api/update-lecture-details', (req, res) => {
    const { lecturefileId, file_url, lecture_name, type } = req.body;

    console.log('Received data:', { lecturefileId, file_url, lecture_name, type });

    if (!lecturefileId || !file_url || !lecture_name || type == null) {
        return res.status(400).send({ error: 'Missing required fields' });
    }

    const sql = 'UPDATE LectureFiles SET file_url = ?, lecture_name = ?, type = ? WHERE id = ?';
    db.query(sql, [file_url, lecture_name, type, lecturefileId], (err, results) => {
        if (err) {
            console.error('Database query error:', err);
            return res.status(500).send({ error: 'Database query error' });
        }
        res.send({ success: true, message: 'Lecture details updated successfully' });
    });
});


//대체텍스트 파일 생성 시 responseUrl 저장
app.post('/api/alt-table', (req, res) => {
    console.log('POST /api/alt-table called');
    const { lecturefile_id, colonfile_id, alternative_text_url } = req.body;

    if (!lecturefile_id || !alternative_text_url) {
        return res.status(400).json({ success: false, error: 'You must provide lecturefile_id and alternative_text_url.' });
    }

    const sql = 'INSERT INTO Alt_table (lecturefile_id, colonfile_id, alternative_text_url) VALUES (?, ?, ?)';
    db.query(sql, [lecturefile_id, colonfile_id, alternative_text_url], (err, result) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        res.json({ success: true, lecturefile_id, colonfile_id, alternative_text_url });
    });
});

//콜론파일 폴더 생성 및 파일 생성
//아직 lecturefile에는 삽입전
app.post('/api/create-colon', (req, res) => {
    const { folderName, noteName, fileUrl, lectureName, type, userKey } = req.body;

    console.log('Received request to create colon folder:', { folderName, noteName, fileUrl, lectureName, type, userKey });

    // Check if the folder already exists for the same user
    const checkFolderQuery = 'SELECT id FROM ColonFolders WHERE folder_name = ? AND userKey = ?';
    db.query(checkFolderQuery, [folderName, userKey], (err, results) => {
        if (err) {
            console.error('Failed to check folder existence:', err);
            return res.status(500).json({ error: 'Failed to check folder existence' });
        }

        const insertFileAndReturnId = (folderId) => {
            // Insert file into the folder
            const insertFileQuery = 'INSERT INTO ColonFiles (folder_id, file_name, file_url, lecture_name, created_at, type) VALUES (?, ?, ?, ?, NOW(), ?)';
            db.query(insertFileQuery, [folderId, noteName, fileUrl, lectureName, type], (err, result) => {
                if (err) {
                    console.error('Failed to add file to folder:', err.message);
                    return res.status(500).json({ error: 'Failed to add file to folder' });
                }
                const colonFileId = result.insertId;
                console.log('File added to ColonFiles, file ID:', colonFileId);

                // Return the colonFileId instead of inserting into LectureFiles
                res.status(200).json({ message: 'File added to ColonFiles successfully', colonFileId: colonFileId, folder_id: folderId });
            });
        };

        if (results.length > 0) {
            // Folder exists, use the existing folder id
            const folderId = results[0].id;
            console.log('Folder exists, using existing folder ID:', folderId);
            insertFileAndReturnId(folderId);
        } else {
            // Folder does not exist, create a new folder
            const createFolderQuery = 'INSERT INTO ColonFolders (folder_name, userKey) VALUES (?, ?)';
            db.query(createFolderQuery, [folderName, userKey], (err, result) => {
                if (err) {
                    console.error('Failed to create folder:', err);
                    return res.status(500).json({ error: 'Failed to create folder' });
                }
                const folderId = result.insertId;
                console.log('Folder created successfully, new folder ID:', folderId);
                insertFileAndReturnId(folderId);
            });
        }
    });
});

//existColon에 삽입
app.post('/api/update-lecture-file', (req, res) => {
    const { lectureFileId, colonFileId } = req.body;

    const updateQuery = 'UPDATE LectureFiles SET existColon = ? WHERE id = ?';
    db.query(updateQuery, [colonFileId, lectureFileId], (err, result) => {
        if (err) {
            console.error('Failed to update lecture file:', err);
            return res.status(500).json({ error: 'Failed to update lecture file' });
        }
        res.status(200).json({ message: 'Lecture file updated successfully' });
    });
});

// 특정 lecturefileId에 해당하는 existColon 값 확인 API 엔드포인트
app.get('/api/check-exist-colon', (req, res) => {
    const lecturefileId = req.query.lecturefileId;
    console.log(`Received lecturefileId in existcolon: ${lecturefileId}`);

    if (!lecturefileId || isNaN(parseInt(lecturefileId, 10))) {
        console.log('Invalid lecturefileId');
        return res.status(400).json({ error: 'Invalid lecturefileId' });
    }

    const parsedLecturefileId = parseInt(lecturefileId, 10);

    const query = 'SELECT existColon FROM LectureFiles WHERE id = ?';
    console.log(`Executing query: ${query} with lecturefileId: ${parsedLecturefileId}`);

    db.query(query, [parsedLecturefileId], (err, results) => {
        if (err) {
            console.error('Failed to check existColon:', err);
            return res.status(500).json({ error: 'Failed to check existColon' });
        }

        if (results.length > 0) {
            console.log(`existColon value: ${results[0].existColon}`);
            res.status(200).json({ existColon: results[0].existColon });
        } else {
            console.log('LectureFile not found');
            res.status(404).json({ error: 'LectureFile not found' });
        }
    });
});


//강의파일 created_at 가져오기
app.get('/api/get-file-created-at', (req, res) => {
    const { folderId, fileName } = req.query;

    const query = 'SELECT created_at FROM LectureFiles WHERE folder_id = ? AND file_name = ? LIMIT 1';
    db.query(query, [folderId, fileName], (err, result) => {
        if (err) {
            return res.status(500).json({ error: 'Failed to fetch created_at' });
        }
        if (result.length > 0) {
            res.status(200).json({ createdAt: result[0].created_at });
        } else {
            res.status(404).json({ error: 'File not found' });
        }
    });
});



// 폴더 이름 가져오기 - 강의 폴더 또는 콜론 폴더 구분
app.get('/api/getFolderName/:fileType/:folderId', (req, res) => {
    const { fileType, folderId } = req.params;
    let table = fileType === 'lecture' ? 'LectureFolders' : 'ColonFolders';

    const sql = `SELECT folder_name FROM ${table} WHERE id = ?`;
    db.query(sql, [folderId], (err, result) => {
        if (err) {
            console.error('Error fetching folder name:', err);
            res.status(500).send({ error: 'Internal Server Error' });
            return;
        }
        if (result.length > 0) {
            res.json({ folder_name: result[0].folder_name });
        } else {
            res.status(404).send({ error: 'Folder not found' });
        }
    });

});

// 강의파일 아이디 가져오기
app.get('/api/getFileId', (req, res) => {
    const fileUrl = req.query.file_url;
    const sql = 'SELECT id FROM LectureFiles WHERE file_url = ?';

    db.query(sql, [fileUrl], (err, results) => {
        if (err) {
            res.status(500).send(err);
        } else {
            if (results.length > 0) {
                res.json({ id: results[0].id });
            } else {
                res.status(404).send({ message: 'File not found' });
            }
        }
    });
});



// **** 현재 로그인한 userKey뿐 아니라, dis_type까지 고려해서 파일 가져와야 함 ///

// 사용자별 최신 강의 파일을 가져오는 API 엔드포인트
app.get('/api/getLectureFiles/:userKey', (req, res) => {
    const userKey = req.params.userKey;
    const disType = req.query.disType; // dis_type 추가
    const sql = `
        SELECT LectureFiles.* FROM LectureFiles
        INNER JOIN LectureFolders ON LectureFiles.folder_id = LectureFolders.id
        WHERE LectureFolders.userKey = ? AND LectureFiles.type = ?  
        ORDER BY LectureFiles.created_at DESC
    `;

    db.query(sql, [userKey, disType], (err, results) => {
        if (err) {
            res.status(500).send(err);
        } else {
            res.json({ files: results });
        }
    });
});


// **** 현재 로그인한 userKey뿐 아니라, dis_type까지 고려해서 파일 가져와야 함 ///

// 사용자별 최신 콜론 파일을 가져오는 API 엔드포인트
app.get('/api/getColonFiles/:userKey', (req, res) => {
    const userKey = req.params.userKey;
    const disType = req.query.disType; // dis_type 추가
    const sql = `
    SELECT ColonFiles.* FROM ColonFiles
    INNER JOIN ColonFolders ON ColonFiles.folder_id = ColonFolders.id
    WHERE ColonFolders.userKey = ? AND ColonFiles.type = ? 
    ORDER BY ColonFiles.created_at DESC`;
    
    db.query(sql, [userKey, disType], (err, results) => {
        if (err) {
            res.status(500).send(err);
        } else {
            res.json({ files: results });
        }
    });
});



// 강의 폴더 이름 가져오기
app.get('/api/get-folder-name', (req, res) => {
    const { folderId } = req.query;

    const sql = 'SELECT folder_name FROM LectureFolders WHERE id = ?';
    db.query(sql, [folderId], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        if (results.length > 0) {
            res.status(200).json({ folder_name: results[0].folder_name });
        } else {
            res.status(404).json({ success: false, error: 'Folder not found' });
        }
    });
});


// //대체 텍스트 URL 가져오기
// app.get('/api/get-alternative-text-url', (req, res) => {
//     const { lecturefileId } = req.query;
//     console.log(`Received lecturefileId: ${lecturefileId}`);

//     const sql = `
//         SELECT alternative_text_url
//         FROM Alt_table2
//         WHERE lecturefile_id = ?
//     `;

//     db.query(sql, [lecturefileId], (err, results) => {
//         if (err) {
//             return res.status(500).json({ success: false, error: err.message });
//         }

//         console.log(`Query results: ${JSON.stringify(results)}`);

//         if (results.length > 0) {
//             res.status(200).json({ alternative_text_url: results[0].alternative_text_url });
//         } else {
//             res.status(404).json({ success: false, message: 'No matching record found' });
//         }
//     });
// });

// 분리된 대체텍스트 URL을 가져오기
app.get('/api/get-alternative-text-urls', (req, res) => {
    const { lecturefileId } = req.query;
    console.log(`Received lecturefileId: ${lecturefileId}`);

    const sql = `
        SELECT alternative_text_url
        FROM Alt_table2
        WHERE lecturefile_id = ?
    `;

    db.query(sql, [lecturefileId], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        const alternativeTextUrls = results.map(record => record.alternative_text_url);
        // console.log('Returning alternative text URLs:', alternativeTextUrls);
        res.status(200).json({ alternative_text_urls: alternativeTextUrls });
    });
});

// 강의 파일 스크립트 URL을 가져오기
app.get('/api/get-record-urls', (req, res) => {
    const { lecturefileId } = req.query;
    console.log(`Received lecturefileId: ${lecturefileId}`);

    const sql = `
        SELECT record_url
        FROM Record_table
        WHERE lecturefile_id = ?
    `;

    db.query(sql, [lecturefileId], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        const recordUrls = results.map(record => record.record_url);
        res.status(200).json({ record_urls: recordUrls });
    });
});



// 분리된 강의 스크립트 URL을 가져오기
app.get('/api/get-upgraderecord-urls', (req, res) => {
    const { lecturefileId } = req.query;
    console.log(`Received lecturefileId: ${lecturefileId}`);

    const sql = `
        SELECT record_url
        FROM Record_table2
        WHERE lecturefile_id = ?
    `;

    db.query(sql, [lecturefileId], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        const recordUrls = results.map(record => record.record_url);
        res.status(200).json({ record_urls: recordUrls });
    });
});

// 분리된 강의 스크립트의 page 값 업데이트해주기
app.post('/api/update-record-page', (req, res) => {
    const { recordUrl, page } = req.body;
    console.log(`Updating record URL: ${recordUrl} with page: ${page}`);

    const sql = `
        UPDATE Record_table2
        SET page = ?
        WHERE record_url = ?
    `;

    db.query(sql, [page, recordUrl], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        console.log(`Updated record URL: ${recordUrl} with page: ${page}`);
        res.status(200).json({ success: true, message: 'Record updated successfully' });
    });
});

//해당 콜론파일 정보 가져오기
app.get('/api/get-colon-details', (req, res) => {
    const colonId = req.query.colonId;
    console.log(`Received colonId: ${colonId}`);

    if (!colonId || isNaN(parseInt(colonId, 10))) {
        console.log('Invalid colonId');
        return res.status(400).json({ error: 'Invalid colonId' });
    }
    const parsedColonId = parseInt(colonId, 10);

    const query = 'SELECT folder_id, file_name, file_url, lecture_name, created_at, type FROM ColonFiles WHERE id = ?';
    console.log(`Executing query: ${query} with colonId: ${parsedColonId}`);

    db.query(query, [parsedColonId], (err, results) => {
        if (err) {
            console.error('Failed to get colon details:', err);
            return res.status(500).json({ error: 'Failed to get colon details' });
        }

        if (results.length > 0) {
            console.log(`Colon details: ${JSON.stringify(results[0])}`);
            res.status(200).json(results[0]);
        } else {
            console.log('Colonfile not found');
            res.status(404).json({ error: 'Colonfile not found' });
        }
    });
});

// 콜론 폴더 이름 가져오기
app.get('/api/get-Colonfolder-name', (req, res) => {
    const { folderId } = req.query;
    const sql = 'SELECT folder_name FROM ColonFolders WHERE id = ?';
    db.query(sql, [folderId], (err, results) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        if (results.length > 0) {
            res.status(200).json({ folder_name: results[0].folder_name });
        } else {
            res.status(404).json({ success: false, error: 'Folder not found' });
        }
    });
});

// 녹음종료 후 자막 스크립트 부분 데베에 저장
app.post('/api/insertRecordData', (req, res) => {
    const { lecturefile_id, colonfile_id, record_url } = req.body;

    if (!lecturefile_id || !record_url) {
        return res.status(400).json({ success: false, error: 'You must provide lecturefile_id and record_url.' });
    }

    const sql = 'INSERT INTO Record_table (lecturefile_id, colonfile_id, record_url) VALUES (?, ?, ?)';
    db.query(sql, [lecturefile_id, colonfile_id, record_url], (err, result) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        res.json({ success: true, id: result.insertId, lecturefile_id, colonfile_id, record_url });
    });
});

// 자막 업그레이드 시작

// 강의 파일의 전사 URL 가져오기 API
app.get('/api/get-transcript-urls', (req, res) => {
    const lecturefileId = req.query.lecturefile_id;
  
    if (!lecturefileId) {
      return res.status(400).json({ message: 'lecturefile_id is required' });
    }
  
    const query = `
      SELECT record_url 
      FROM Record_table 
      WHERE lecturefile_id = ? 
    `;
  
    db.query(query, [lecturefileId], (err, results) => {
      if (err) {
        console.error('Error fetching transcript URLs:', err);
        return res.status(500).json({ message: 'Server error' });
      }
  
      if (results.length === 0) {
        return res.status(404).json({ message: 'No transcript URLs found' });
      }
  
      const urls = results.map(row => ({ url: row.record_url }));
      res.status(200).json(urls); // 전사 URL 리스트를 반환
    });
  });

// 자막 업그레이드 후 데베에 저장
app.post('/api/insertUpgradeRecordData', (req, res) => {
    const { lecturefile_id, colonfile_id, record_url } = req.body;

    if (!lecturefile_id || !record_url) {
        return res.status(400).json({ success: false, error: 'You must provide lecturefile_id and record_url.' });
    }

    const sql = 'INSERT INTO Record_table2 (lecturefile_id, colonfile_id, record_url) VALUES (?, ?, ?)';
    db.query(sql, [lecturefile_id, colonfile_id, record_url], (err, result) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        res.json({ success: true, id: result.insertId, lecturefile_id, colonfile_id, record_url });
    });
});


// 콜론 생성 후 Record_table2 업데이트
app.post('/api/update-record-table2', (req, res) => {
    const { lecturefile_id, colonfile_id } = req.body;
    const sql = 'UPDATE Record_table2 SET colonfile_id = ? WHERE lecturefile_id = ?';
    console.log(`lecturefile_id: ${lecturefile_id}, colonfile_id: ${colonfile_id}`);

    db.query(sql, [colonfile_id, lecturefile_id], (err, result) => {
        if (err) {
            console.error('Error updating record table:', err);
            res.status(500).json({ error: 'Failed to update record table' });
        } else {
            res.status(200).json({ success: true });
        }
    });
});


// Record_Table2에서 page, record_url(페이지 스크립트) 가져오기
app.get('/api/get-page-scripts', (req, res) => {
    const colonfile_id = req.query.colonfile_id;
    const sql = 'SELECT page, record_url FROM Record_table2 WHERE colonfile_id = ?';

    db.query(sql, [colonfile_id], (err, results) => {
        if (err) {
            console.error('Page script import failed:', err);
            res.status(500).send('Page script import failed');
        } else {
            console.log("Page script import successful")
            res.send(results);
        }
    });
});

// 자막 업그레이드 끝

// 특정 lecturefile_id 행에 colonfile_id 업데이트하기
app.post('/api/update-alt-table', (req, res) => {
    const { lecturefileId, colonFileId } = req.body;

    console.log('Received data:', { lecturefileId, colonFileId }); // 로그 추가

    if (!lecturefileId || !colonFileId) {
        console.log('Missing required fields'); // 로그 추가
        return res.status(400).send({ error: 'Missing required fields' });
    }

    const sql = 'UPDATE Alt_table2 SET colonfile_id = ? WHERE lecturefile_id = ?';
    db.query(sql, [colonFileId, lecturefileId], (err, results) => {
        if (err) {
            console.error('Database query error:', err); // 로그 추가
            res.status(500).send('Internal server error');
        } else {
            if (results.affectedRows > 0) {
                console.log('Update successful'); // 로그 추가
                res.status(200).send('Update successful');
            } else {
                console.log('Lecturefile not found'); // 로그 추가
                res.status(404).send('Lecturefile not found');
            }
        }
    });
});

// Alt_table2의 특정 colonfile_id 행에서 여러 URL 가져오기
app.get('/api/get-alt-url/:colonfile_id', (req, res) => {
    const colonfile_id = req.params.colonfile_id;
    console.log(`Received request for colonfile_id: ${colonfile_id}`); // 로그 추가

    const sql = 'SELECT alternative_text_url FROM Alt_table2 WHERE colonfile_id = ?';

    db.query(sql, [colonfile_id], (err, results) => {
        if (err) {
            console.error('Failed to fetch alternative text URLs:', err);
            return res.status(500).send('Failed to fetch alternative text URLs');
        }

        console.log('Query results:', results); // 로그 추가

        if (results.length > 0) {
            const alternativeTextUrls = results.map(record => record.alternative_text_url);
            console.log('Returning alternative text URLs:', alternativeTextUrls); // 로그 추가
            res.status(200).json({ alternative_text_urls: alternativeTextUrls });
        } else {
            console.log('No URLs found for the given colonfile_id'); // 로그 추가
            res.status(404).send('No URLs found for the given colonfile_id');
        }
    });
});


//쪼개 대체 삽입
app.post('/api/alt-table2', (req, res) => {
    console.log('POST /api/alt-table2 called');
    const { lecturefile_id, alternative_text_url, page } = req.body;

    if (!lecturefile_id || !alternative_text_url || page === undefined) {
        return res.status(400).json({ success: false, error: 'You must provide lecturefile_id, url, and page.' });
    }

    const sql = 'INSERT INTO Alt_table2 (lecturefile_id, alternative_text_url, page) VALUES (?, ?, ?)';
    db.query(sql, [lecturefile_id, alternative_text_url, page], (err, result) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        res.json({ success: true, lecturefile_id, alternative_text_url, page });
    });
});

// 사용자 학습 유형(장애 타입) 업데이트 API
app.post('/api/user/:userKey/update-type', (req, res) => {
    console.log('1');
    const userKey = req.params.userKey;
    const { type } = req.body;
    console.log(userKey);
    const sql = 'UPDATE user_table SET dis_type = ? WHERE userKey = ?';

    // 콜백 방식으로 쿼리 실행
    db.query(sql, [type, userKey], (error, result) => {
        if (error) {
            console.error('DB errors:', error.message);
            return res.status(500).json({ success: false, message: `DB errors: ${error.message}` });
        }

        // 업데이트 성공 시
        if (result.affectedRows > 0) {
            return res.status(200).json({ success: true, message: 'Learning types have been updated.' });
        } else {
            return res.status(404).json({ success: false, message: 'User not found.' });
        }
    });
});

// existLecture 값을 무조건 1로 업데이트
app.post('/api/update-existLecture', (req, res) => {
    const { lecturefileId } = req.body;

    // lectureFileId가 제대로 전달되었는지 확인
    console.log('Received lecturefileId:', lecturefileId);

    if (!lecturefileId) {
        console.error('lectureFileId is missing');
        return res.status(400).json({ error: 'lectureFileId is required' });
    }

    const updateQuery = 'UPDATE LectureFiles SET existLecture = 1 WHERE id = ?';

    // 쿼리 실행 전에 로그 출력
    console.log('Executing query:', updateQuery, 'with lecturefileId:', lecturefileId);

    db.query(updateQuery, [lecturefileId], (err, result) => {
        if (err) {
            console.error('Failed to update existLecture:', err);
            return res.status(500).json({ error: 'Failed to update existLecture' });
        }

        // 결과 로그 출력
        console.log('Update result:', result);

        if (result.affectedRows === 0) {
            console.log('No rows were updated, check if lectureFileId exists in the database.');
            return res.status(404).json({ error: 'No lecture found with the provided lectureFileId' });
        }

        res.status(200).json({ message: 'existLecture updated to 1 successfully' });
    });
});



// API 엔드포인트: lecturefileId로 existLecture 값을 확인
app.get('/api/checkExistLecture/:lectureFileId', (req, res) => {
    const lectureFileId = req.params.lectureFileId;
    const query = 'SELECT existLecture FROM LectureFiles WHERE id = ?';
    db.query(query, [lectureFileId], (err, result) => {
        if (err) {
            console.error('Error checking existLecture:', err);
            return res.status(500).json({ error: 'Failed to check existLecture' });
        }

        if (result.length > 0) {
            // lecturefileId에 대한 existLecture 값을 반환
            res.status(200).json({ existLecture: result[0].existLecture });
        } else {
            // 해당 lecturefileId가 없는 경우
            res.status(404).json({ error: 'Lecture file not found' });
        }
    });
});

// 키워드 데이터 삽입 API
app.post('/api/insert-keywords', (req, res) => {
    const { lecturefileId, keywordsFileUrl } = req.body;

    // lecturefile_id 또는 keywords_url이 없을 경우 오류 반환
    if (!lecturefileId || !keywordsFileUrl) {
        return res.status(400).json({ success: false, error: 'You must provide lecturefileId and keywordsFileUrl.' });
    }

    // SQL 쿼리 작성 및 실행
    const sql = 'INSERT INTO Keywords_table (lecturefile_id, keywords_url) VALUES (?, ?)';
    db.query(sql, [lecturefileId, keywordsFileUrl], (err, result) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }
        // 성공 시 삽입된 id와 함께 응답
        res.json({ success: true, id: result.insertId, lecturefileId, keywordsFileUrl });
    });
});

// Keywords_table에서 lecturefile_id로 키워드 조회하는 API
app.get('/api/getKeywords/:lecturefile_id', (req, res) => {
    const { lecturefile_id } = req.params;

    if (!lecturefile_id) {
        return res.status(400).json({ success: false, error: 'You must provide lecturefile_id.' });
    }

    const sql = 'SELECT keywords_url FROM Keywords_table WHERE lecturefile_id = ?';
    db.query(sql, [lecturefile_id], (err, result) => {
        if (err) {
            return res.status(500).json({ success: false, error: err.message });
        }

        if (result.length === 0) {
            return res.status(404).json({ success: false, error: 'No keywords found for the given lecturefile_id.' });
        }

        const keywordsUrl = result[0].keywords_url;
        res.json({ success: true, keywordsUrl });
    });
});

app.listen(port, () => {
    console.log(`Server started on port ${port}`);
});