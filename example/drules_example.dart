import 'package:drules/drules.dart';
import 'package:template_expressions/template_expressions.dart';

void main() async {
  var jsonRules = [
    '''
      {
        "id": "1",
        "name": "Mark email as read if its from a@b.com",
        "enabled": true,
        "priority": 2,
        "conditions": {
          "operator": "==",
          "operands": ["email.from", "a@b.com"]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "chain",
            "parameters": [
              {
                "operation": "markAsRead",
                "parameters": []
              },
              {
                "operation": "print",
                "parameters": ["Email read status - \${email.read}"]
              }
            ]
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
        "id": "2",
        "name": "Delete email if its subject conatins 'Hello' and from a@b.com",
        "enabled": true,
        "priority": 1,
        "conditions": {
          "operator": "all",
          "operands": [
            {
              "operator": "==",
              "operands": ["email.from", "a@b.com"]
            },
            {
              "operator": "expression",
              "operands": ["email.subject.contains('Hello')"]
            }
          ]
        },
        "actionInfo": {
          "onSuccess": {
            "operation": "expression",
            "parameters": ["email.delete()"]
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
        "name": "rule1",
        "conditions": {
          "operator": ">",
          "operands": ["age", 18]
        },
        "actionInfo": {
            "onSuccess": {
                "operation": "print",
                "parameters": ["You are an adult"]
            }
        }
    }
    ''',
    '''
    {
        "name": "rule2",
        "conditions": {
          "operator": "<",
          "operands": ["age", 18]
        },
        "actionInfo": {
            "onSuccess": {
                "operation": "print",
                "parameters": ["You are a child"]
            }
        }
    }
    '''
  ];

  var ruleRepository = StringRuleRepository(jsonRules);
  var ruleEngine = RuleEngine(ruleRepository);
  var records = <ActivationRecord>[];

  ruleEngine.registerAction(_LogFailure());
  ruleEngine.registerAction(_MarkAsRead());

  ruleEngine + (record) => records.add(record);

  var context = RuleContext(resolve: [
    MemberAccessor<Email>({
      'subject': (e) => e.subject,
      'from': (e) => e.from,
      'read': (e) => e.read,
      'delete': (e) => e.delete,
    }),
  ]);

  // should activate email rules
  context.addFact('email', Email(subject: 'Hello World', from: 'a@b.com'));

  // should activate age rules
  context.addFact("age", 20);

  await ruleEngine.run(context);

  print('========= Activation Records =========');
  for (var record in records) {
    print('Run ${record.runId} executed with record - $record');
  }
}

class _LogFailure extends Action {
  @override
  String get action => "logFailure";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    print(
        'Rule ${context.currentRuleId} failed due to - ${context.getError()}');

    return ActionResult(shouldContinue: true, output: 'Failure');
  }
}

class _MarkAsRead extends Action {
  @override
  String get action => "markAsRead";

  @override
  Future<ActionResult> execute(List parameters, RuleContext context) async {
    var email = context.getFact('email') as Email?;

    email?.markRead();

    return ActionResult(shouldContinue: true, output: email?.read);
  }
}

class Email {
  final String subject;
  final String from;
  bool read;

  Email({
    this.subject = '',
    this.from = '',
    this.read = false,
  });

  void delete() {
    print('Email deleted from $from');
  }

  void markRead() {
    read = true;
  }
}
