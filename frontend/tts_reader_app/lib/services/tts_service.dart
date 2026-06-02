// tts_service.dart — handles all communication with the TTS backend endpoints.
// Keeping network logic in a separate service class means the UI code (HomeScreen)
// stays clean and focused on layout, not HTTP details.

import 'dart:convert';      // provides jsonEncode for safely serialising Dart objects to JSON
import 'dart:typed_data';   // provides Uint8List, a typed list of bytes (used for raw audio data)
import 'package:http/http.dart' as http; // the HTTP client package; `as http` avoids name clashes

class TtsService {
  // baseUrl is injected at construction time so this class stays testable and
  // reusable — you can point it at localhost in dev and a real server in prod.
  final String baseUrl;

  TtsService({required this.baseUrl});

  // Public methods are thin wrappers that choose the right endpoint.
  // They hide the implementation detail (path, voice handling) from callers.
  Future<Uint8List> synthesizeFree(String text) async {
    return _synthesize('/tts/stream/free', text, null);
  }

  Future<Uint8List> synthesizePremium(String text, String voice) async {
    return _synthesize('/tts/stream/premium', text, voice);
  }

  // Private method (leading underscore in Dart = private to this file).
  // `async` means this function is non-blocking — Flutter can render frames
  // while waiting for the HTTP response.
  // `Future<Uint8List>` is the return type: a promise that will eventually
  // resolve to a list of bytes (the MP3 audio data).
  Future<Uint8List> _synthesize(
      String path, String text, String? voice) async {
    // Build the request body as a Dart Map, then encode it to a JSON string.
    // jsonEncode handles escaping special characters (quotes, newlines, etc.)
    // which is why we never build JSON strings manually with string interpolation.
    final body = <String, dynamic>{'text': text};
    if (voice != null) body['voice'] = voice; // only include voice for premium

    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: {'Content-Type': 'application/json'}, // tells the server what format to expect
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('TTS request failed: ${response.statusCode}');
    }

    // response.bodyBytes is the raw MP3 audio as a Uint8List.
    // We return bytes (not a file path) because on web there is no file system —
    // the audio lives in memory and gets fed directly to the audio player.
    return response.bodyBytes;
  }
}
