import 'package:drules/src/actions.dart';
import 'package:drules/src/conditions.dart';
import 'package:drules/src/repository.dart';
import 'package:test/test.dart';

void main() {
  group('ActionRepository Tests', () {
    test('Find registered action', () {
      var repository = ActionRepository();
      var action = repository.findAction('stop');
      expect(action, isA<Stop>());
    });

    test('Find unregistered action', () {
      var repository = ActionRepository();
      var action = repository.findAction('unknown');
      expect(action, isNull);
    });
  });

  group('ConditionRepository Tests', () {
    test('Find registered condition', () {
      var repository = ConditionRepository();
      var condition = repository.findCondition('all');
      expect(condition, isA<All>());
    });

    test('Find unregistered condition', () {
      var repository = ConditionRepository();
      var condition = repository.findCondition('Unknown');
      expect(condition, isNull);
    });
  });
}
