import 'package:flutter/material.dart';
import 'package:trustydr/core/theme/patient_app_colors.dart';

/// Generic workflow-stage stepper -- Phase 2 of the TrustyDr Workflow &
/// Notification Platform (see NOTIFICATION_PLATFORM_PROGRESS.md at the
/// ecosystem root). Extracted and generalized from
/// pages/patient/referral_detail_page.dart's own `_StatusTimeline`/
/// `_TimelineRow` (same dot-and-connector visual, same done/active/pending
/// styling) so any workflow (Marketplace order, and later Prescription/Lab/
/// Appointment/B2B) can render its progress from a plain ordered stage list
/// plus the entity's current stage key -- no per-domain stepper widget.
///
/// A workflow's terminal NEGATIVE outcome (rejected/cancelled/delivery
/// failed) does not fit this linear happy-path stepper -- pass
/// [terminalLabel] instead of [currentStage] to render a single distinct
/// row for that case, rather than a confusing partial progress bar.
class WorkflowTimelineStep {
  final String key;
  final String label;
  const WorkflowTimelineStep({required this.key, required this.label});
}

class WorkflowTimeline extends StatelessWidget {
  const WorkflowTimeline({
    super.key,
    this.steps = const [],
    this.currentStage,
    this.terminalLabel,
  }) : assert(
          (currentStage == null) != (terminalLabel == null),
          'Provide exactly one of currentStage (happy-path stepper) or terminalLabel (terminal outcome row).',
        );

  /// The ordered happy-path stages (e.g. accepted -> preparing -> ...).
  final List<WorkflowTimelineStep> steps;

  /// The entity's current stage key, matched against [steps] to compute
  /// each row's done/active state. Mutually exclusive with [terminalLabel].
  final String? currentStage;

  /// A terminal, non-happy-path outcome (order rejected/cancelled/delivery
  /// failed) -- renders as one distinct row instead of the stepper.
  /// Mutually exclusive with [currentStage].
  final String? terminalLabel;

  @override
  Widget build(BuildContext context) {
    if (terminalLabel != null) {
      return _TimelineRow(
        label: terminalLabel!,
        done: false,
        active: false,
        isLast: true,
        isTerminalOutcome: true,
      );
    }

    final idx = steps.indexWhere((s) => s.key == currentStage);
    return Column(
      children: List.generate(steps.length, (i) {
        final done = idx >= 0 && i < idx;
        final active = i == idx;
        return _TimelineRow(
          label: steps[i].label,
          done: done,
          active: active,
          isLast: i == steps.length - 1,
        );
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.done,
    required this.active,
    required this.isLast,
    this.isTerminalOutcome = false,
  });

  final String label;
  final bool done;
  final bool active;
  final bool isLast;
  final bool isTerminalOutcome;

  @override
  Widget build(BuildContext context) {
    final color = isTerminalOutcome
        ? PatientAppColors.statusCancelled
        : done
            ? PatientAppColors.brandTeal
            : active
                ? PatientAppColors.brandIndigo
                : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          child: Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: done || active || isTerminalOutcome
                      ? color
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : isTerminalOutcome
                        ? const Icon(Icons.close, size: 12, color: Colors.white)
                        : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color:
                      done ? PatientAppColors.brandTeal : Colors.grey.shade200,
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: active || done || isTerminalOutcome
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: done || active || isTerminalOutcome
                  ? Colors.black87
                  : Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
