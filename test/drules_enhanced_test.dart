import 'package:drules/drules.dart';
import 'package:test/test.dart';

void main() {
  group('Enhanced Drules API', () {
    late Drules drules;

    setUp(() {
      drules = Drules();
    });

    tearDown(() async {
      await drules.dispose();
    });

    group('Fact Management', () {
      test('should add static facts correctly', () async {
        drules.addFacts({
          'staticValue': 42,
          'userName': 'John Doe',
          'isActive': true,
        });

        final facts = await drules.getCurrentFacts();
        expect(facts['staticValue'], equals(42));
        expect(facts['userName'], equals('John Doe'));
        expect(facts['isActive'], isTrue);
      });

      test('should add dynamic facts correctly', () async {
        var counter = 0;
        drules.addFacts({
          'dynamicCounter': () => ++counter,
          'timestamp': () => DateTime.now().millisecondsSinceEpoch,
        });

        final facts1 = await drules.getCurrentFacts();
        expect(facts1['dynamicCounter'], equals(1));

        final facts2 = await drules.getCurrentFacts();
        expect(facts2['dynamicCounter'], equals(2));
        expect(facts2['timestamp'], isA<int>());
      });

      test('should handle async fact providers', () async {
        drules.addFacts({
          'asyncValue': () async {
            await Future.delayed(Duration(milliseconds: 10));
            return 'async_result';
          },
        });

        final facts = await drules.getCurrentFacts();
        expect(facts['asyncValue'], equals('async_result'));
      });

      test('should handle fact provider errors gracefully', () async {
        drules.addFacts({
          'errorFact': () => throw Exception('Test error'),
          'normalFact': () => 'normal_value',
        });

        final facts = await drules.getCurrentFacts();
        expect(facts['errorFact_error'], contains('Test error'));
        expect(facts['normalFact'], equals('normal_value'));
      });

      test('should support fluent fact addition', () {
        final result = drules
            .addFact('key1', 'value1')
            .addFact('key2', () => 'dynamic_value');

        expect(result, same(drules));
      });

      test('should remove facts correctly', () async {
        drules.addFacts({
          'toRemove': 'value',
          'toKeep': 'value',
        });

        drules.removeFact('toRemove');
        final facts = await drules.getCurrentFacts();

        expect(facts.containsKey('toRemove'), isFalse);
        expect(facts['toKeep'], equals('value'));
      });

      test('should clear all facts', () async {
        drules.addFacts({'key1': 'value1', 'key2': 'value2'});
        drules.clearFacts();

        final facts = await drules.getCurrentFacts();
        // Only internal or error keys may remain, so check user keys are gone
        expect(facts.containsKey('key1'), isFalse);
        expect(facts.containsKey('key2'), isFalse);
      });
    });

    group('Action Management', () {
      test('should add actions with fluent API', () {
        final result = drules.addAction(
          key: 'testAction',
          condition: (facts) => facts['value'] == 42,
          onSuccess: () async => 'success_result',
          onFail: () async => 'fail_result',
        );

        expect(result, same(drules));
      });

      test('should trigger action on success condition', () async {
        var actionTriggered = false;

        drules.addFact('batteryLevel', 15).addAction(
              key: 'lowBatteryAlert',
              condition: (facts) => facts['batteryLevel'] < 20,
              onSuccess: () async {
                actionTriggered = true;
                return 'low_battery_alert_sent';
              },
              onFail: () async => 'battery_level_ok',
            );

        final results = await drules.trigger();

        expect(actionTriggered, isTrue);
        expect(results, hasLength(1));
        expect(results.first.output, equals('low_battery_alert_sent'));
        expect(results.first.exception, isNull);
      });

      test('should trigger action on fail condition', () async {
        var failActionTriggered = false;

        drules.addFact('batteryLevel', 80).addAction(
              key: 'lowBatteryAlert',
              condition: (facts) => facts['batteryLevel'] < 20,
              onSuccess: () async => 'low_battery_alert_sent',
              onFail: () async {
                failActionTriggered = true;
                return 'battery_level_ok';
              },
            );

        final results = await drules.trigger();

        expect(failActionTriggered, isTrue);
        expect(results, hasLength(1));
        expect(results.first.output, equals('battery_level_ok'));
      });

      test('should handle action without callbacks', () async {
        drules.addFact('value', 42).addAction(
              key: 'noCallbacks',
              condition: (facts) => facts['value'] == 42,
            );

        final results = await drules.trigger();
        expect(results, isEmpty);
      });

      test('should handle action execution errors', () async {
        drules.addFact('value', 42).addAction(
              key: 'errorAction',
              condition: (facts) => facts['value'] == 42,
              onSuccess: () async => throw Exception('Action failed'),
            );

        final results = await drules.trigger();

        expect(results, hasLength(1));
        expect(results.first.output, isNull);
        expect(results.first.exception, isA<Exception>());
        expect(results.first.shouldContinue, isFalse);
      });

      test('should remove actions correctly', () async {
        drules
            .addFact('value', 42)
            .addAction(
              key: 'toRemove',
              condition: (facts) => true,
              onSuccess: () async => 'should_not_trigger',
            )
            .addAction(
              key: 'toKeep',
              condition: (facts) => true,
              onSuccess: () async => 'should_trigger',
            );

        drules.removeAction('toRemove');
        final results = await drules.trigger();

        expect(results, hasLength(1));
        expect(results.first.output, equals('should_trigger'));
      });

      test('should clear all actions', () async {
        drules
            .addFact('value', 42)
            .addAction(
              key: 'action1',
              condition: (facts) => true,
              onSuccess: () async => 'result1',
            )
            .addAction(
              key: 'action2',
              condition: (facts) => true,
              onSuccess: () async => 'result2',
            );

        drules.clearActions();
        final results = await drules.trigger();

        expect(results, isEmpty);
      });
    });

    group('First Match Policy', () {
      test('should stop at first matching action', () async {
        var firstActionTriggered = false;
        var secondActionTriggered = false;

        drules
            .addFact('value', 42)
            .addAction(
              key: 'firstAction',
              condition: (facts) => facts['value'] == 42,
              onSuccess: () async {
                firstActionTriggered = true;
                return 'first_result';
              },
            )
            .addAction(
              key: 'secondAction',
              condition: (facts) => facts['value'] == 42,
              onSuccess: () async {
                secondActionTriggered = true;
                return 'second_result';
              },
            );

        final results = await drules.trigger();

        expect(firstActionTriggered, isTrue);
        expect(secondActionTriggered, isFalse);
        expect(results, hasLength(1));
        expect(results.first.output, equals('first_result'));
      });
    });

    group('Specific Action Triggering', () {
      test('should trigger specific actions by key', () async {
        var action1Triggered = false;
        var action2Triggered = false;
        var action3Triggered = false;

        drules
            .addFact('value', 42)
            .addAction(
              key: 'action1',
              condition: (facts) => facts['value'] == 42,
              onSuccess: () async {
                action1Triggered = true;
                return 'result1';
              },
            )
            .addAction(
              key: 'action2',
              condition: (facts) => facts['value'] == 42,
              onSuccess: () async {
                action2Triggered = true;
                return 'result2';
              },
            )
            .addAction(
              key: 'action3',
              condition: (facts) => facts['value'] == 42,
              onSuccess: () async {
                action3Triggered = true;
                return 'result3';
              },
            );

        final results = await drules.triggerSpecific(['action2', 'action3']);

        expect(action1Triggered, isFalse);
        expect(action2Triggered, isTrue);
        expect(action3Triggered, isTrue);
        expect(results, hasLength(2));
        expect(results[0].output, equals('result2'));
        expect(results[1].output, equals('result3'));
      });

      test('should ignore non-existent action keys', () async {
        drules.addFact('value', 42).addAction(
              key: 'existingAction',
              condition: (facts) => true,
              onSuccess: () async => 'result',
            );

        final results =
            await drules.triggerSpecific(['nonExistent', 'existingAction']);

        expect(results, hasLength(1));
        expect(results.first.output, equals('result'));
      });
    });

    group('Autonomous System Use Cases', () {
      test('network management scenario', () async {
        // Simulate network service
        var wifiConnected = true;
        var mobileDataActive = false;

        drules.addFacts({
          'wifiConnected': () => wifiConnected,
          'mobileDataActive': () => mobileDataActive,
        });

        // Network failover action
        drules.addAction(
          key: 'networkFailover',
          condition: (facts) => facts['wifiConnected'] == false,
          onSuccess: () async {
            mobileDataActive = true;
            return 'switched_to_mobile';
          },
          onFail: () async => 'wifi_stable',
        );

        // Initial state - WiFi connected
        var results = await drules.trigger();
        expect(results.first.output, equals('wifi_stable'));
        expect(mobileDataActive, isFalse);

        // WiFi disconnected
        wifiConnected = false;
        results = await drules.trigger();
        expect(results.first.output, equals('switched_to_mobile'));
        expect(mobileDataActive, isTrue);
      });

      test('battery optimization scenario', () async {
        var batteryLevel = 50;
        var powerSavingMode = false;

        drules.addFacts({
          'batteryLevel': () => batteryLevel,
          'powerSavingMode': () => powerSavingMode,
        });

        drules.addAction(
          key: 'batteryOptimization',
          condition: (facts) =>
              facts['batteryLevel'] < 20 && !facts['powerSavingMode'],
          onSuccess: () async {
            powerSavingMode = true;
            return 'power_saving_enabled';
          },
          onFail: () async => 'battery_sufficient',
        );

        // Battery sufficient
        var results = await drules.trigger();
        expect(results.first.output, equals('battery_sufficient'));

        // Battery low
        batteryLevel = 15;
        results = await drules.trigger();
        expect(results.first.output, equals('power_saving_enabled'));
        expect(powerSavingMode, isTrue);

        // Already in power saving mode
        batteryLevel = 10;
        results = await drules.trigger();
        expect(results.first.output, equals('battery_sufficient'));
      });

      test('sensor-driven actions scenario', () async {
        var temperature = 22.0;
        var humidityLevel = 45;
        var ventilationActive = false;

        drules.addFacts({
          'temperature': () => temperature,
          'humidity': () => humidityLevel,
          'ventilationActive': () => ventilationActive,
        });

        drules.addAction(
          key: 'climateControl',
          condition: (facts) =>
              facts['temperature'] > 25 || facts['humidity'] > 60,
          onSuccess: () async {
            ventilationActive = true;
            return 'ventilation_activated';
          },
          onFail: () async => 'climate_optimal',
        );

        // Normal conditions
        var results = await drules.trigger();
        expect(results.first.output, equals('climate_optimal'));

        // High temperature
        temperature = 27.0;
        results = await drules.trigger();
        expect(results.first.output, equals('ventilation_activated'));
        expect(ventilationActive, isTrue);
      });
    });

    group('Action Chaining', () {
      test('should support action chaining through triggerSpecific', () async {
        var step1Completed = false;
        var step2Completed = false;
        var step3Completed = false;

        drules
            .addFact('process', 'start')
            .addAction(
              key: 'step1',
              condition: (facts) => facts['process'] == 'start',
              onSuccess: () async {
                step1Completed = true;
                // Trigger next step
                await drules.triggerSpecific(['step2']);
                return 'step1_complete';
              },
            )
            .addAction(
              key: 'step2',
              condition: (facts) => step1Completed,
              onSuccess: () async {
                step2Completed = true;
                // Trigger next step
                await drules.triggerSpecific(['step3']);
                return 'step2_complete';
              },
            )
            .addAction(
              key: 'step3',
              condition: (facts) => step2Completed,
              onSuccess: () async {
                step3Completed = true;
                return 'step3_complete';
              },
            );

        await drules.triggerSpecific(['step1']);

        expect(step1Completed, isTrue);
        expect(step2Completed, isTrue);
        expect(step3Completed, isTrue);
      });
    });

    group('Integration with Facts', () {
      test('should refresh facts before each trigger', () async {
        var counter = 0;

        drules.addFacts({
          'counter': () => ++counter,
        });

        drules.addAction(
          key: 'counterAction',
          condition: (facts) => facts['counter'] > 0,
          onSuccess: () async {
            final currentFacts = await drules.getCurrentFacts();
            return 'counter_value_${currentFacts['counter']}';
          },
        );

        // First trigger
        var results = await drules.trigger();
        expect(results.first.output, contains('counter_value_'));

        // Second trigger should have incremented counter
        results = await drules.trigger();
        expect(results.first.output, contains('counter_value_'));

        // Verify counter was called multiple times
        expect(counter, greaterThan(1));
      });
    });
  });
}
