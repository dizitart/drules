import 'dart:convert';

import 'package:drules/drules.dart';
import 'package:test/test.dart';

void main() {
  group('FileRuleRepository', () {
    test('asserts if both fileNames and directory are empty', () {
      expect(() => FileRuleRepository(fileNames: [], directory: ''),
          throwsA(isA<AssertionError>()));
    });

    test('loadJsonRules yields json rules from files', () async {
      final repository =
          FileRuleRepository(fileNames: ['test/rules/rule_one.json']);
      await expectLater(
          repository.loadJsonRules(),
          emits(isA<String>()
              .having((s) => s, 'json content', contains('Rule One'))));
    });

    test('loadJsonRules yields json rules from directory', () async {
      final repository = FileRuleRepository(directory: 'test/rules');
      await expectLater(
          repository.loadJsonRules(),
          emitsInAnyOrder([
            isA<String>()
                .having((s) => s, 'json content', contains('Rule One')),
            isA<String>()
                .having((s) => s, 'json content', contains('Rule Two')),
            isA<String>().having(
                (s) => s, 'json content', contains('Stop Action Test Rule')),
          ]));
    });

    test('dispose completes without errors', () {
      final repository = FileRuleRepository(fileNames: ['test.json']);
      expect(repository.dispose(), completes);
    });

    test('loadJsonRuleById returns the correct json rule by id', () async {
      final repository =
          FileRuleRepository(fileNames: ['test/rules/rule_one.json']);
      final jsonRule = await repository.loadJsonRuleById('1');
      final ruleMap = jsonDecode(jsonRule!);
      expect(ruleMap['id'], '1');
    });

    test('loadJsonRuleByName yields json rules with matching name', () async {
      final repository = FileRuleRepository(directory: 'test/rules');
      await expectLater(
        repository.loadJsonRuleByName('Rule One'),
        emits(isA<String>()
            .having((s) => s, 'json content', contains('Rule One'))),
      );
    });

    test('dispose completes without errors', () {
      final repository = FileRuleRepository(fileNames: ['test.json']);
      expect(repository.dispose(), completes);
    });
  });
}
