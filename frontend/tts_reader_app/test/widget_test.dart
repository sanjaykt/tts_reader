import 'package:flutter_test/flutter_test.dart';
import 'package:tts_reader_app/main.dart';

void main() {
  testWidgets('App renders TTS Reader title', (WidgetTester tester) async {
    await tester.pumpWidget(const TtsReaderApp());
    expect(find.text('TTS Reader'), findsOneWidget);
  });
}
