import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PdfService {
  final String baseUrl;

  PdfService({required this.baseUrl});

  Future<String> extractText(String fileName, Uint8List fileBytes) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/tts/pdf'));

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: MediaType('application', 'pdf'),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('PDF extraction failed: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['text'] as String;
  }
}
