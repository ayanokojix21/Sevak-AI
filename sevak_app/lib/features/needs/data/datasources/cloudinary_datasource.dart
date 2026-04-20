import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:sevak_app/core/config/env_config.dart';

class CloudinaryDatasource {
  Future<String> uploadImage(List<int> imageBytes, String filename) async {
    final cloudName = EnvConfig.cloudinaryCloudName;
    final apiKey = EnvConfig.cloudinaryApiKey;
    final apiSecret = EnvConfig.cloudinaryApiSecret;

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // Create signature: sha1("timestamp=$timestamp$apiSecret")
    final signaturePayload = "timestamp=$timestamp$apiSecret";
    final signature = sha1.convert(utf8.encode(signaturePayload)).toString();

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);

    request.fields['api_key'] = apiKey;
    request.fields['timestamp'] = timestamp;
    request.fields['signature'] = signature;
    
    // Add file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ),
    );

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseBody);
      return jsonResponse['secure_url'] as String;
    } else {
      throw Exception('Failed to upload image to Cloudinary: ${response.statusCode} - $responseBody');
    }
  }
}
