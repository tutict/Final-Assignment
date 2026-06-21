// ignore_for_file: use_build_context_synchronously

import 'package:final_assignment_front/core/auth/user_profile_service.dart';
import 'package:final_assignment_front/core/network/app_exception.dart';
import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/user_dashboard_screen_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/user/widgets/user_page_app_bar.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/utils/services/api_client.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';
import 'package:final_assignment_front/utils/ui/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

String generateIdempotencyKey() =>
    DateTime.now().microsecondsSinceEpoch.toString();

class PersonalMainPage extends StatefulWidget {
  const PersonalMainPage({super.key});

  @override
  State<PersonalMainPage> createState() => _PersonalMainPageState();
}

class _PersonalMainPageState extends State<PersonalMainPage> {
  final UserDashboardController dashboardController =
      Get.find<UserDashboardController>();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final ApiClient apiClient = ApiClient();

  final _scrollController = ScrollController();
  final _editController = TextEditingController();

  DriverInformation? _driverInfo;
  int? _driverId;
  String _displayName = '';
  String _email = '';
  String _phoneNumber = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final jwtToken = await AuthTokenStore.instance.getJwtToken();
      if (jwtToken == null || jwtToken.isEmpty) {
        throw Exception('未登录，请重新登录');
      }

      final profile = await Get.find<UserProfileService>().getProfile();
      final driverId = profile.driverId;

      _driverId = driverId;
      _displayName =
          profile.driverName ?? profile.displayName ?? profile.username;
      _email = profile.email ?? '';
      _phoneNumber = profile.phoneNumber ?? '';

      if (driverId == null) {
        setState(() {
          _driverInfo = null;
          _isLoading = false;
          _errorMessage = '当前账号尚未关联驾驶员档案';
        });
        dashboardController.updateCurrentUser(_displayName, _email);
        return;
      }

      await driverApi.initializeWithJwt();
      final driverInfo = await driverApi.getDriver(driverId: driverId);

      setState(() {
        _driverInfo = driverInfo;
        _displayName = driverInfo?.name ?? _displayName;
        _phoneNumber = driverInfo?.contactNumber ?? _phoneNumber;
        _isLoading = false;
      });

