import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_sqlite_demo/main.dart';

void main() {
  testWidgets('Aplikasi catatan berhasil ditampilkan', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NotesApp());

    expect(find.text('Catatanku'), findsOneWidget);
  });
}
