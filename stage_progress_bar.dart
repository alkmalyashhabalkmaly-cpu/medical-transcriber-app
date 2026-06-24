import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../models/transcription_job.dart';
import '../utils/constants.dart';

/// Visual four-stage pipeline progress bar shown during processing.
class StageProgressBar extends StatelessWidget {
  const StageProgressBar({super.key, required this.job});
  final TranscriptionJob job;

  static const _stages = [
    (JobStatus.parsingPptx,  'استخراج\nالشرائح',   Icons.slideshow_rounded),
    (JobStatus.transcribing, 'التفريغ\nالصوتي',     Icons.mic_rounded),
    (JobStatus.refining,     'التحرير\nالأكاديمي',  Icons.auto_fix_high_rounded),
    (JobStatus.done,         'اكتمل',               Icons.check_circle_rounded),
  ];

  int get _currentIndex {
    return switch (job.status) {
      JobStatus.pending       => -1,
      JobStatus.parsingPptx   => 0,
      JobStatus.transcribing  => 1,
      JobStatus.refining      => 2,
      JobStatus.done          => 3,
      JobStatus.failed        => -1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentIndex;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            for (int i = 0; i < _stages.length; i++) ...[
              _StageNode(
                icon: _stages[i].$3,
                label: _stages[i].$2,
                state: i < current
                    ? _NodeState.done
                    : i == current
                        ? _NodeState.active
                        : _NodeState.pending,
              ),
              if (i < _stages.length - 1)
                Expanded(
                  child: _StageConnector(filled: i < current),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _NodeState { pending, active, done }

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.icon,
    required this.label,
    required this.state,
  });

  final IconData icon;
  final String label;
  final _NodeState state;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _NodeState.done    => AppColors.success,
      _NodeState.active  => AppColors.teal,
      _NodeState.pending => AppColors.textMuted,
    };

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(state == _NodeState.pending ? 0.2 : 0.6),
                width: 2,
              ),
            ),
            child: Icon(
              state == _NodeState.done ? Icons.check_rounded : icon,
              color: color,
              size: 18,
            ),
          ),
          const Gap(6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: state == _NodeState.active
                  ? FontWeight.w700
                  : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageConnector extends StatelessWidget {
  const _StageConnector({required this.filled});
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: filled ? AppColors.success : const Color(0xFF243447),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
