import 'package:drules/drules.dart';
import 'package:test/test.dart';

void main() {
  group('Drules Enhanced API Integration', () {
    late Drules drules;

    setUp(() {
      drules = Drules();
    });

    tearDown(() async {
      await drules.dispose();
    });

    test('Single rule evaluation', () async {
      drules
        .addFact('param1', 'value1')
        .addAction(
          key: 'rule1',
          condition: (facts) => facts['param1'] == 'value1',
          onSuccess: () async => 'Success',
          onFail: () async => 'Failure',
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('Success'));
    });

    test('Multiple rules evaluation', () async {
      drules
        .addFact('param1', 'value1')
        .addFact('param2', 'value2')
        .addAction(
          key: 'rule1',
          condition: (facts) => facts['param1'] == 'value1',
          onSuccess: () async => 'Success1',
        )
        .addAction(
          key: 'rule2',
          condition: (facts) => facts['param2'] == 'value2',
          onSuccess: () async => 'Success2',
        );
      final results = await drules.triggerSpecific(['rule1', 'rule2']);
      expect(results, hasLength(2));
      expect(results[0].output, equals('Success1'));
      expect(results[1].output, equals('Success2'));
    });

    test('Disabled rule should not be evaluated', () async {
      drules
        .addFact('param1', 'value1')
        .addAction(
          key: 'rule1',
          condition: (facts) => false, // Simulate disabled
          onSuccess: () async => 'Success',
        );
      final results = await drules.trigger();
      expect(results, isEmpty);
    });

    test('ALL condition', () async {
      drules
        .addFact('param1', 'value1')
        .addFact('param2', 'value2')
        .addAction(
          key: 'allRule',
          condition: (facts) => facts['param1'] == 'value1' && facts['param2'] == 'value2',
          onSuccess: () async => 'AllSuccess',
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('AllSuccess'));
    });

    test('ANY condition', () async {
      drules
        .addFact('param1', 'value3')
        .addFact('param2', 'value2')
        .addAction(
          key: 'anyRule',
          condition: (facts) => facts['param1'] == 'value3' || facts['param2'] == 'value2',
          onSuccess: () async => 'AnySuccess',
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('AnySuccess'));
    });

    test('GT condition', () async {
      drules
        .addFact('param1', 20)
        .addAction(
          key: 'gtRule',
          condition: (facts) => facts['param1'] > 10,
          onSuccess: () async => 'GtSuccess',
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('GtSuccess'));
    });

    test('LT condition', () async {
      drules
        .addFact('param1', 0)
        .addAction(
          key: 'ltRule',
          condition: (facts) => facts['param1'] < 10,
          onSuccess: () async => 'LtSuccess',
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('LtSuccess'));
    });

    test('Contains string condition', () async {
      drules
        .addFact('param1', 'value1')
        .addAction(
          key: 'containsRule',
          condition: (facts) => (facts['param1'] as String).contains('value'),
          onSuccess: () async => 'ContainsSuccess',
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('ContainsSuccess'));
    });

    test('Custom action', () async {
      String? out;
      drules
        .addFact('param1', 'value1')
        .addAction(
          key: 'customAction',
          condition: (facts) => facts['param1'] == 'value1',
          onSuccess: () async {
            out = 'Testing action';
            return 'Custom action executed';
          },
        );
      final results = await drules.trigger();
      expect(results, hasLength(1));
      expect(results.first.output, equals('Custom action executed'));
      expect(out, equals('Testing action'));
    });
  });
}
