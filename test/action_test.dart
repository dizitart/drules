import 'package:drules/drules.dart';
import 'package:drules/src/actions.dart';
import 'package:drules/src/repository.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:test/test.dart';

void main() {
  group('Action Test Suite', () {
    test('DummyAction implements Action interface', () async {
      var dummyAction = DummyAction();
      expect(dummyAction, isA<Action>());

      var result = await dummyAction.execute([], RuleContext());
      // Check if the execute method works as expected
      expect(result.output, equals("Dummy output"));
      expect(result.exception, isNull);
    });

    test('Test CustomAction', () async {
      var action = CustomAction('custom', (parameters, context) async {
        return 'Custom Action executed';
      });

      var result = await action.execute([], RuleContext());
      expect(result.output, equals('Custom Action executed'));
      expect(result.exception, isNull);
    });

    test('Test Stop Action', () async {
      var action = Stop();

      var result = await action.execute([], RuleContext());
      expect(result.output, isNull);
      expect(result.exception, isNull);
      expect(result.shouldContinue, isFalse);
    });

    test('Test Print Action', () async {
      var action = Print();

      var result = await action.execute(['Hello, World!'], RuleContext());
      expect(result.output, equals('Hello, World!'));
      expect(result.exception, isNull);
    });

    test('Test Chain Action', () async {
      var action1 = CustomAction('action1', (parameters, context) async {
        return 'Action 1 executed';
      });

      var action2 = CustomAction('action2', (parameters, context) async {
        return 'Action 2 executed';
      });

      var chainAction = Chain();
      ActionRepository().registerAction(action1);
      ActionRepository().registerAction(action2);

      var result = await chainAction.execute(
        [
          {'operation': 'action1', 'parameters': []},
          {'operation': 'action2', 'parameters': []},
        ],
        RuleContext(),
      );

      expect(result.output, equals('Action 2 executed'));
      expect(result.exception, isNull);
      expect(result.shouldContinue, isTrue);
      expect(result.childResults, hasLength(2));
      expect(result.childResults[0].output, equals('Action 1 executed'));
      expect(result.childResults[1].output, equals('Action 2 executed'));
    });

    test('Test Pipe Action', () async {
      var action1 = CustomAction('action1', (parameters, context) async {
        return 'Action 1 executed';
      });

      var action2 = CustomAction('action2', (parameters, context) async {
        return 'Action 2 executed';
      });

      var pipeAction = Pipe();
      ActionRepository().registerAction(action1);
      ActionRepository().registerAction(action2);

      var result = await pipeAction.execute(
        [
          {'operation': 'action1', 'parameters': []},
          {'operation': 'action2', 'parameters': []},
        ],
        RuleContext(),
      );

      expect(result.output, equals('Action 2 executed'));
      expect(result.exception, isNull);
      expect(result.shouldContinue, isTrue);
      expect(result.childResults, hasLength(2));
      expect(result.childResults[0].output, equals('Action 1 executed'));
      expect(result.childResults[1].output, equals('Action 2 executed'));
    });

    test('Test Parallel Action', () async {
      var action1 = CustomAction('action1', (parameters, context) async {
        return 'Action 1 executed';
      });

      var action2 = CustomAction('action2', (parameters, context) async {
        return 'Action 2 executed';
      });

      var parallelAction = Parallel();
      ActionRepository().registerAction(action1);
      ActionRepository().registerAction(action2);

      var result = await parallelAction.execute(
        [
          {'operation': 'action1', 'parameters': []},
          {'operation': 'action2', 'parameters': []},
        ],
        RuleContext(),
      );

      expect(result.output, equals('Action 2 executed'));
      expect(result.exception, isNull);
      expect(result.shouldContinue, isTrue);
      expect(result.childResults, hasLength(2));
      expect(result.childResults[0].output, equals('Action 1 executed'));
      expect(result.childResults[1].output, equals('Action 2 executed'));
    });
  });

  group('Print Action Tests', () {
    test('Print action should process and print message correctly', () async {
      final printAction = Print();
      final context = RuleContext(facts: {'name': 'John Doe'});
      final parameters = [r'Hello, ${name}!'];

      final result = await printAction.execute(parameters, context);

      expect(result.output, equals('Hello, John Doe!'));
      // Since we can't directly test console output, we check if the output is correctly returned
    });

    test('Print action should throw exception with empty parameters', () {
      final printAction = Print();
      final context = RuleContext(facts: {});

      expect(
        printAction.execute([], context),
        throwsA(isA<RuleEngineException>()),
      );
    });

    test('Print action should correctly process template expressions',
        () async {
      final printAction = Print();
      final context = RuleContext(facts: {'day': 'Monday'});
      final parameters = [r'Today is ${day}.'];

      final result = await printAction.execute(parameters, context);

      expect(result.output, equals('Today is Monday.'));
    });
  });

  group('CustomAction Tests', () {
    test('CustomAction should execute provided function', () async {
      final customAction =
          CustomAction('testAction', (parameters, context) async {
        return 'Custom action executed';
      });

      final result = await customAction.execute([], RuleContext());

      expect(result.output, equals('Custom action executed'));
      expect(result.exception, isNull);
    });

    test('CustomAction should pass parameters to the function', () async {
      final customAction =
          CustomAction('testActionWithParams', (parameters, context) async {
        if (parameters.isNotEmpty && parameters[0] == 'param1') {
          return 'Parameter received';
        }
        return 'No parameter';
      });

      final result = await customAction.execute(['param1'], RuleContext());

      expect(result.output, equals('Parameter received'));
      expect(result.exception, isNull);
    });

    test('CustomAction should utilize context in the function', () async {
      final customAction =
          CustomAction('testActionWithContext', (parameters, context) async {
        if (context.getFacts().containsKey('key1')) {
          return context.getFacts()['key1'];
        }
        return 'Context not used';
      });

      final result = await customAction
          .execute([], RuleContext(facts: {'key1': 'value1'}));

      expect(result.output, equals('value1'));
      expect(result.exception, isNull);
    });

    test('CustomAction should handle exceptions thrown by the function',
        () async {
      final customAction =
          CustomAction('testActionException', (parameters, context) async {
        throw RuleEngineException('Custom action failed');
      });

      expect(
        customAction.execute([], RuleContext()),
        throwsA(isA<RuleEngineException>()),
      );
    });
  });

  group('Stop Action Tests', () {
    test('Executing Stop action returns correct ActionResult', () async {
      var stopAction = Stop();
      var result = await stopAction.execute([], RuleContext());

      expect(result.output, isNull,
          reason: 'Output should be null for Stop action');
      expect(result.exception, isNull,
          reason: 'Exception should be null for Stop action');
      expect(result.shouldContinue, isFalse,
          reason: 'shouldContinue should be false for Stop action');
    });
  });

  group('Chain Action Tests', () {
    test('Executing Chain with empty parameters throws exception', () async {
      var chainAction = Chain();
      expect(() => chainAction.execute([], RuleContext()),
          throwsA(isA<RuleEngineException>()));
    });

    test('Chain correctly executes a single action', () async {
      var mockAction = CustomAction(
          'mock', (parameters, context) async => 'Mock Action Executed');
      ActionRepository().registerAction(mockAction);

      var chainAction = Chain();
      var result = await chainAction.execute([
        {'operation': 'mock', 'parameters': []}
      ], RuleContext());

      expect(result.output, equals('Mock Action Executed'));
      expect(result.childResults, hasLength(1));
      expect(result.shouldContinue, isTrue);
    });

    test('Chain correctly executes multiple actions in sequence', () async {
      var mockAction1 = CustomAction(
          'mock1', (parameters, context) async => 'Mock Action 1 Executed');
      var mockAction2 = CustomAction(
          'mock2', (parameters, context) async => 'Mock Action 2 Executed');
      ActionRepository().registerAction(mockAction1);
      ActionRepository().registerAction(mockAction2);

      var chainAction = Chain();
      var result = await chainAction.execute([
        {'operation': 'mock1', 'parameters': []},
        {'operation': 'mock2', 'parameters': []}
      ], RuleContext());

      expect(result.output, equals('Mock Action 2 Executed'));
      expect(result.childResults, hasLength(2));
      expect(result.shouldContinue, isTrue);
    });

    test('Chain stops executing further actions if shouldContinue is false',
        () async {
      var stopAction = Stop();
      var mockAction = CustomAction(
          'mock', (parameters, context) async => 'Mock Action Executed');
      ActionRepository().registerAction(stopAction);
      ActionRepository().registerAction(mockAction);

      var chainAction = Chain();
      var result = await chainAction.execute([
        {'operation': 'stop', 'parameters': []},
        {
          'operation': 'mock',
          'parameters': []
        } // This action should not be executed
      ], RuleContext());

      expect(result.childResults, hasLength(1));
      expect(result.shouldContinue, isFalse);
    });
  });

  group('Pipe Action Tests', () {
    test('Executing Pipe with valid actions processes them in sequence',
        () async {
      var action1 = CustomAction('action1', (parameters, context) async {
        return 'First action executed';
      });

      var action2 = CustomAction('action2', (parameters, context) async {
        return 'Second action executed';
      });

      var pipeAction = Pipe();
      ActionRepository().registerAction(action1);
      ActionRepository().registerAction(action2);

      var result = await pipeAction.execute(
        [
          {'operation': 'action1', 'parameters': []},
          {'operation': 'action2', 'parameters': []},
        ],
        RuleContext(),
      );

      expect(result.output, equals('Second action executed'));
      expect(result.exception, isNull);
      expect(result.shouldContinue, isTrue);
      expect(result.childResults, hasLength(2));
      expect(result.childResults[0].output, equals('First action executed'));
      expect(result.childResults[1].output, equals('Second action executed'));
    });

    test('Executing Pipe with invalid action throws exception', () async {
      var invalidAction =
          CustomAction('invalidAction', (parameters, context) async {
        throw RuleEngineException('Invalid action executed');
      });

      var pipeAction = Pipe();
      ActionRepository().registerAction(invalidAction);

      expect(
        pipeAction.execute(
          [
            {'operation': 'invalidAction', 'parameters': []},
          ],
          RuleContext(),
        ),
        throwsA(isA<RuleEngineException>()),
      );
    });

    test('Execute method with empty parameters throws exception', () {
      var pipeAction = Pipe();
      expect(pipeAction.execute([], RuleContext()),
          throwsA(isA<RuleEngineException>()));
    });

    test(
        'Execute method stops execution when an action returns shouldContinue as false',
        () async {
      var stopAction = Stop();
      ActionRepository().registerAction(stopAction);

      var pipeAction = Pipe();
      var result = await pipeAction.execute([
        {'operation': 'stop', 'parameters': []}
      ], RuleContext());

      expect(result.shouldContinue, isFalse);
      expect(result.childResults, hasLength(1));
    });
  });

  group('Parallel Action Tests', () {
    test('Parallel action executes multiple actions in parallel', () async {
      var action1 = CustomAction(
          'action1', (parameters, context) async => 'Action 1 executed');
      var action2 = CustomAction(
          'action2', (parameters, context) async => 'Action 2 executed');
      ActionRepository().registerAction(action1);
      ActionRepository().registerAction(action2);

      var parallelAction = Parallel();
      var result = await parallelAction.execute([
        {'operation': 'action1', 'parameters': []},
        {'operation': 'action2', 'parameters': []}
      ], RuleContext());

      expect(result.shouldContinue, isTrue);
      expect(result.output, equals('Action 2 executed'));
      expect(result.childResults, hasLength(2));
      expect(result.childResults[0].output, equals('Action 1 executed'));
      expect(result.childResults[1].output, equals('Action 2 executed'));
    });

    test('Parallel action throws exception on empty parameters', () async {
      var parallelAction = Parallel();
      expect(() async => await parallelAction.execute([], RuleContext()),
          throwsA(isA<RuleEngineException>()));
    });

    test('Parallel action throws exception on invalid action definition',
        () async {
      var parallelAction = Parallel();
      expect(
          () async => await parallelAction.execute([
                {'operation': 'invalidAction', 'parameters': []}
              ], RuleContext()),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('ExpressionAction Tests', () {
    test('Evaluate simple expression', () async {
      var context = RuleContext();
      context.addFact('number', 5);
      var action = ExpressionAction();
      var parameters = ['5 + 5'];
      var result = await action.execute(parameters, context);
      expect(result.output, equals(10));
    });

    test('Evaluate expression with variable substitution', () async {
      var context = RuleContext();
      context.addFact('number', 5);
      var action = ExpressionAction();
      var parameters = ['number * 2'];
      var result = await action.execute(parameters, context);
      expect(result.output, equals(10));
    });

    test('Evaluate expression with member function', () async {
      var context = RuleContext();
      context.addFact('list', [1, 2, 3]);
      var action = ExpressionAction();
      var parameters = [r"list.contains(2)"];
      var result = await action.execute(parameters, context);
      expect(result.output, equals(true));
    });

    test('Evaluate expression with member accessor', () async {
      var email = Email(subject: 'Test subject', read: false);

      var context = RuleContext(resolve: [
        MemberAccessor<Email>({
          'markRead': (e) => e.markRead,
        }),
      ]);
      context.addFact('list', [1, 2, 3]);
      context.addFact('email', email);

      var action = ExpressionAction();
      var parameters = [r"email.markRead()"];
      var result = await action.execute(parameters, context);
      expect(result.output, isNull);

      email = context.getFact('email') as Email;
      expect(email.read, equals(true));
    });

    test('Handle invalid expression gracefully', () async {
      var context = RuleContext();
      var action = ExpressionAction();
      var parameters = ['invalid +'];
      try {
        await action.execute(parameters, context);
        fail('Should have thrown an exception for invalid expression');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}

class DummyAction extends Action {
  @override
  String get action => "dummy";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    // Minimal logic for testing
    return ActionResult(output: "Dummy output", exception: null);
  }
}

class Email {
  final String subject;
  bool read = false;

  Email({
    this.subject = '',
    this.read = false,
  });

  void markRead() {
    read = true;
  }
}
