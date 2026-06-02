import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';
import '../services/tts_service.dart';
import '../services/pdf_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _baseUrl = 'http://localhost:8000';

  final _ttsService = TtsService(baseUrl: _baseUrl);
  final _pdfService = PdfService(baseUrl: _baseUrl);
  final _player = AudioPlayer();
  final _textController = TextEditingController();

  bool _loading = false;
  bool _playing = false;
  String _status = '';
  String _selectedVoice = 'alloy';
  bool _usePremium = false;

  static const _premiumVoices = [
    'alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'
  ];

  @override
  void dispose() {
    _player.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;

    setState(() {
      _loading = true;
      _status = 'Extracting text from PDF...';
    });

    try {
      final text = await _pdfService.extractText(
        result.files.single.name,
        result.files.single.bytes!,
      );
      setState(() => _textController.text = text);
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _loading = false;
        _status = '';
      });
    }
  }

  Future<void> _speak() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    if (text.length > 5000) {
      _showError(
          'Text is too long (${text.length} characters). Maximum is 5,000. Try selecting a shorter section.');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Generating audio...';
    });

    try {
      Uint8List bytes;
      if (_usePremium) {
        bytes = await _ttsService.synthesizePremium(text, _selectedVoice);
      } else {
        bytes = await _ttsService.synthesizeFree(text);
      }

      await _player.stop();
      await _player.setAudioSource(
          MyBytesAudioSource(bytes, contentType: 'audio/mpeg'));
      await _player.play();

      setState(() => _playing = true);

      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          setState(() => _playing = false);
        }
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() {
        _loading = false;
        _status = '';
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play();
      setState(() => _playing = true);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Reader'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PDF upload
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF'),
            ),
            const SizedBox(height: 16),

            // Text input
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter text or upload a PDF...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // TTS mode toggle
            Row(
              children: [
                const Text('Free'),
                Switch(
                  value: _usePremium,
                  onChanged: (v) => setState(() => _usePremium = v),
                ),
                const Text('Premium (OpenAI)'),
              ],
            ),

            // Voice selector (premium only)
            if (_usePremium) ...[
              DropdownButtonFormField<String>(
                value: _selectedVoice,
                decoration: const InputDecoration(
                  labelText: 'Voice',
                  border: OutlineInputBorder(),
                ),
                items: _premiumVoices
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVoice = v!),
              ),
              const SizedBox(height: 12),
            ],

            // Status
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_status,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center),
              ),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _speak,
                    icon: _loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.play_arrow),
                    label: const Text('Read Aloud'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _playing ? _togglePlayPause : null,
                  icon: Icon(_playing ? Icons.pause : Icons.play_circle),
                  tooltip: _playing ? 'Pause' : 'Play',
                ),
                IconButton(
                  onPressed: _playing
                      ? () async {
                          await _player.stop();
                          setState(() => _playing = false);
                        }
                      : null,
                  icon: const Icon(Icons.stop),
                  tooltip: 'Stop',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Feeds raw MP3 bytes to just_audio without writing a temp file.
class MyBytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  final String contentType;

  MyBytesAudioSource(this._bytes, {required this.contentType});

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,
      contentLength: end - start,
      offset: start,
      contentType: contentType,
      stream: Stream.value(_bytes.sublist(start, end)),
    );
  }
}
