import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  bool get isConfigured {
    return !AppConfig.cloudinaryCloudName.startsWith('PASTE_') &&
        !AppConfig.cloudinaryUnsignedPreset.startsWith('PASTE_');
  }

  Future<String> pickAndUploadPdf() async {
    if (!isConfigured) {
      throw Exception('Cloudinary is not configured in app_config.dart');
    }

    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No PDF selected');
    }

    final PlatformFile picked = result.files.first;
    return uploadPdf(
      bytes: picked.bytes,
      filePath: picked.path,
      fileName: picked.name,
    );
  }

  Future<String> uploadPdf({
    required String fileName,
    String? filePath,
    List<int>? bytes,
  }) async {
    if (!isConfigured) {
      throw Exception('Cloudinary is not configured in app_config.dart');
    }

    final Uri uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/raw/upload',
    );

    final http.MultipartRequest request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = AppConfig.cloudinaryUnsignedPreset
      ..fields['resource_type'] = 'raw';

    if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );
    } else if (filePath != null && filePath.trim().isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
    } else {
      throw Exception('Could not read selected file');
    }

    final http.StreamedResponse streamedResponse = await request.send();
    final String responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode > 299) {
      throw Exception('Cloudinary upload failed: $responseBody');
    }

    final Map<String, dynamic> json =
        jsonDecode(responseBody) as Map<String, dynamic>;
    final String? url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary did not return secure_url');
    }
    return url;
  }
}
