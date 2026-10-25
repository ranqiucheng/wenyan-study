import "package:flutter_test/flutter_test.dart";

import "package:wenyan/data/training_repository.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("加载三类词义训练题库", () async {
    final categories = await TrainingRepository.loadAll();
    expect(categories.length, 3);
    final byId = {for (final c in categories) c.id: c};
    expect(byId["shuoci"]!.items.length, 40);
    expect(byId["yici"]!.items.length, 25);
    expect(byId["gujin"]!.items.length, 30);
    for (final category in categories) {
      for (final item in category.items) {
        expect(item.word.isNotEmpty, isTrue);
        expect(item.example.isNotEmpty, isTrue);
        if (category.id == "shuoci") {
          expect(item.familiar.isNotEmpty && item.contextual.isNotEmpty, isTrue);
        } else if (category.id == "gujin") {
          expect(item.ancient.isNotEmpty && item.modern.isNotEmpty, isTrue);
        } else {
          expect(item.senses.length, greaterThanOrEqualTo(2));
          expect(item.answerIndex, lessThan(item.senses.length));
        }
      }
    }
  });
}
