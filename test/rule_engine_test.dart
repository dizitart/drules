import 'package:drules/drules.dart';
import 'package:drules/src/repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

@GenerateNiceMocks([
  MockSpec<RuleRepository>(),
  MockSpec<ActionRepository>(),
  MockSpec<ConditionRepository>(),
  MockSpec<Rule>(),
  MockSpec<RuleContext>(),
  MockSpec<ActionResult>(),
  MockSpec<RuleResult>(),
])
import 'rule_engine_test.mocks.dart';

void main() {
  group('RuleEngine', () {
    late RuleEngine ruleEngine;
    late MockRuleRepository mockRuleRepository;
    late MockRuleContext mockRuleContext;

    setUp(() {
      mockRuleRepository = MockRuleRepository();
      mockRuleContext = MockRuleContext();
      ruleEngine = RuleEngine(mockRuleRepository);
    });

    test('should register actions correctly', () {
      final action = MockAction();
      expect(() => ruleEngine.registerAction(action), returnsNormally);
    });

    test('should register conditions correctly', () {
      final condition = MockCondition();
      expect(() => ruleEngine.registerCondition(condition), returnsNormally);
    });

    test('dispose should dispose repositories', () async {
      await ruleEngine.dispose();
      verify(mockRuleRepository.dispose()).called(1);
    });

    group('run', () {
      test('should yield no results when no rules are found', () async {
        when(mockRuleRepository.findAllRules()).thenAnswer((_) async => []);
        var results = [];
        ruleEngine + (record) => results.add(record);

        await ruleEngine.run(mockRuleContext);
        expect(results, isEmpty);
      });

      test('should yield results for enabled rules', () async {
        final mockRule = MockRule();
        when(mockRule.id).thenReturn('testRule');
        when(mockRule.enabled).thenReturn(true);
        when(mockRule.priority).thenReturn(1);
        when(mockRule.conditions)
            .thenReturn(ConditionDefinition(operator: 'test', operands: []));
        when(mockRule.actionInfo).thenReturn(ActionInfo(
            onSuccess: ActionDefinition(operation: 'test', parameters: [])));

        final actionResult = MockActionResult();
        when(actionResult.shouldContinue).thenReturn(true);

        when(mockRuleRepository.findAllRules())
            .thenAnswer((_) async => [mockRule]);

        when(MockActionRepository().findAction('test'))
            .thenAnswer((_) => MockAction());
        when(MockConditionRepository().findCondition('test'))
            .thenAnswer((_) => MockCondition());

        ruleEngine.registerAction(MockAction());
        ruleEngine.registerCondition(MockCondition());

        var results = [];
        ruleEngine + (record) => results.add(record);

        await ruleEngine.run(mockRuleContext);

        await Future.delayed(Duration(milliseconds: 50));

        expect(results, isNotEmpty);
      });
    });
  });
}

class MockAction extends Action {
  @override
  String get action => 'test';

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    return MockActionResult();
  }
}

class MockCondition extends Condition {
  @override
  bool evaluate(List operands, RuleContext context) {
    return true;
  }

  @override
  String get operator => 'test';
}
