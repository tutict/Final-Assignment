import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:flutter/cupertino.dart';

class ChangeMobilePhoneNumber extends StatefulWidget {
  const ChangeMobilePhoneNumber({super.key});

  @override
  State<ChangeMobilePhoneNumber> createState() =>
      _ChangeMobilePhoneNumberState();
}

class _ChangeMobilePhoneNumberState extends State<ChangeMobilePhoneNumber> {
  // 输入框控制器
  final _phoneController = TextEditingController();

  // 用于与后端交互
  late DriverInformationControllerApi driverApi;

  @override
  void initState() {
    super.initState();
    driverApi = DriverInformationControllerApi();
  }

  /// 调用后端接口更新手机号码
  /// 注意: 你当前的 put API 只允许传一个 int? updateValue
  /// 如果想真正更新手机号码，需要后端支持
  Future<void> _updatePhoneNumber() async {
    final newPhone = _phoneController.text.trim();
    if (newPhone.isEmpty) {
      // 简单校验
      return;
    }
    try {
      // 这里演示使用 apiDriversDriverIdPut(...)
      // 你后端只接收 int? => updateValue，需要修改才能真正更新 phone
      // 暂时仅做演示
      await driverApi.apiDriversDriverIdPut(
        driverId: '123', // 示例写死
        updateValue: 999, // 示例
      );
      // 更新成功后返回
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showCupertinoDialog(
        context: context,
        builder: (_) =>
            CupertinoAlertDialog(
              title: const Text('错误'),
              content: Text('更新手机号码失败: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('确定'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('修改手机号码'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back),
        ),
        backgroundColor: CupertinoColors.systemBlue,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              CupertinoTextField(
                controller: _phoneController,
                placeholder: '请输入新的手机号码',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20.0),
              CupertinoButton.filled(
                onPressed: _updatePhoneNumber,
                child: const Text('提交'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
