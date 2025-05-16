import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  static const String folderName = 'Peteks Notes';
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/drive.file',
    'https://www.googleapis.com/auth/drive.appdata',
    'https://www.googleapis.com/auth/drive',
  ];

  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? _auth;
  drive.DriveApi? _driveApi;
  String? _folderId;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: _scopes,
    signInOption: SignInOption.standard,
  );

  Future<bool> signIn() async {
    try {
      // First try to sign in silently
      _currentUser = await _googleSignIn.signInSilently();

      // If silent sign-in fails, show the sign-in dialog
      _currentUser ??= await _googleSignIn.signIn();

      if (_currentUser == null) {
        return false;
      }

      _auth = await _currentUser!.authentication;
      if (_auth?.accessToken == null) {
        return false;
      }

      final client = _GoogleAuthClient(_auth!.accessToken!);
      _driveApi = drive.DriveApi(client);

      // Test the connection by getting the folder
      await getOrCreateNotesFolder();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> signInSilently() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      if (_currentUser == null) return false;
      _auth = await _currentUser!.authentication;
      if (_auth?.accessToken == null) return false;
      final client = _GoogleAuthClient(_auth!.accessToken!);
      _driveApi = drive.DriveApi(client);
      await getOrCreateNotesFolder();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      _auth = null;
      _driveApi = null;
      _folderId = null;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getOrCreateNotesFolder() async {
    try {
      if (_driveApi == null) {
        return null;
      }

      // Search for folder
      final query =
          "mimeType = 'application/vnd.google-apps.folder' and name = '$folderName' and trashed = false";
      final files = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (files.files != null && files.files!.isNotEmpty) {
        _folderId = files.files!.first.id;
        return _folderId;
      }

      // Create folder if not found
      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final created = await _driveApi!.files.create(
        folder,
        $fields: 'id',
      );

      _folderId = created.id;
      return _folderId;
    } catch (e) {
      rethrow;
    }
  }

  // Upload a note as .md file
  Future<void> uploadNoteMd(String fileName, String markdownContent) async {
    try {
      if (_driveApi == null) throw Exception('Not signed in to Google Drive');
      final folderId = await getOrCreateNotesFolder();
      if (folderId == null) throw Exception('Could not get or create folder');

      // Check if file exists (by name)
      final query =
          "name = '$fileName' and '$folderId' in parents and trashed = false";
      final files = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (files.files != null && files.files!.isNotEmpty) {
        // Update existing file
        final fileId = files.files!.first.id;
        await _driveApi!.files.update(
          drive.File(),
          fileId!,
          uploadMedia: drive.Media(
            Stream.value(utf8.encode(markdownContent)),
            utf8.encode(markdownContent).length,
          ),
        );
      } else {
        // Create new file
        final file = drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'text/markdown';

        await _driveApi!.files.create(
          file,
          uploadMedia: drive.Media(
            Stream.value(utf8.encode(markdownContent)),
            utf8.encode(markdownContent).length,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Download all notes as .md files
  Future<List<Map<String, String>>> downloadAllNotesMd() async {
    try {
      if (_driveApi == null) throw Exception('Not signed in to Google Drive');
      final folderId = await getOrCreateNotesFolder();
      if (folderId == null) throw Exception('Could not get or create folder');

      final query =
          "mimeType = 'text/markdown' and '$folderId' in parents and trashed = false";
      final files = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      final List<Map<String, String>> notes = [];
      if (files.files != null) {
        for (final file in files.files!) {
          if (file.id != null && file.name != null) {
            final media = await _driveApi!.files.get(
              file.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            ) as drive.Media;

            final content =
                await media.stream.transform(const Utf8Decoder()).join();
            notes.add({'fileName': file.name!, 'content': content});
          }
        }
      }
      return notes;
    } catch (e) {
      rethrow;
    }
  }

  // Upload an image file
  Future<void> uploadImage(String fileName, List<int> imageBytes) async {
    try {
      if (_driveApi == null) throw Exception('Not signed in to Google Drive');
      final folderId = await getOrCreateNotesFolder();
      if (folderId == null) throw Exception('Could not get or create folder');

      // Check if file exists (by name)
      final query =
          "name = '$fileName' and '$folderId' in parents and trashed = false";
      final files = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name)',
      );

      if (files.files != null && files.files!.isNotEmpty) {
        // Update existing file
        final fileId = files.files!.first.id;
        await _driveApi!.files.update(
          drive.File(),
          fileId!,
          uploadMedia: drive.Media(
            Stream.value(imageBytes),
            imageBytes.length,
          ),
        );
      } else {
        // Create new file
        final file = drive.File()
          ..name = fileName
          ..parents = [folderId]
          ..mimeType = 'image/jpeg';

        await _driveApi!.files.create(
          file,
          uploadMedia: drive.Media(
            Stream.value(imageBytes),
            imageBytes.length,
          ),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  // Download all images
  Future<List<Map<String, dynamic>>> downloadAllImages() async {
    try {
      if (_driveApi == null) throw Exception('Not signed in to Google Drive');
      final folderId = await getOrCreateNotesFolder();
      if (folderId == null) throw Exception('Could not get or create folder');

      final query =
          "mimeType contains 'image/' and '$folderId' in parents and trashed = false";
      final files = await _driveApi!.files.list(
        q: query,
        spaces: 'drive',
        $fields: 'files(id, name, mimeType)',
      );

      final List<Map<String, dynamic>> images = [];
      if (files.files != null) {
        for (final file in files.files!) {
          if (file.id != null && file.name != null) {
            final media = await _driveApi!.files.get(
              file.id!,
              downloadOptions: drive.DownloadOptions.fullMedia,
            ) as drive.Media;

            final bytes = await media.stream.toList();
            final imageBytes = bytes.expand((x) => x).toList();

            images.add({
              'fileName': file.name!,
              'bytes': imageBytes,
              'mimeType': file.mimeType,
            });
          }
        }
      }
      return images;
    } catch (e) {
      rethrow;
    }
  }
}

// Helper class for Google APIs auth
class _GoogleAuthClient extends http.BaseClient {
  final String _accessToken;
  final http.Client _client = http.Client();
  _GoogleAuthClient(this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}
