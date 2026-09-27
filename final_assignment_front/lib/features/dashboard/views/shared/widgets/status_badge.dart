import 'package:final_assignment_front/core/theme/app_colors.dart';
import 'package:final_assignment_front/utils/helpers/app_helpers.dart';
import 'package:flutter/material.dart';

/// 语义化状态色调。映射到 [AppColors] 里的交通执法语义色，
/// 使状态徽章与当前主题（浅/深）保持一致，而非硬编码 Material 色。
enum StatusTone { neutral, info, success, warning, danger }

/// 交通违法系统的统一状态徽章。
///
/// 用于"待处理 / 处理中 / 已完成 / 已驳回"等状态列，替代散落各处的
/// 硬编码 `Container`/`Chip`。颜色从 `Theme.of(context).extension<AppColors>()`
/// 读取，天然支持深浅主题。
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  /// 由 [OffenseProcessStatus] 派生语义徽章。
  factory StatusBadge.offenseProcess(OffenseProcessStatus status,
      {bool dense = false}) {
    return StatusBadge(
      label: status.label,
      tone: _toneForOffenseProcess(status),
      icon: _iconForOffenseProcess(status),
      dense: dense,
    );
  }

  /// 由 [AppealAcceptanceStatus] 派生语义徽章。
  factory StatusBadge.appealAcceptance(AppealAcceptanceStatus status,
      {bool dense = false}) {
    return StatusBadge(
      label: status.label,
      tone: _toneForAppealAcceptance(status),
      icon: _iconForAppealAcceptance(status),
      dense: dense,
    );
  }

  /// 由 [AppealProcessStatus] 派生语义徽章。
  factory StatusBadge.appealProcess(AppealProcessStatus status,
      {bool dense = false}) {
    return StatusBadge(
      label: status.label,
      tone: _toneForAppealProcess(status),
      icon: _iconForAppealProcess(status),
      dense: dense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light;
    final (fg, bg) = _resolve(colors);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(icon, size: dense ? 12 : 14, color: fg),
            ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ).copyWith(color: fg),
          ),
        ],
      ),
    );
  }

  (Color, Color) _resolve(AppColors colors) {
    switch (tone) {
      case StatusTone.info:
        return (colors.info, colors.infoBackground);
      case StatusTone.success:
        return (colors.success, colors.successBackground);
      case StatusTone.warning:
        return (colors.warning, colors.warningBackground);
      case StatusTone.danger:
        return (colors.danger, colors.dangerBackground);
      case StatusTone.neutral:
        return (colors.info, colors.infoBackground);
    }
  }

  static StatusTone _toneForOffenseProcess(OffenseProcessStatus status) {
    switch (status) {
      case OffenseProcessStatus.unprocessed:
        return StatusTone.warning;
      case OffenseProcessStatus.processing:
        return StatusTone.info;
      case OffenseProcessStatus.processed:
      case OffenseProcessStatus.appealApproved:
        return StatusTone.success;
      case OffenseProcessStatus.appealing:
        return StatusTone.info;
      case OffenseProcessStatus.appealRejected:
        return StatusTone.danger;
      case OffenseProcessStatus.cancelled:
      case OffenseProcessStatus.unknown:
        return StatusTone.neutral;
    }
  }

  static IconData? _iconForOffenseProcess(OffenseProcessStatus status) {
    switch (status) {
      case OffenseProcessStatus.unprocessed:
        return Icons.schedule;
      case OffenseProcessStatus.processing:
        return Icons.autorenew;
      case OffenseProcessStatus.processed:
        return Icons.check_circle;
      case OffenseProcessStatus.appealing:
        return Icons.help_outline;
      case OffenseProcessStatus.appealApproved:
        return Icons.task_alt;
      case OffenseProcessStatus.appealRejected:
        return Icons.block;
      case OffenseProcessStatus.cancelled:
        return Icons.cancel_outlined;
      case OffenseProcessStatus.unknown:
        return null;
    }
  }

  static IconData _iconForAppealAcceptance(AppealAcceptanceStatus status) {
    switch (status) {
      case AppealAcceptanceStatus.pending:
        return Icons.schedule;
      case AppealAcceptanceStatus.accepted:
        return Icons.check_circle;
      case AppealAcceptanceStatus.rejected:
        return Icons.block;
      case AppealAcceptanceStatus.needSupplement:
        return Icons.info_outline;
    }
  }

  static IconData _iconForAppealProcess(AppealProcessStatus status) {
    switch (status) {
      case AppealProcessStatus.unprocessed:
        return Icons.schedule;
      case AppealProcessStatus.underReview:
        return Icons.autorenew;
      case AppealProcessStatus.approved:
        return Icons.task_alt;
      case AppealProcessStatus.rejected:
        return Icons.block;
      case AppealProcessStatus.withdrawn:
        return Icons.undo;
      case AppealProcessStatus.unknown:
        return Icons.help_outline;
    }
  }

  static StatusTone _toneForAppealAcceptance(AppealAcceptanceStatus status) {
    switch (status) {
      case AppealAcceptanceStatus.pending:
        return StatusTone.warning;
      case AppealAcceptanceStatus.accepted:
        return StatusTone.success;
      case AppealAcceptanceStatus.rejected:
        return StatusTone.danger;
      case AppealAcceptanceStatus.needSupplement:
        return StatusTone.info;
    }
  }

  static StatusTone _toneForAppealProcess(AppealProcessStatus status) {
    switch (status) {
      case AppealProcessStatus.unprocessed:
        return StatusTone.warning;
      case AppealProcessStatus.underReview:
        return StatusTone.info;
      case AppealProcessStatus.approved:
        return StatusTone.success;
      case AppealProcessStatus.rejected:
        return StatusTone.danger;
      case AppealProcessStatus.withdrawn:
        return StatusTone.warning;
      case AppealProcessStatus.unknown:
        return StatusTone.neutral;
    }
  }
}