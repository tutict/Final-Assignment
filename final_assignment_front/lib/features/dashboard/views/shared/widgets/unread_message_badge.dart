import 'package:final_assignment_front/core/theme/app_colors.dart';
import 'package:final_assignment_front/features/api/progress_item_controller_api.dart';
import 'package:final_assignment_front/features/model/progress_item.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('userName') ?? '';
      final rows = username.isEmpty
          ? await api.listProgressItems()
          : await api.listProgressItemsByUsername(username: username);
      if (!mounted) return;
      setState(() => _count = rows.where((row) => ProgressItem.isOpenStatus(row.status)).length);
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
