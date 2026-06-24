import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../utils/constants.dart';

/// A tappable drop zone card that shows accepted file info once selected.
class FileDropZone extends StatefulWidget {
  const FileDropZone({
    super.key,
    required this.icon,
    required this.label,
    required this.hint,
    required this.accentColor,
    required this.onTap,
    this.acceptedFile,
  });

  final IconData icon;
  final String label;
  final String hint;
  final Color accentColor;
  final VoidCallback onTap;
  final PlatformFile? acceptedFile;

  @override
  State<FileDropZone> createState() => _FileDropZoneState();
}

class _FileDropZoneState extends State<FileDropZone> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasFile  = widget.acceptedFile != null;
    final accent   = widget.accentColor;
    final borderColor = hasFile
        ? accent
        : _hovered
            ? accent.withOpacity(0.6)
            : const Color(0xFF243447);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: hasFile
                ? accent.withOpacity(0.07)
                : _hovered
                    ? AppColors.ink.withOpacity(0.8)
                    : AppColors.ink,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: hasFile ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon blob
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasFile ? Icons.check_circle_rounded : widget.icon,
                  color: accent,
                  size: 26,
                ),
              ).animate(target: hasFile ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.08, 1.08),
                duration: 300.ms,
              ),

              const Gap(16),

              // Text area
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: hasFile ? accent : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      hasFile
                          ? widget.acceptedFile!.name
                          : widget.hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasFile ? accent.withOpacity(0.8) : AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFile && widget.acceptedFile!.size > 0) ...[
                      const Gap(2),
                      Text(
                        _formatBytes(widget.acceptedFile!.size),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // CTA / change
              Text(
                hasFile ? 'تغيير' : 'اختر ملفاً',
                style: TextStyle(
                  fontSize: 13,
                  color: accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}
