import 'dart:async';

import 'package:drules/drules.dart';
import 'package:drules/src/repository.dart';
import 'package:drules/src/rule.dart';
import 'package:event_bus/event_bus.dart';
import 'package:template_expressions/template_expressions.dart';
import 'package:uuid/uuid.dart';

/// Represents a JSON based rule engine where all rules are stored in JSON format.
///
/// The rule engine is responsible for executing rules based on the context
/// provided. It evaluates the conditions of each rule and if the conditions are
/// met, it executes the action associated with the rule. All rules are stored
/// in a rule repository and are executed in descending order of priority.
///
/// The facts are passed to the rule engine via [RuleContext] and is used to
/// evaluate the conditions and execute the actions. The facts can be passed as
/// a map of key-value pairs where the keys are strings and the values are dynamic
/// including user-defined objects. To access the fields of a user-defined object,
/// one must provide the list of [MemberAccessor]s to the `resolve` parameter of
/// the [RuleContext] which are used to access the fields of the object.
///
/// The rule engine can be configured with custom actions and conditions. It also
/// supports event listeners that can be used to listen to rule activations.
///
/// The rule engine is asynchronous and can be used in a non-blocking manner.
class RuleEngine {
  final RuleRepository _ruleRepository;
  final _actionRepository = ActionRepository();
  final _conditionRepository = ConditionRepository();
  final _eventBus = EventBus();
  final _subscriptions = <int, StreamSubscription<ActivationRecord>>{};

  RuleEngine(this._ruleRepository) {
    _actionRepository.init();
    _conditionRepository.init();
  }

  /// Registers a custom action with the rule engine.
  ///
  /// The action must implement the [Action] interface.
  void registerAction(Action action) {
    _actionRepository.registerAction(action);
  }

  /// Registers a custom condition with the rule engine.
  ///
  /// The condition must implement the [Condition] interface.
  void registerCondition(Condition condition) {
    _conditionRepository.registerCondition(condition);
  }

  /// Adds an event listener to the rule engine.
  ///
  /// The event listener is notified whenever a rule is activated.
  void addListener(ActivationEventListener listener) {
    var subscription = _eventBus.on<ActivationRecord>().listen(listener);
    var hashCode = subscription.hashCode;
    _subscriptions[hashCode] = subscription;
  }

  /// Removes an event listener from the rule engine.
  ///
  /// The event listener is no longer notified when a rule is activated.
  void removeListener(ActivationEventListener listener) {
    var subscription = _subscriptions[listener.hashCode];
    if (subscription != null) {
      subscription.cancel();
      _subscriptions.remove(hashCode);
    }
  }

  /// Adds an event listener to the rule engine.
  void operator +(ActivationEventListener listener) {
    addListener(listener);
  }

  /// Removes an event listener from the rule engine.
  void operator -(ActivationEventListener listener) {
    removeListener(listener);
  }

  /// Disposes the rule engine.
  ///
  /// Disposing the rule engine releases all resources used by the rule engine.
  Future<void> dispose() async {
    _actionRepository.dispose();
    _conditionRepository.dispose();
    _ruleRepository.dispose();
    _eventBus.destroy();
  }

  /// Runs the rule engine with the given context.
  ///
  /// The rule engine evaluates all rules in descending order of priority.
  Future<void> run(RuleContext context) async {
    var rules = await _ruleRepository.findAllRules();

    // take only enabled rules
    rules = rules.where((rule) => rule.enabled).toList();

    // sort by descending order of priority
    rules.sort((a, b) => b.priority.compareTo(a.priority));

    for (var rule in rules) {
      var shouldContinue = await _runRule(rule, context);

      if (!shouldContinue) {
        // check if the rule is marked as shouldContinue = false
        break;
      }
    }
  }

  Future<bool> _runRule(Rule rule, RuleContext context) async {
    var conditionResult = false;
    var isSuccess = false;
    var activated = false;
    var actionResult = ActionResult(
      output: null,
      exception: null,
      stackTrace: null,
    );

    var stopWatch = Stopwatch()..start();
    try {
      context.addFact(ruleId, rule.id);
      conditionResult = _runCondition(rule.conditions, context);
      if (conditionResult) {
        activated = true;
        var action = rule.actionInfo.onSuccess;
        if (action != null) {
          actionResult = await _runAction(action, context);
        } else {
          actionResult = ActionResult(
            output: null,
            exception: null,
            stackTrace: null,
          );
        }
      }
      isSuccess = true;
    } on Exception catch (e, stackTrace) {
      context.addFact('error', e);
      var action = rule.actionInfo.onFailure;
      if (action != null) {
        actionResult = await _runAction(action, context);
      } else {
        actionResult = ActionResult(
          output: null,
          exception: e,
          stackTrace: stackTrace,
        );
      }

      var errorResult = ActionResult(
        output: actionResult.output,
        shouldContinue: false,
        exception: actionResult.exception ?? e,
        stackTrace: actionResult.stackTrace ?? stackTrace,
        childResults: actionResult.childResults,
      );
      actionResult = errorResult;
    }

    stopWatch.stop();

    if (activated) {
      var ruleResult = RuleResult(
        ruleId: rule.id,
        isSuccess: isSuccess,
        actionResult: actionResult,
      );

      var activationRecord = ActivationRecord(
        runId: Uuid().v4(),
        timestamp: DateTime.now(),
        executionTime: stopWatch.elapsed,
        ruleResult: ruleResult,
        facts: context.getFacts(),
      );

      _notify(activationRecord);
    }

    return actionResult.shouldContinue;
  }

  bool _runCondition(
      ConditionDefinition conditionDefinition, RuleContext context) {
    var condition =
        _conditionRepository.findCondition(conditionDefinition.operator);
    if (condition == null) {
      throw RuleEngineException(
          'Condition is not registered - ${conditionDefinition.operator}');
    }
    return condition.evaluate(conditionDefinition.operands, context);
  }

  Future<ActionResult> _runAction(
      ActionDefinition actionDefinition, RuleContext context) {
    var action = _actionRepository.findAction(actionDefinition.operation);
    if (action == null) {
      throw RuleEngineException(
          'Action is not registered - ${actionDefinition.operation}');
    }

    return action.execute(actionDefinition.parameters, context);
  }

  void _notify(ActivationRecord event) {
    if (!_eventBus.streamController.isClosed) {
      _eventBus.fire(event);
    }
  }
}
