import 'package:drules/drules.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:test/test.dart';

import 'action_test.dart';

void main() {
  group('RuleEngine Integration Tests', () {
    test('Single rule evaluation', () async {
      var jsonRule = '''
      {
        "id": "rule1",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var records = <ActivationRecord>[];

      var context = RuleContext();
      context.addFact('param1', 'value1');

      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records.length, equals(1));
      expect(records.first.ruleResult.ruleId, equals('rule1'));
    });

    test('Multiple rules evaluation', () async {
      var jsonRules = [
        '''
        {
          "id": "rule1",
          "enabled": true,
          "priority": 2,
          "conditions": {
            "operator": "==",
            "operands": ["param1", "value1"]
          },
          "actionInfo": {
            "onSuccess": {
              "operation": "logSuccess",
              "parameters": []
            },
            "onFailure": {
              "operation": "logFailure",
              "parameters": []
            }
          }
        }
        ''',
        '''
        {
          "id": "rule2",
          "enabled": true,
          "priority": 1,
          "conditions": {
            "operator": "==",
            "operands": ["param2", "value2"]
          },
          "actionInfo": {
            "onSuccess": {
              "operation": "logSuccess",
              "parameters": []
            },
            "onFailure": {
              "operation": "logFailure",
              "parameters": []
            }
          }
        }
        '''
      ];

      var ruleRepository = StringRuleRepository(jsonRules);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');
      context.addFact('param2', 'value2');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records.length, equals(2));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>()
                .having((r) => r.ruleResult.ruleId, 'ruleId', 'rule1'),
            isA<ActivationRecord>()
                .having((r) => r.ruleResult.ruleId, 'ruleId', 'rule2'),
          ]));
    });

    test('Disabled rule should not be evaluated', () async {
      var jsonRule = '''
      {
        "id": "rule1",
        "enabled": false,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, isEmpty);
    });

    test('ALL condition', () async {
      var jsonRule = '''
      {
        "id": "rule3",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "all",
          "operands": [
            {"operator": "==", "operands": ["param1", "value1"]},
            {"operator": "==", "operands": ["param2", "value2"]}
          ]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');
      context.addFact('param2', 'value2');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>()
                .having((a) => a.ruleResult.isSuccess, 'isSuccess', true)
          ]));
    });

    test('Multiple conditions', () async {
      var jsonRule = '''
      {
        "id": "rule_multiple_conditions",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "all",
          "operands": [
            {"operator": "==", "operands": ["param1", "value1"]},
            {"operator": "==", "operands": ["param2", "value2"]},
            {"operator": ">", "operands": ["param3", 10]}
          ]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 'value1');
      context.addFact('param2', 'value2');
      context.addFact('param3', 20);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('ANY condition', () async {
      var jsonRule = '''
      {
        "id": "rule4",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "any",
          "operands": [
            {"operator": "==", "operands": ["param1", "value3"]},
            {"operator": "==", "operands": ["param2", "value2"]}
          ]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1'); // This will not match
      context.addFact('param2', 'value2'); // This will match

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>()
                .having((a) => a.ruleResult.isSuccess, 'isSuccess', true)
          ]));
    });

    test('None condition', () async {
      var jsonRule = '''
      {
        "id": "rule5",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "none",
          "operands": [
            {"operator": "==", "operands": ["param1", "value3"]},
            {"operator": "==", "operands": ["param2", "value1"]}
          ]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');
      context.addFact('param2', 'value2');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>()
                .having((a) => a.ruleResult.isSuccess, 'isSuccess', true)
          ]));
    });

    test('NOT condition', () async {
      var jsonRule = '''
      {
        "id": "rule5",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "!",
          "operands": [
            {"operator": "==", "operands": ["param1", "value3"]}
          ]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>()
                .having((a) => a.ruleResult.isSuccess, 'isSuccess', true)
          ]));
    });

    test('NEQ condition', () async {
      var jsonRule = '''
      {
        "id": "ruleNEQ",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "!=",
          "operands": ["param1", "expectedValue"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 'actualValue');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>()
                .having((a) => a.ruleResult.isSuccess, 'isSuccess', true)
          ]));
    });

    test('GT condition', () async {
      var jsonRule = '''
      {
        "id": "rule_GT",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": ">",
          "operands": ["param1", 10]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 20);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('GT negative condition', () async {
      var jsonRule = '''
      {
        "id": "rule_GT_negative",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": ">",
          "operands": ["param1", 10]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 0);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, isEmpty);
    });

    test('GTE condition', () async {
      var jsonRule = '''
      {
        "id": "rule_GTE",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": ">=",
          "operands": ["param1", 10]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 10);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('LT condition', () async {
      var jsonRule = '''
      {
        "id": "rule_LT",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "<",
          "operands": ["param1", 10]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 0);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('LTE condition', () async {
      var jsonRule = '''
      {
        "id": "rule_LTE",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "<=",
          "operands": ["param1", 10]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 10);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('LTE negative condition', () async {
      var jsonRule = '''
      {
        "id": "rule_LTE_negative",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "<=",
          "operands": ["param1", 10]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 20);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, isEmpty);
    });

    test('Contains string condition', () async {
      var jsonRule = '''
      {
        "id": "rule_contains",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "contains",
          "operands": ["param1", "value"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('Contains list condition', () async {
      var jsonRule = '''
      {
        "id": "rule_contains_list",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "contains",
          "operands": ["param1", "value"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', ['value1', 'value']);

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('Startswith condition', () async {
      var jsonRule = '''
      {
        "id": "rule_startsWith",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "startsWith",
          "operands": ["param1", "value"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('Endswith condition', () async {
      var jsonRule = '''
      {
        "id": "rule_endsWith",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "endsWith",
          "operands": ["param1", "value"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', '1value');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('Matches condition', () async {
      var jsonRule = '''
      {
        "id": "rule_matches",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "matches",
          "operands": ["param1", "^[a-zA-Z0-9]*\$"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Success'))
          ]));
    });

    test('Matches negative condition', () async {
      var jsonRule = '''
      {
        "id": "rule_matches_negative",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "matches",
          "operands": ["param1", "^[a-zA-Z0-9]*\$"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "logSuccess",
            "parameters": []
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext();
      context.addFact('param1', 'value1@');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, isEmpty);
    });

    test('Expression condition', () async {
      var jsonRule = '''
      {
        "id": "rule_expression",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "expression",
          "operands": ["email.subject.contains('Hello')"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "expression",
            "parameters": ["email.markRead()"]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogFailure());
      var context = RuleContext(resolve: [
        MemberAccessor<Email>({
          'subject': (e) => e.subject,
          'markRead': (e) => e.markRead,
        }),
      ]);
      context.addFact('email', Email(subject: 'Hello World'));

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output, 'Email.read', isNull)
          ]));

      var email = context.getFact('email') as Email;
      expect(email.read, isTrue);
    });

    test('Custom action', () async {
      var jsonRule = '''
      {
        "id": "rule_custom_action",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "testAction",
            "parameters": [
              "Testing action"
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine
          .registerAction(CustomAction('testAction', (list, context) async {
        context.addFact("out", list.first.toString());
        return 'Custom action executed';
      }));
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Custom action executed'))
          ]));

      var out = context.getFact('out');
      expect(out, equals('Testing action'));
    });

    test('Stop action', () async {
      var jsonRule = '''
      {
        "id": "rule_stop",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "expression",
          "operands": ["counter.value == 2"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "chain",
            "parameters": [
              {
                "operation": "expression",
                "parameters" : ["counter.increment()"]
              },
              {
                "operation": "stop",
                "parameters": []
              },
              {
                "operation": "expression",
                "parameters": ["counter.increment()"]
              }
            ]
          },
          "onFailure": {
            "operation": "stop",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());

      var context = RuleContext(resolve: [
        MemberAccessor<_Counter>({
          'value': (c) => c.value,
          'increment': (c) => c.increment,
        }),
      ]);
      context.addFact('counter', _Counter(2));

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output, 'counter', isNull)
          ]));

      var counter = context.getFact('counter');
      expect(counter.value, equals(3));

      jsonRule = '''
      {
        "id": "rule_stop",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "expression",
          "operands": ["counter.value == 2"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "chain",
            "parameters": [
              {
                "operation": "expression",
                "parameters" : ["counter.increment()"]
              },
              {
                "operation": "expression",
                "parameters": ["counter.increment()"]
              }
            ]
          },
          "onFailure": {
            "operation": "stop",
            "parameters": []
          }
        }
      }
      ''';
      ruleRepository = StringRuleRepository([jsonRule]);
      ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogSuccess());

      context = RuleContext(resolve: [
        MemberAccessor<_Counter>({
          'value': (c) => c.value,
          'increment': (c) => c.increment,
        }),
      ]);
      context.addFact('counter', _Counter(2));

      records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output, 'counter', isNull)
          ]));

      counter = context.getFact('counter');
      expect(counter.value, equals(4));
    });

    test('Print action', () async {
      var jsonRule = '''
      {
        "id": "rule_print",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "print",
            "parameters": ["Hello World"]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Hello World'))
          ]));
    });

    test('Chain action', () async {
      var jsonRule = '''
      {
        "id": "rule_chain",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "chain",
            "parameters": [
              {
                "operation": "action1",
                "parameters": [2, 3]
              },
              {
                "operation": "action2",
                "parameters": [1, 4]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Action1());
      ruleEngine.registerAction(_Action2());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output, 'output', equals(5))
          ]));

      var result = context.getFact(lastResult);
      expect(result, isNull);
    });

    test('Pipe action', () async {
      var jsonRule = '''
      {
        "id": "rule_pipe",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "pipe",
            "parameters": [
              {
                "operation": "action1",
                "parameters": [2, 3]
              },
              {
                "operation": "action2",
                "parameters": [4]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Action1());
      ruleEngine.registerAction(_Action2());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output, 'output', equals(9))
          ]));

      var result = context.getFact(lastResult);
      expect(result, equals(9));
    });

    test('Parallel action', () async {
      var jsonRule = '''
      {
        "id": "rule_parallel",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "parallel",
            "parameters": [
              {
                "operation": "wait",
                "parameters": [2]
              },
              {
                "operation": "wait",
                "parameters": [2]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Wait());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      final stopwatch = Stopwatch()..start();

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Completed'))
          ]));

      expect(stopwatch.elapsed.inSeconds, lessThan(3));
    });

    test('Execution time between chain and parallel action', () async {
      var jsonRule = '''
      {
        "id": "rule_chain_parallel",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "chain",
            "parameters": [
              {
                "operation": "wait",
                "parameters": [2]
              },
              {
                "operation": "wait",
                "parameters": [2]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Wait());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var stopwatch = Stopwatch()..start();

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Completed'))
          ]));

      expect(stopwatch.elapsed.inSeconds, greaterThan(3));

      jsonRule = '''
      {
        "id": "rule_chain_parallel",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "parallel",
            "parameters": [
              {
                "operation": "wait",
                "parameters": [2]
              },
              {
                "operation": "wait",
                "parameters": [2]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';

      ruleRepository = StringRuleRepository([jsonRule]);
      ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Wait());
      ruleEngine.registerAction(_LogFailure());

      context = RuleContext();
      context.addFact('param1', 'value1');

      stopwatch = Stopwatch()..start();

      records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(records, hasLength(1));
      expect(
          records,
          orderedEquals([
            isA<ActivationRecord>().having(
                (a) => a.ruleResult.actionResult.output,
                'output',
                equals('Completed'))
          ]));

      expect(stopwatch.elapsed.inSeconds, lessThan(3));
    });

    test('Execution order of chain', () async {
      var jsonRule = '''
      {
        "id": "rule_chain_order",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "chain",
            "parameters": [
              {
                "operation": "action1",
                "parameters": [2, 3]
              },
              {
                "operation": "action2",
                "parameters": [1, 5]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Action1());
      ruleEngine.registerAction(_Action2());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      var childResults = records.first.ruleResult.actionResult.childResults;

      expect(childResults.length, equals(2));
      expect(childResults[0].output, equals(5));
      expect(childResults[1].output, equals(6));
    });

    test('Execution order of pipe', () async {
      var jsonRule = '''
      {
        "id": "rule_pipe_order",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "==",
          "operands": ["param1", "value1"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "pipe",
            "parameters": [
              {
                "operation": "action1",
                "parameters": [2, 3]
              },
              {
                "operation": "action2",
                "parameters": [5]
              }
            ]
          },
          "onFailure": {
            "operation": "logFailure",
            "parameters": []
          }
        }
      }
      ''';
      var ruleRepository = StringRuleRepository([jsonRule]);
      var ruleEngine = RuleEngine(ruleRepository);
      ruleEngine.registerAction(_Action1());
      ruleEngine.registerAction(_Action2());
      ruleEngine.registerAction(_LogFailure());

      var context = RuleContext();
      context.addFact('param1', 'value1');

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      var childResults = records.first.ruleResult.actionResult.childResults;

      expect(childResults.length, equals(2));
      expect(childResults[0].output, equals(5));
      expect(childResults[1].output, equals(10));
    });

    test('Test json file rule 1', () async {
      var ruleEngine = RuleEngine(
        FileRuleRepository(
          fileNames: ['test/rules/rule_one.json'],
        ),
      );

      var context = RuleContext(
        facts: {
          'email': {
            'subject': 'Hello',
            'body': 'Hello, how are you?',
            'from': 'a@b.com'
          },
        },
      );

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      var ruleResult = records.first.ruleResult;

      expect(ruleResult.isSuccess, isTrue);
      expect(ruleResult.actionResult.output,
          contains('Email has been tagged as read.'));
    });

    test('Test json file rule 2', () async {
      var ruleEngine = RuleEngine(
        FileRuleRepository(
          fileNames: ['test/rules/rule_two.json'],
        ),
      );

      var context = RuleContext(
        facts: {
          'email': {
            'subject': 'Hello',
            'body': 'Hello, how are you?',
            'from': 'a@b.com'
          },
        },
      );

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      var ruleResult = records.first.ruleResult;
      expect(ruleResult.isSuccess, isTrue);
      expect(ruleResult.actionResult.output,
          contains('Email with subject Hello has been read.'));
    });

    test('Test stop executing further rule by STOP', () async {
      var ruleEngine = RuleEngine(
        FileRuleRepository(
          fileNames: [
            'test/rules/rule_one.json',
            'test/rules/stop_rule_one.json',
          ],
        ),
      );

      var context = RuleContext(
        facts: {
          'email': {
            'subject': 'Hello',
            'body': 'Hello, how are you?',
            'from': 'a@b.com'
          },
        },
      );

      var records = <ActivationRecord>[];
      ruleEngine + (record) => records.add(record);

      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      var ruleResult = records.first.ruleResult;

      expect(ruleResult.isSuccess, isTrue);
      expect(ruleResult.actionResult.childResults, hasLength(2));
      expect(ruleResult.actionResult.childResults.first.output,
          contains('Email has been tagged as read.'));
    });

    test('Test stop executing further action in a rule by STOP', () async {
      var ruleEngine = RuleEngine(
        StringRuleRepository(
          [
            r"""
{
    "id": "2",
    "name": "Stop Action Test Rule",
    "enabled": true,
    "priority": 2,
    "parameters": [
        "email.from"
    ],
    "conditions": {
        "operator": "==",
        "operands": [
            "email.from",
            "a@b.com"
        ]
    },
    "actionInfo": {
        "onSuccess": {
            "operation": "chain",
            "parameters": [
                {
                    "operation": "stop",
                    "parameters": []
                },
                {
                    "operation": "print",
                    "parameters": [
                        "Email has been tagged as read."
                    ]
                }
            ]
        },
        "onFailure": {
            "operation": "print",
            "parameters": [
                "Stop Action Test Rule 1 failed with error - ${error}"
            ]
        }
    }
}
""",
            r"""
{
    "id": "1",
    "name": "Rule One",
    "enabled": true,
    "priority": 1,
    "parameters": [
        "email.from"
    ],
    "conditions": {
        "operator": "==",
        "operands": [
            "email.from",
            "a@b.com"
        ]
    },
    "actionInfo": {
        "onSuccess": {
            "operation": "print",
            "parameters": [
                "Email with subject ${email.subject} has been read."
            ]
        },
        "onFailure": {
            "operation": "print",
            "parameters": [
                "Rule one failed with error - ${error}"
            ]
        }
    }
}
"""
          ],
        ),
      );

      var context = RuleContext(
        facts: {
          'email': {
            'subject': 'Hello',
            'body': 'Hello, how are you?',
            'from': 'a@b.com'
          },
        },
      );

      List<RuleResult> results = [];
      ruleEngine + (record) => results.add(record.ruleResult);
      await ruleEngine.run(context);

      // wait for events to be processed
      await Future.delayed(Duration(milliseconds: 50));

      expect(results.length, equals(1));
      expect(results.first.isSuccess, isTrue);
      expect(results.first.actionResult.childResults, hasLength(1));
      expect(results.first.actionResult.childResults.first.output, isNull);
    });
  });
}

class _LogSuccess extends Action {
  @override
  String get action => "logSuccess";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    print('Rule ${context.currentRuleId} executed successfully');

    return ActionResult(shouldContinue: true, output: 'Success');
  }
}

class _LogFailure extends Action {
  @override
  String get action => "logFailure";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    print('Rule ${context.currentRuleId} failed');

    return ActionResult(shouldContinue: true, output: 'Failure');
  }
}

class _Counter {
  int _value;

  _Counter(this._value);

  void increment() {
    _value++;
  }

  int get value => _value;
}

class _Action1 extends Action {
  @override
  String get action => 'action1';

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    var first = parameters[0] as int;
    var second = parameters[1] as int;

    var result = first + second;
    return ActionResult(
      output: result,
    );
  }
}

class _Action2 extends Action {
  @override
  String get action => 'action2';

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    var first = parameters[0] as int;
    var second = context.getFact(lastResult) == null
        ? parameters[1] as int
        : context.getFact(lastResult) as int;

    var result = first + second;
    return ActionResult(
      output: result,
    );
  }
}

class _Wait extends Action {
  @override
  String get action => 'wait';

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    await Future.delayed(Duration(seconds: parameters.first as int));
    return ActionResult(output: 'Completed');
  }
}
