import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Image storage backed by Cloudinary unsigned uploads.
///
/// The API shape matches the original Firebase Storage implementation so that
/// callers (community provider, trip creation, profile edit) don't need to
/// change. Only the upload path is different: files now go to Cloudinary and
/// the returned `secure_url` is what gets persisted in Firestore.
class StorageService {
  static const _cloudName = 'dpmraxyev';
  static const _uploadPreset = 'SURAKSA';

  /// Uploads [file] to Cloudinary. [path] is interpreted as a logical storage
  /// path (e.g. `users/{uid}/avatar.jpg`, `posts/{postId}/image_0.jpg`) and is
  /// converted into a Cloudinary folder so the dashboard stays organized.
  /// Returns the Cloudinary `secure_url`.
  Future<String> uploadImage(File file, String path) async {
    if (!await file.exists()) {
      throw Exception('File does not exist: ${file.path}');
    }

    // Use the directory portion of [path] as the Cloudinary folder.
    // e.g. "posts/abc123/image_0.jpg" -> folder "sura/posts/abc123".
    final lastSlash = path.lastIndexOf('/');
    final dir = lastSlash >= 0 ? path.substring(0, lastSlash) : '';
    final folder = dir.isEmpty ? 'sura' : 'sura/$dir';

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception(
        'Cloudinary upload failed (${response.statusCode}): ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null) {
      throw Exception('Cloudinary response missing secure_url: ${response.body}');
    }
    return url;
  }

  /// Deletion of unsigned uploads requires an authenticated Admin API call
  /// (Cloudinary API secret). That can't safely run from the client, so this
  /// is a no-op — orphaned assets can be cleaned up from the Cloudinary
  /// dashboard if needed. The signature is kept so callers don't break.
  Future<void> deleteImage(String url) async {}

  Future<List<String>> uploadPostImages(List<File> files, String postId) async {
    final urls = <String>[];
    for (int i = 0; i < files.length; i++) {
      final path = 'posts/$postId/image_$i.jpg';
      final url = await uploadImage(files[i], path);
      urls.add(url);
    }
    return urls;
  }

  Future<void> deletePostImages(List<String> urls) async {}
}
