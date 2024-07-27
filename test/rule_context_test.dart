import 'package:drules/src/rule_context.dart';
import 'package:test/test.dart';

void main() {
  group('Rule Context', () {
    test('RuleContext class addFact() method', () {
      var context = RuleContext();
      context.addFact('key', 'value');
      expect(context.getFact('key'), equals('value'));
    });

    test('Fact class operator[] method', () {
      var fact = Facts({
        'key1': 'value1',
        'key2': {
          'nestedKey': 'nestedValue',
        },
        'list': [1, 2, 3],
      });
      expect(fact['key1'], equals('value1'));
      expect(fact['key2.nestedKey'], equals('nestedValue'));
      expect(fact['list.0'], equals(1));
    });

    test('Fact class containsKey() method', () {
      var fact = Facts({'key': 'value'});
      expect(fact.containsKey('key'), isTrue);
      expect(fact.containsKey('invalidKey'), isFalse);
    });

    test('Fact class fields getter', () {
      var fact = Facts({
        'key1': 'value1',
        'key2': {
          'nestedKey': 'nestedValue',
        },
        'list': [1, 2, 3],
      });
      var fields = fact.fields;
      expect(fields, isNotNull);
      expect(fields, isA<Set<String>>());
      expect(fields.length, equals(3));
      expect(fields, containsAll(['key1', 'key2.nestedKey', 'list']));
    });
  });
}
