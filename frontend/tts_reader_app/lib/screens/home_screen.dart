// home_screen.dart — the main (and only) screen of the app.
// It handles PDF uploading, text input, TTS mode selection, and audio playback.

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';   // cross-platform file picker (mobile + web)
import 'package:just_audio/just_audio.dart';      // audio playback engine
import '../config/constants.dart';
import '../services/tts_service.dart';
import '../services/pdf_service.dart';

// StatefulWidget is used here because this screen manages state that changes
// over time: loading spinners, playing status, selected voice, etc.
// In Flutter, widgets are split into two classes:
//   - HomeScreen (the configuration, immutable)
//   - _HomeScreenState (the mutable state, rebuilt when setState() is called)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Service classes are created once and reused — they hold no mutable state
  // themselves, so there's no need to recreate them on every rebuild.
  // The base URL comes from AppConstants so it only needs to change in one place.
  final _ttsService = TtsService(baseUrl: AppConstants.baseUrl);
  final _pdfService = PdfService(baseUrl: AppConstants.baseUrl);

  // AudioPlayer manages the audio session. It must be disposed when the
  // widget is removed from the tree to release system audio resources.
  final _player = AudioPlayer();

  // TextEditingController connects the TextField widget to our code.
  // We use it to read and set the text field's content programmatically.
  final _textController = TextEditingController();

  // State variables — each call to setState() triggers a rebuild of build().
  bool _loading = false;      // true while waiting for network requests
  bool _playing = false;      // true while audio is actively playing
  String _status = '';        // status message shown below the text field
  String _selectedVoice = 'alloy'; // default OpenAI voice
  bool _usePremium = false;   // toggles between free (gTTS) and premium (OpenAI)

  // The available voices from OpenAI's TTS API.
  static const _premiumVoices = [
    'alloy', 'echo', 'fable', 'onyx', 'nova', 'shimmer'
  ];

  // dispose() is called when this widget is permanently removed from the screen.
  // Always dispose controllers and players here to prevent memory leaks.
  @override
  void dispose() {
    _player.dispose();
    _textController.dispose();
    super.dispose(); // always call super.dispose() last
  }

  // Opens the platform file picker filtered to PDFs only.
  // `withData: true` tells the picker to load the file bytes into memory —
  // this is required on web where file paths don't exist.
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    // User cancelled the picker or the file had no readable bytes — do nothing.
    if (result == null || result.files.single.bytes == null) return;

    // setState() tells Flutter "something changed, please redraw".
    // Only the widgets that depend on the changed values are redrawn.
    setState(() {
      _loading = true;
      _status = 'Extracting text from PDF...';
    });

    try {
      final text = await _pdfService.extractText(
        result.files.single.name,
        result.files.single.bytes!,  // ! asserts non-null (we checked above)
      );
      // Update the text field with the extracted content.
      setState(() => _textController.text = text);
    } catch (e) {
      _showError(e.toString());
    } finally {
      // `finally` always runs — clears the loading state whether or not the
      // request succeeded. This prevents the spinner from getting stuck.
      setState(() {
        _loading = false;
        _status = '';
      });
    }
  }

  // Sends the text to the backend for TTS synthesis and plays the returned audio.
  Future<void> _speak() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Guard against sending too much text to the backend — the server enforces
    // the same limit but checking here gives immediate feedback without a round-trip.
    if (text.length > AppConstants.maxTtsChars) {
      _showError(
          'Text is too long (${text.length} characters). Maximum is ${AppConstants.maxTtsChars}. Try selecting a shorter section.');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Generating audio...';
    });

    try {
      // Choose the TTS engine based on the toggle.
      // Both methods return raw MP3 bytes (Uint8List).
      Uint8List bytes;
      if (_usePremium) {
        bytes = await _ttsService.synthesizePremium(text, _selectedVoice);
      } else {
        bytes = await _ttsService.synthesizeFree(text);
      }

      // Stop any audio that's currently playing before loading new audio.
      await _player.stop();

      // MyBytesAudioSource is a custom class (defined below) that feeds
      // in-memory bytes to just_audio. This avoids writing a temp file to disk,
      // which is important for web compatibility.
      await _player.setAudioSource(
          MyBytesAudioSource(bytes, contentType: 'audio/mpeg'));
      await _player.play();

      setState(() => _playing = true);

      // Listen to the player's state stream to detect when playback finishes.
      // Streams in Dart are like event listeners — they emit values over time.
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

  // Pauses if playing, resumes if paused.
  Future<void> _togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
      setState(() => _playing = false);
    } else {
      await _player.play();
      setState(() => _playing = true);
    }
  }

  // Shows a brief error message at the bottom of the screen using a SnackBar.
  // ScaffoldMessenger is the standard Flutter way to show snackbars from anywhere
  // in the widget tree without needing a direct reference to the Scaffold.
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // build() is called every time setState() is called.
  // It returns the entire widget tree for this screen — Flutter efficiently
  // diffs this against the previous tree and only updates what changed.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar is the top bar with a title.
      appBar: AppBar(
        title: const Text('TTS Reader'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        // Column arranges its children vertically, one after another.
        // crossAxisAlignment.stretch makes each child fill the full width.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // --- PDF Upload Button ---
            // onPressed: null disables the button while loading (shows greyed out state).
            OutlinedButton.icon(
              onPressed: _loading ? null : _pickPdf,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload PDF'),
            ),
            const SizedBox(height: 16), // SizedBox is the standard Flutter spacer

            // --- Text Input ---
            // Expanded makes the TextField grow to fill all available vertical space,
            // pushing the controls below it to the bottom of the screen.
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,   // null = unlimited lines
                expands: true,    // fills the Expanded parent's height
                textAlignVertical: TextAlignVertical.top, // text starts at the top, not the centre
                decoration: const InputDecoration(
                  hintText: 'Enter text or upload a PDF...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Free / Premium Toggle ---
            // Row arranges children horizontally.
            Row(
              children: [
                const Text('Free'),
                Switch(
                  value: _usePremium,
                  // onChanged is called with the new value whenever the switch is tapped.
                  onChanged: (v) => setState(() => _usePremium = v),
                ),
                const Text('Premium (OpenAI)'),
              ],
            ),

            // --- Voice Selector (only shown in premium mode) ---
            // The `if` inside a list with spread `...[]` is a Flutter pattern
            // for conditionally including widgets without breaking the list syntax.
            if (_usePremium) ...[
              DropdownButtonFormField<String>(
                value: _selectedVoice,
                decoration: const InputDecoration(
                  labelText: 'Voice',
                  border: OutlineInputBorder(),
                ),
                // .map() transforms the list of voice strings into DropdownMenuItems.
                // .toList() is needed because map() returns a lazy Iterable, not a List.
                items: _premiumVoices
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedVoice = v!),
              ),
              const SizedBox(height: 12),
            ],

            // --- Status Message ---
            // Only shown when _status is non-empty (e.g. "Generating audio...").
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_status,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center),
              ),

            // --- Playback Controls ---
            Row(
              children: [
                // Expanded makes the Read Aloud button fill the remaining width
                // after the icon buttons take their space.
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _speak,
                    // Ternary operator switches the icon between a spinner and a play arrow.
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

                // Pause/resume — only enabled while audio is playing.
                IconButton(
                  onPressed: _playing ? _togglePlayPause : null,
                  icon: Icon(_playing ? Icons.pause : Icons.play_circle),
                  tooltip: _playing ? 'Pause' : 'Play',
                ),

                // Stop — resets playback position.
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

// --- Custom Audio Source ---
// just_audio can play audio from a URL, a file, or a custom source.
// Since the backend returns raw MP3 bytes (not a URL), we need this custom
// StreamAudioSource to feed those bytes directly to the audio engine.
// This approach works on both mobile and web — no temp files needed.
class MyBytesAudioSource extends StreamAudioSource {
  final Uint8List _bytes;
  final String contentType; // e.g. 'audio/mpeg' for MP3

  MyBytesAudioSource(this._bytes, {required this.contentType});

  // request() is called by just_audio when it needs audio data.
  // `start` and `end` allow seeking — the player can request a specific byte range.
  // This is how audio scrubbing (jumping to a position) works under the hood.
  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;               // ??= means "assign only if currently null"
    end ??= _bytes.length;
    return StreamAudioResponse(
      sourceLength: _bytes.length,       // total size of the audio
      contentLength: end - start,        // size of this particular chunk
      offset: start,                     // where in the file this chunk starts
      contentType: contentType,
      stream: Stream.value(_bytes.sublist(start, end)), // emit the bytes as a one-shot stream
    );
  }
}