      dashboardController.updateCurrentUser(_displayName, _email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driverId', driverId.toString());
      await prefs.setString('driver_id', driverId.toString());
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = _formatErrorMessage(error);
      });
    }
  }

  Future<void> _updateField(String field, String value) async {
    final driverId = _driverId;
    final current = _driverInfo;
    if (driverId == null || current == null) {
      AppSnackbar.showError(context, message: '当前账号尚未关联驾驶员档案');
      return;
    }

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      AppSnackbar.showError(context, message: '内容不能为空');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedDriver = _updatedDriverPayload(current, field, trimmed);
      await driverApi.updateDriver(
        driverId: driverId,
        driverInformation: updatedDriver,
        idempotencyKey: generateIdempotencyKey(),
      );

      Get.find<UserProfileService>().invalidate();
      await _loadCurrentUser();
      AppSnackbar.showSuccess(context, message: '资料已更新');
    } catch (error) {
      AppSnackbar.showError(context, message: _formatErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  DriverInformation _updatedDriverPayload(
    DriverInformation current,
    String field,
    String value,
  ) {
    return DriverInformation(
      driverId: current.driverId,
      authUserId: current.authUserId,
      name: field == 'name' ? value : current.name,
      idCardNumber: field == 'idCardNumber' ? value : current.idCardNumber,
      gender: current.gender,
      birthdate: current.birthdate,
      contactNumber: field == 'contactNumber' ? value : current.contactNumber,
      email: current.email,
      address: current.address,
      driverLicenseNumber:
          field == 'driverLicenseNumber' ? value : current.driverLicenseNumber,
      licenseType: current.licenseType ?? current.allowedVehicleType,
      allowedVehicleType: current.allowedVehicleType ?? current.licenseType,
      firstLicenseDate: current.firstLicenseDate,
      issueDate: current.issueDate,
      expiryDate: current.expiryDate,
      issuingAuthority: current.issuingAuthority,
      currentPoints: current.currentPoints,
      totalDeductedPoints: current.totalDeductedPoints,
      status: current.status,
      createdAt: current.createdAt,
      updatedAt: current.updatedAt,
      createdBy: current.createdBy,
      updatedBy: current.updatedBy,
      deletedAt: current.deletedAt,
      remarks: current.remarks,
    );
  }

  String _formatErrorMessage(dynamic error) {
    if (error is AppException) {
      return switch (error.type) {
        AppErrorType.unauthorized => '登录已失效，请重新登录',
        AppErrorType.forbidden => '权限不足，无法访问该驾驶员档案',
        AppErrorType.notFound => '未找到驾驶员档案',
        AppErrorType.network => '网络请求失败，请检查后端服务',
        AppErrorType.timeout => '请求超时，请稍后重试',
        AppErrorType.serverError => '服务器处理失败，请稍后重试',
        _ => error.message,
      };
    }
    final text = error.toString();
    if (text.contains('Internal server error')) {
      return '服务器处理失败，请稍后重试';
    }
    if (text.startsWith('Exception: ')) {
      return text.substring('Exception: '.length);
    }
    return text;
  }

  Future<void> _showEditDialog({
    required String title,
    required String field,
    required String initialValue,
    TextInputType keyboardType = TextInputType.text,
  }) async {
    _editController.text = initialValue;
    final theme = Theme.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text('编辑$title'),
          content: TextField(
            controller: _editController,
            keyboardType: keyboardType,
            autofocus: true,
            style: TextStyle(color: theme.colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: title,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.42),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final value = _editController.text;
                Navigator.of(context).pop();
                _updateField(field, value);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final theme = dashboardController.currentBodyTheme.value;

      return Theme(
        data: theme,
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: UserPageAppBar(
            theme: theme,
            title: '个人资料',
          ),
          body: Stack(
            children: [
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_errorMessage.isNotEmpty)
                _ProfileErrorState(
                  message: _errorMessage,
                  onRetry: _loadCurrentUser,
                )
              else
                _buildContent(theme),
              if (_isSaving)
                Positioned.fill(
                  child: ColoredBox(
                    color: theme.colorScheme.scrim.withValues(alpha: 0.18),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildContent(ThemeData theme) {
    final driver = _driverInfo;
    final points = driver?.currentPoints;
    final deducted = driver?.totalDeductedPoints;

    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        children: [
          _ProfileSummary(
            name: _displayName,
            email: _email,
            driverLicenseNumber: driver?.driverLicenseNumber,
            currentPoints: points,
            status: _statusLabel(driver?.status),
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: '身份信息',
            children: [
              _ProfileFieldTile(
                icon: Icons.badge_outlined,
                label: '姓名',
                value: driver?.name ?? _displayName,
                onTap: () => _showEditDialog(
                  title: '姓名',
                  field: 'name',
                  initialValue: driver?.name ?? _displayName,
                ),
              ),
              _ProfileFieldTile(
                icon: Icons.credit_card_outlined,
                label: '身份证号码',
                value: driver?.idCardNumber,
                onTap: () => _showEditDialog(
                  title: '身份证号码',
                  field: 'idCardNumber',
                  initialValue: driver?.idCardNumber ?? '',
                  keyboardType: TextInputType.text,
                ),
              ),
              _ProfileFieldTile(
                icon: Icons.phone_outlined,
                label: '联系电话',
                value: driver?.contactNumber ?? _phoneNumber,
                onTap: () => _showEditDialog(
                  title: '联系电话',
                  field: 'contactNumber',
                  initialValue: driver?.contactNumber ?? _phoneNumber,
                  keyboardType: TextInputType.phone,
                ),
              ),
              _ProfileFieldTile(
                icon: Icons.alternate_email_rounded,
                label: '邮箱',
                value: driver?.email ?? _email,
                editable: false,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ProfileSection(
            title: '驾驶证信息',
            children: [
              _ProfileFieldTile(
                icon: Icons.assignment_ind_outlined,
                label: '驾驶证号',
                value: driver?.driverLicenseNumber,
                onTap: () => _showEditDialog(
                  title: '驾驶证号',
                  field: 'driverLicenseNumber',
                  initialValue: driver?.driverLicenseNumber ?? '',
                ),
              ),
              _ProfileFieldTile(
                icon: Icons.directions_car_outlined,
                label: '准驾车型',
                value: driver?.licenseType ?? driver?.allowedVehicleType,
                editable: false,
              ),
              _ProfileFieldTile(
                icon: Icons.event_available_outlined,
                label: '初次领证日期',
                value: _formatDate(driver?.firstLicenseDate),
                editable: false,
              ),
              _ProfileFieldTile(
                icon: Icons.verified_user_outlined,
                label: '发证机关',
                value: driver?.issuingAuthority,
                editable: false,
              ),
              _ProfileFieldTile(
                icon: Icons.timeline_outlined,
                label: '累计扣分',
                value: deducted == null ? null : '$deducted 分',
                editable: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? status) {
    return switch (status) {
      'Active' => '正常',
      'Suspended' => '暂扣',
      'Revoked' => '吊销',
      'Expired' => '过期',
      _ => status?.isNotEmpty == true ? status! : '未知',
    };
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({
    required this.name,
    required this.email,
    required this.driverLicenseNumber,
    required this.currentPoints,
    required this.status,
  });

  final String name;
  final String email;
  final String? driverLicenseNumber;
  final int? currentPoints;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = MediaQuery.of(context).size.width < 720;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: scheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  color: scheme.onPrimaryContainer,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email.isEmpty ? '未填写邮箱' : email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(width: compact ? 0 : 24, height: compact ? 18 : 0),
          if (compact)
            _buildPills(context, WrapAlignment.start)
          else
            Expanded(child: _buildPills(context, WrapAlignment.end)),
        ],
      ),
    );
  }

  Widget _buildPills(BuildContext context, WrapAlignment alignment) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: alignment,
      children: [
        _SummaryPill(
          label: '驾驶证号',
          value: driverLicenseNumber?.isNotEmpty == true
              ? driverLicenseNumber!
              : '未填写',
        ),
        _SummaryPill(
          label: '当前积分',
          value: currentPoints == null ? '未知' : '$currentPoints 分',
        ),
        _SummaryPill(label: '状态', value: status),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          Divider(
              height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ...children,
        ],
      ),
    );
  }
}

class _ProfileFieldTile extends StatelessWidget {
  const _ProfileFieldTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.editable = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final resolvedValue =
        value?.trim().isNotEmpty == true ? value!.trim() : '未填写';

    return InkWell(
      onTap: editable ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: scheme.primary, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    resolvedValue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (editable)
              Icon(
                Icons.edit_outlined,
                color: scheme.onSurfaceVariant,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileErrorState extends StatelessWidget {
  const _ProfileErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: scheme.error,
              size: 44,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}
