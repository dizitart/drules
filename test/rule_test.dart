import 'package:drules/drules.dart';
import 'package:test/test.dart';

void main() {
  group('Rule test suite', () {
    test('Rule class toJson() method', () {
      var rule = Rule(
        name: 'Test Rule',
        conditions: ConditionDefinition(operator: '==', operands: ['a', 'b']),
        actionInfo: ActionInfo(
          onSuccess: ActionDefinition(
            operation: 'print',
            parameters: ['Success'],
          ),
          onFailure: ActionDefinition(
            operation: 'print',
            parameters: ['Failure'],
          ),
        ),
      );
      var json = rule.toJson();
      expect(json['name'], equals('Test Rule'));
      expect(json['conditions']['operator'], equals('=='));
      expect(json['actionInfo']['onSuccess']['operation'], equals('print'));
      expect(
          json['actionInfo']['onFailure']['parameters'], contains('Failure'));
    });

    test('Rule class fromJson() method', () {
      var json = {
        'id': '123',
        'name': 'Test Rule',
        'priority': 1,
        'enabled': true,
        'conditions': {
          'operator': '==',
          'operands': ['a', 'b'],
        },
        'actionInfo': {
          'onSuccess': {
            'operation': 'print',
            'parameters': ['Success'],
          },
          'onFailure': {
            'operation': 'print',
            'parameters': ['Failure'],
          },
        },
      };
      var rule = Rule.fromJson(json);
      expect(rule.id, equals('123'));
      expect(rule.name, equals('Test Rule'));
      expect(rule.priority, equals(1));
      expect(rule.enabled, isTrue);
      expect(rule.conditions.operator, equals('=='));
      expect(rule.actionInfo.onSuccess?.operation, equals('print'));
      expect(rule.actionInfo.onFailure?.parameters, contains('Failure'));
    });

    test('RuleResult class toString() method', () {
      var actionResult = ActionResult(output: 'Output');
      var ruleResult = RuleResult(
        ruleId: '123',
        isSuccess: true,
        actionResult: actionResult,
      );
      var resultString = ruleResult.toString();
      expect(resultString, contains('123'));
      expect(resultString, contains('true'));
      expect(resultString, contains('Output'));
    });

    test('ActionResult class toString() method with exception', () {
      var exception = Exception('Test Exception');
      var stackTrace = StackTrace.current;
      var actionResult = ActionResult(
        exception: exception,
        stackTrace: stackTrace,
      );
      var resultString = actionResult.toString();
      expect(resultString, contains('Exception: Test Exception'));
      expect(resultString, contains('stackTrace: $stackTrace'));
    });

    test('ActionResult class toString() method without exception', () {
      var childResult = ActionResult(output: 'Child Output');
      var actionResult = ActionResult(
        output: 'Output',
        childResults: [childResult],
      );
      var resultString = actionResult.toString();
      expect(resultString, contains('Output'));
      expect(resultString, contains('Child Output'));
    });
  });
}
