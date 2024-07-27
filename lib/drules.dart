/// A simple json based Dart rule engine.
library;

export 'src/actions.dart' show Action, CustomAction, lastResult;
export 'src/conditions.dart' show Condition;
export 'src/repository.dart' hide ActionRepository, ConditionRepository;
export 'src/rule_engine.dart';
export 'src/rule.dart' hide ruleId;
export 'src/repos/index.dart';
export 'src/events/activation.dart';
export 'src/rule_context.dart' hide Facts;
