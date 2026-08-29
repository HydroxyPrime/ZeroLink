import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Opens the gallery, compresses on-device via ImagePicker's
  /// imageQuality param, uploads, and returns the download URL.
  Future<String?> pickAndUploadImage({
    required String chatId,
    required ImageSource source,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 70, // compression
      maxWidth: 1600,
    );
    if (picked == null) return null;

    final file = File(picked.path);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
    final ref = _storage.ref().child('chat_images/$chatId/$fileName');

    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }

  Future<String> uploadProfilePhoto(String userId, File file) async {
    final ref = _storage.ref().child('profile_photos/$userId.jpg');
    final uploadTask = await ref.putFile(file);
    return await uploadTask.ref.getDownloadURL();
  }
}
