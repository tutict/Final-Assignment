// part 指令表示此文件是 'ui_utils.dart' 库的一部分。
// 使用相同 part 指令的文件可以一起编译为一个整体。
part of 'ui_utils.dart';

// AppBottomSheet 类用于包含应用中所有底部弹出层（Bottom Sheet）的模板。
// 该类通过集中管理所有与底部弹出层相关的逻辑和UI，促进代码的复用性和可维护性。
class AppBottomSheet {
  static Future<T?> showOptionsSheet<T>({
    required BuildContext context,
    required List<Widget> options,
    String? title,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                ),
              ...options,
            ],
          ),
        ),
      ),
    );
  }

  static Future<T?> showCustomContent<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: child,
      ),
    );
  }
}
