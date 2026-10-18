import 'package:flutter/material.dart';
import '../models/candidate.dart';
import '../theme/app_theme.dart';

class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final VoidCallback onTap;
  final bool isSelected;
  final ValueChanged<bool?>? onCheckChanged;
  final bool showCheckbox;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onTap,
    this.isSelected = false,
    this.onCheckChanged,
    this.showCheckbox = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: isSelected ? 3 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppTheme.primaryColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order number circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${candidate.orderNo}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            candidate.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        _StatusBadge(status: candidate.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.badge_outlined,
                      text: 'เลขประจำตัวสอบ: ${candidate.examId}',
                    ),
                    const SizedBox(height: 2),
                    _InfoRow(
                      icon: Icons.work_outline,
                      text: candidate.position,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _InfoRow(
                          icon: Icons.location_on_outlined,
                          text: candidate.province == '-' ? candidate.region : candidate.province,
                        ),
                        const Spacer(),
                        if (candidate.score != '-' && candidate.score.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'คะแนน: ${candidate.score}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7B5800),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (showCheckbox) ...[
                const SizedBox(width: 8),
                Checkbox(
                  value: isSelected,
                  onChanged: onCheckChanged,
                  activeColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ] else
                const Icon(
                  Icons.chevron_right,
                  color: AppTheme.textHint,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  Color get _bgColor {
    if (status.contains('ผ่าน') && !status.contains('ไม่')) {
      return const Color(0xFFE8F5E9);
    } else if (status.contains('ไม่ผ่าน')) {
      return const Color(0xFFFFEBEE);
    }
    return const Color(0xFFE3F2FD);
  }

  Color get _textColor {
    if (status.contains('ผ่าน') && !status.contains('ไม่')) {
      return const Color(0xFF2E7D32);
    } else if (status.contains('ไม่ผ่าน')) {
      return const Color(0xFFC62828);
    }
    return const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _textColor,
        ),
      ),
    );
  }
}
