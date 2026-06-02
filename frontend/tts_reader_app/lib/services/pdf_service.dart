// pdf_service.dart — uploads a PDF file to the backend and returns the extracted text.
// Multipart form upload is used because we're sending a binary file, not JSON.

import 'dart:convert';      // for jsonDecode — safely parses the JSON response
import 'dart:typed_data';   // for Uint8List — raw file bytes from the file picker
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for MediaType — describes the file's MIME type

class PdfService {
  final String baseUrl;

  PdfService({required this.baseUrl});

  // `fileName` is the original file name (e.g. "report.pdf").
  // `fileBytes` is the file's raw content as bytes — on web the file picker
  // gives us bytes directly because there is no accessible file path in the browser.
  Future<String> extractText(String fileName, Uint8List fileBytes) async {
    // MultipartRequest is how you send files over HTTP (like an HTML form with enctype="multipart/form-data").
    // The backend's FastAPI endpoint reads the file from the "file" field name.
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/tts/pdf'));

    // MultipartFile.fromBytes attaches the file bytes to the request.
    // contentType tells the server this is a PDF, not an image or plain text.
    request.files.add(http.MultipartFile.fromBytes(
      'file',          // must match the parameter name in the FastAPI endpoint
      fileBytes,
      filename: fileName,
      contentType: MediaType('application', 'pdf'),
    ));

    // Multipart requests are sent as a stream, so we first get a StreamedResponse,
    // then convert it to a regular Response to read the body as a string.
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode != 200) {
      throw Exception('PDF extraction failed: ${response.statusCode}');
    }

    // jsonDecode properly parses the JSON string into a Dart Map, handling all
    // escape sequences (like \n for newlines) correctly.
    // Casting to Map<String, dynamic> tells Dart the shape of the decoded object.
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['text'] as String;
  }
}
