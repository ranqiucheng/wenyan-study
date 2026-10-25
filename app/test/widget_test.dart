import "package:flutter_test/flutter_test.dart";

import "package:wenyan/main.dart";

void main() {
  testWidgets("app builds", (tester) async {
    await tester.pumpWidget(const WenyanApp());
    expect(find.text("文言研习"), findsOneWidget);
  });
}
