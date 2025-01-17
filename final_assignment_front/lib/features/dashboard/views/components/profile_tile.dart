part of '../manager_screens/manager_dashboard_screen.dart';

class _ProfilTile extends StatelessWidget {
  const _ProfilTile({required this.data, required this.onPressedNotification});

  final _Profile data;
  final Function() onPressedNotification;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(0),
      leading: CircleAvatar(backgroundImage: data.photo),
      title: Text(
        data.name,
        style: TextStyle(fontSize: 14, color: kFontColorPallets[0])
            .useSystemChineseFont(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        data.email,
        style: TextStyle(fontSize: 12, color: kFontColorPallets[2])
            .useSystemChineseFont(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        onPressed: onPressedNotification,
        icon: const Icon(EvaIcons.bellOutline),
        tooltip: "notification",
      ),
    );
  }
}
