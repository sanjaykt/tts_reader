import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class TtsService {
  final String baseUrl;

  TtsService({required this.baseUrl});

  Future<Uint8List> synthesizeFree(String text) async {
    return _synthesize('/tts/stream/free', text, null);
  }

  Future<Uint8List> synthesizePremium(String text, String voice) async {
    return _synthesize('/tts/stream/premium', text, voice);
  }

  Future<Uint8List> _synthesize(
      String path, String text, String? voice) async {
    final body = <String, dynamic>{'text': text};
    if (voice != null) body['voice'] = voice;

    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('TTS request failed: ${response.statusCode}');
    }

    return response.bodyBytes;
  }
}
