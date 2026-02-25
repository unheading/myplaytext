import 'package:flutter_test/flutter_test.dart';

import 'package:app/routes/index.dart';

void main() {
  testWidgets('Root widget builds', (WidgetTester tester) async {
    expect(getRootWiget(), isNotNull);
  });
}
