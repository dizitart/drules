import 'package:drules/src/conditions.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:test/test.dart';
import 'package:drules/drules.dart';

import 'action_test.dart';

void main() {
  group('All Condition Tests', () {
    test('Evaluate All condition with true operands', () {
      var condition = All();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 1]
        },
        {
          'operator': '==',
          'operands': ['2', 2]
        },
        {
          'operator': '==',
          'operands': ['3', 3]
        },
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate All condition with false operands', () {
      var condition = All();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 1]
        },
        {
          'operator': '==',
          'operands': ['2', 3]
        }, // false condition
        {
          'operator': '==',
          'operands': ['3', 3]
        },
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate All condition with empty operands', () {
      var condition = All();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Any Condition Tests', () {
    test('Evaluate Any condition with true operands', () {
      var condition = Any();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 2]
        }, // false condition
        {
          'operator': '==',
          'operands': ['2', 2]
        },
        {
          'operator': '==',
          'operands': ['3', 4]
        }, // false condition
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Any condition with false operands', () {
      var condition = Any();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 2]
        }, // false condition
        {
          'operator': '==',
          'operands': ['2', 3]
        }, // false condition
        {
          'operator': '==',
          'operands': ['3', 4]
        }, // false condition
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Any condition with empty operands', () {
      var condition = Any();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('None Condition Tests', () {
    test('Evaluate None condition with true operands', () {
      var condition = None();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 2]
        }, // false condition
        {
          'operator': '==',
          'operands': ['2', 3]
        }, // false condition
        {
          'operator': '==',
          'operands': ['3', 4]
        }, // false condition
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate None condition with false operands', () {
      var condition = None();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 2]
        }, // false condition
        {
          'operator': '==',
          'operands': ['2', 2]
        },
        {
          'operator': '==',
          'operands': ['3', 4]
        }, // false condition
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate None condition with empty operands', () {
      var condition = None();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Eq Condition Tests', () {
    test('Evaluate Eq condition with equal operands', () {
      var condition = Eq();
      var operands = ['1', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Eq condition with not equal operands', () {
      var condition = Eq();
      var operands = ['1', 2];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Eq condition with empty operands', () {
      var condition = Eq();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Eq condition with invalid operands', () {
      var condition = Eq();
      var operands = [1];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Neq Condition Tests', () {
    test('Evaluate Neq condition with not equal operands', () {
      var condition = Neq();
      var operands = ['1', 2];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Neq condition with equal operands', () {
      var condition = Neq();
      var operands = ['1', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Neq condition with empty operands', () {
      var condition = Neq();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Neq condition with invalid operands', () {
      var condition = Neq();
      var operands = [1];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Gt Condition Tests', () {
    test('Evaluate Gt condition with greater operands', () {
      var condition = Gt();
      var operands = ['2', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Gt condition with smaller operands', () {
      var condition = Gt();
      var operands = ['1', 2];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Gt condition with empty operands', () {
      var condition = Gt();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Gt condition with invalid operands', () {
      var condition = Gt();
      var operands = [1];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Gte Condition Tests', () {
    test('Evaluate Gte condition with greater operands', () {
      var condition = Gte();
      var operands = ['2', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Gte condition with equal operands', () {
      var condition = Gte();
      var operands = ['1', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Gte condition with smaller operands', () {
      var condition = Gte();
      var operands = ['1', 2];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Gte condition with empty operands', () {
      var condition = Gte();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Gte condition with invalid operands', () {
      var condition = Gte();
      var operands = [1];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Lt Condition Tests', () {
    test('Evaluate Lt condition with smaller operands', () {
      var condition = Lt();
      var operands = ['1', 2];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Lt condition with greater operands', () {
      var condition = Lt();
      var operands = ['2', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Lt condition with empty operands', () {
      var condition = Lt();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Lt condition with invalid operands', () {
      var condition = Lt();
      var operands = [1];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Lte Condition Tests', () {
    test('Evaluate Lte condition with smaller operands', () {
      var condition = Lte();
      var operands = ['1', 2];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Lte condition with equal operands', () {
      var condition = Lte();
      var operands = ['1', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Lte condition with greater operands', () {
      var condition = Lte();
      var operands = ['2', 1];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Lte condition with empty operands', () {
      var condition = Lte();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Lte condition with invalid operands', () {
      var condition = Lte();
      var operands = [1];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Not Condition Tests', () {
    test('Evaluate Not condition with true operand', () {
      var condition = Not();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 1]
        }
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Not condition with false operand', () {
      var condition = Not();
      var operands = [
        {
          'operator': '==',
          'operands': ['1', 2]
        }
      ];
      var context = RuleContext(facts: {'1': 1, '2': 2, '3': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Not condition with empty operands', () {
      var condition = Not();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Contains Condition Tests', () {
    test('Evaluate Contains condition with matching operands', () {
      var condition = Contains();
      var operands = ['1', 'Hello'];
      var context = RuleContext(facts: {'1': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Contains condition with non-matching operands', () {
      var condition = Contains();
      var operands = ['1', 'Hello'];
      var context = RuleContext(facts: {'1': 'World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Contains condition with empty operands', () {
      var condition = Contains();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Contains condition with invalid operands', () {
      var condition = Contains();
      var operands = ['Hello, World!'];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('StartsWith Condition Tests', () {
    test('Evaluate StartsWith condition with matching operands', () {
      var condition = StartsWith();
      var operands = ['a', 'Hello'];
      var context = RuleContext(facts: {'a': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate StartsWith condition with non-matching operands', () {
      var condition = StartsWith();
      var operands = ['a', 'Foo'];
      var context = RuleContext(facts: {'a': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate StartsWith condition with empty operands', () {
      var condition = StartsWith();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate StartsWith condition with invalid operands', () {
      var condition = StartsWith();
      var operands = ['Hello, World!'];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('EndsWith Condition Tests', () {
    test('Evaluate EndsWith condition with matching operands', () {
      var condition = EndsWith();
      var operands = ['a', 'World!'];
      var context = RuleContext(facts: {'a': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate EndsWith condition with non-matching operands', () {
      var condition = EndsWith();
      var operands = ['a', 'Foo'];
      var context = RuleContext(facts: {'a': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate EndsWith condition with empty operands', () {
      var condition = EndsWith();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate EndsWith condition with invalid operands', () {
      var condition = EndsWith();
      var operands = ['Hello, World!'];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Regex Condition Tests', () {
    test('Evaluate Regex condition with matching operands', () {
      var condition = Matches();
      var operands = ['a', 'Hello.*'];
      var context = RuleContext(facts: {'a': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Regex condition with matching pattern', () {
      var condition = Matches();
      var operands = ['a', r'^\d+$']; // Pattern to match digits only
      var context = RuleContext(facts: {'a': '12345'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Regex condition with non-matching operands', () {
      var condition = Matches();
      var operands = ['a', 'Foo.*'];
      var context = RuleContext(facts: {'a': 'Hello, World!'});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Regex condition with non-matching pattern', () {
      var condition = Matches();
      var operands = ['a', r'^\d+$']; // Pattern to match digits only
      var context = RuleContext(facts: {'a': 'abcd'});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Regex condition with empty operands', () {
      var condition = Matches();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Regex condition with invalid operands', () {
      var condition = Matches();
      var operands = ['Hello, World!'];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Regex condition with special characters in pattern', () {
      var condition = Matches();
      var operands = ['a', r'\$\d+\.\d{2}']; // Pattern for currency format
      var context = RuleContext(facts: {'a': r'$100.00'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test(
        'Evaluate Regex condition with pattern and input with special characters',
        () {
      var condition = Matches();
      var operands = ['a', r'\bhello\b']; // Word boundary pattern
      var context = RuleContext(facts: {'a': 'hello world'});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Regex condition with empty pattern', () {
      var condition = Matches();
      var operands = ['a', '']; // Empty pattern
      var context = RuleContext(facts: {'a': 'hello world'});
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Regex condition with null pattern', () {
      var condition = Matches();
      var operands = ['a', null]; // Null pattern
      var context = RuleContext(facts: {'a': 'hello world'});
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Regex condition with insufficient operands', () {
      var condition = Matches();
      var operands = [r'^\d+$']; // Missing input string
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });
  });

  group('Expression Condition Tests', () {
    test('Evaluate Expression condition with true expression', () {
      var condition = ExpressionCondition();
      var operands = ['x + 1 == 2'];
      var context = RuleContext(facts: {'x': 1});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Expression condition with false expression', () {
      var condition = ExpressionCondition();
      var operands = ['1 + x == 3'];
      var context = RuleContext(facts: {'x': 1});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Expression condition with empty operands', () {
      var condition = ExpressionCondition();
      var operands = [];
      var context = RuleContext();
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Expression condition with invalid operands', () {
      var condition = ExpressionCondition();
      var operands = ['x + 1 == 2', 'y + 1 == 3'];
      var context = RuleContext(facts: {'z': 3});
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Expression condition with non-boolean expression', () {
      var condition = ExpressionCondition();
      var operands = ['x + 1'];
      var context = RuleContext(facts: {'x': 1});
      expect(() => condition.evaluate(operands, context),
          throwsA(isA<RuleEngineException>()));
    });

    test('Evaluate Expression condition with valid complex expression', () {
      var condition = ExpressionCondition();
      var operands = ['(x * 3) + 2 == 11'];
      var context = RuleContext(facts: {'x': 3});
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });

    test('Evaluate Expression condition with invalid complex expression', () {
      var condition = ExpressionCondition();
      var operands = ['(3 * 3) + x == 10']; // Incorrect expression
      var context = RuleContext(facts: {'x': 2});
      var result = condition.evaluate(operands, context);
      expect(result, isFalse);
    });

    test('Evaluate Expression condition with member accessor', () {
      var condition = ExpressionCondition();
      var operands = ["email.subject.contains('Hello')"];
      var context = RuleContext(resolve: [
        MemberAccessor<Email>({
          'subject': (e) => e.subject,
        })
      ]);
      context.addFact('email', Email(subject: 'Hello World'));
      var result = condition.evaluate(operands, context);
      expect(result, isTrue);
    });
  });
}
