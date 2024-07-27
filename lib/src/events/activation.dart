import 'package:drules/drules.dart';

/// An event listener that listens for activation events.
///
/// The listener is called when a rule is activated.
typedef ActivationEventListener = void Function(ActivationRecord event);

/// Represents an activation event.
///
/// The event contains information about the rule that was activated,
/// the facts that triggered the rule, and the result of the rule.
class ActivationRecord {
  final String runId;
  final DateTime timestamp;
  final Duration executionTime;
  final RuleResult ruleResult;
  final Map<String, dynamic> facts;

  ActivationRecord({
    required this.runId,
    required this.timestamp,
    required this.executionTime,
    required this.ruleResult,
    required this.facts,
  });

  @override
  String toString() {
    return 'ActivationRecord: { runId: $runId, timestamp: $timestamp, '
        'executionTime: $executionTime, ruleResult: $ruleResult }';
  }
}
