import 'package:drules/drules.dart';
import 'package:test/test.dart';

void main() {
  group('StringRuleRepository', () {
    test('asserts if rule list is empty', () {
      expect(() => StringRuleRepository([]), throwsA(isA<AssertionError>()));
    });

    test('loadJsonRules yields json rules from strings', () async {
      final repository = StringRuleRepository([
        '{"rule": "Rule One"}',
        '{"rule": "Rule Two"}',
      ]);
      await expectLater(
          repository.loadJsonRules(),
          emitsInOrder([
            isA<String>()
                .having((s) => s, 'json content', contains('Rule One')),
            isA<String>()
                .having((s) => s, 'json content', contains('Rule Two')),
            emitsDone,
          ]));
    });

    test('dispose completes without errors', () {
      final repository = StringRuleRepository(['{"rule": "Test Rule"}']);
      expect(repository.dispose(), completes);
    });

    test('loadJsonRuleById returns the correct rule', () async {
      final repository = StringRuleRepository([
        '{"id": "1", "name": "Rule One"}',
        '{"id": "2", "name": "Rule Two"}',
      ]);

      final rule = await repository.loadJsonRuleById('1');

      expect(rule, '{"id": "1", "name": "Rule One"}');
    });

    test('loadJsonRuleById returns null if rule is not found', () async {
      final repository = StringRuleRepository([
        '{"id": "1", "name": "Rule One"}',
        '{"id": "2", "name": "Rule Two"}',
      ]);

      final rule = await repository.loadJsonRuleById('3');

      expect(rule, isNull);
    });

    test('loadJsonRuleByName returns rules with matching name', () async {
      final repository = StringRuleRepository([
        '{"id": "1", "name": "Rule One"}',
        '{"id": "2", "name": "Rule Two"}',
        '{"id": "3", "name": "Another Rule"}',
      ]);

      final rules = repository.loadJsonRuleByName('Rule');

      await expectLater(
        rules,
        emitsInOrder([
          '{"id": "1", "name": "Rule One"}',
          '{"id": "2", "name": "Rule Two"}',
        ]),
      );
    });

    test('dispose completes without errors', () {
      final repository =
          StringRuleRepository(['{"id": "1", "name": "Test Rule"}']);

      expect(repository.dispose(), completes);
    });
  });
}
