import 'package:final_assignment_front/core/theme/app_colors.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:flutter/material.dart';

class UnreadMessageBadge extends StatefulWidget {
  const UnreadMessageBadge({super.key});

  @override
  State<UnreadMessageBadge> createState() => _UnreadMessageBadgeState();
}

class _UnreadMessageBadgeState extends State<UnreadMessageBadge> {
  int? _count;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = ProgressControllerApi();
      await api.initializeWithJwt();
      final rows = await api.listProgressItems();
      if (!mounted) return;
      setState(() => _count = rows.length);
    } catch (_) {
      if (!mounted) return;
      setState(() => _count = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _count;
    if (count == null || count <= 0) return const SizedBox.shrink();
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.light;
    final label = count > 99 ? '99+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colors.infoBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: colors.info,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
    );
  }
}
