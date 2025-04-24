import 'package:final_assignment_front/features/dashboard/views/manager_screens/manager_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/api/role_management_controller_api.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/role_management.dart';
import 'package:final_assignment_front/features/dashboard/views/user_screens/user_dashboard.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  final RoleManagementControllerApi roleApi = RoleManagementControllerApi();
  final List<UserManagement> _userList = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchType = 'username'; // Default search type
  String? _currentUsername;
  bool _isAdmin = false;
  List<RoleManagement> _roles = [];

  final DashboardController controller =
      Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('jwtToken');
      if (jwtToken == null) throw Exception('未找到 JWT，请重新登录');
      final decodedToken = JwtDecoder.decode(jwtToken);
      _currentUsername = decodedToken['sub'] ?? '';
      if (_currentUsername!.isEmpty) throw Exception('JWT 中未找到用户名');
      debugPrint('Current username from JWT: $_currentUsername');

      await userApi.initializeWithJwt();
      await roleApi.initializeWithJwt();

      // Fetch roles for potential role display
      _roles = await roleApi.apiRolesGet();
      debugPrint('Roles fetched: ${_roles.map((r) => r.toJson()).toList()}');

      await _fetchUsers(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = '初始化失败: $e';
      });
    } finally {
      if (_isAdmin) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers({bool reset = false, String? query}) async {
    if (!_isAdmin) return;
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _userList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    debugPrint(
        'Fetching users with query: $searchQuery, page: $_currentPage, searchType: $_searchType');

    try {
      List<UserManagement> users = [];
      if (searchQuery.isEmpty) {
        debugPrint('Fetching all users for page: $_currentPage');
        users = await userApi.apiUsersGet();
      } else if (_searchType == 'username') {
        debugPrint('Fetching user by username: $searchQuery');
        final user =
            await userApi.apiUsersUsernameUsernameGet(username: searchQuery);
        users = user != null ? [user] : [];
      } else if (_searchType == 'status') {
        debugPrint('Fetching users by status: $searchQuery');
        users = await userApi.apiUsersStatusStatusGet(status: searchQuery);
      } else if (_searchType == 'contactNumber') {
        debugPrint('Fetching users by contactNumber: $searchQuery');
        users = await userApi.apiUsersGet(); // Placeholder: Filter client-side
        users = users
            .where((u) => u.contactNumber?.contains(searchQuery) ?? false)
            .toList();
      } else if (_searchType == 'email') {
        debugPrint('Fetching users by email: $searchQuery');
        users = await userApi.apiUsersGet(); // Placeholder: Filter client-side
        users = users
            .where((u) => u.email?.contains(searchQuery) ?? false)
            .toList();
      }

      debugPrint('Users fetched: ${users.map((u) => u.toJson()).toList()}');
      setState(() {
        _userList.addAll(users);
        if (users.length < _pageSize) _hasMore = false;
        if (_userList.isEmpty && _currentPage == 1) {
          _errorMessage = searchQuery.isNotEmpty ? '未找到符合条件的用户' : '当前没有用户记录';
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('404')) {
          _userList.clear();
          _errorMessage = '未找到符合条件的用户';
          _hasMore = false;
        } else {
          _errorMessage =
              e.toString().contains('403') ? '未授权，请重新登录' : '获取用户失败: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (_searchType == 'username') {
        debugPrint('Fetching username suggestions with prefix: $prefix');
        return [
          'admin',
          'user',
          'test'
        ]; // Placeholder: Replace with actual API
      } else if (_searchType == 'status') {
        debugPrint('Fetching status suggestions with prefix: $prefix');
        return ['ACTIVE', 'INACTIVE', 'SUSPENDED'];
      } else if (_searchType == 'contactNumber') {
        debugPrint('Fetching contactNumber suggestions with prefix: $prefix');
        return ['1234567890', '0987654321']; // Placeholder
      } else {
        debugPrint('Fetching email suggestions with prefix: $prefix');
        return ['user@example.com', 'admin@example.com']; // Placeholder
      }
    } catch (e) {
      debugPrint('Failed to fetch autocomplete suggestions: $e');
      return [];
    }
  }

  Future<void> _loadMoreUsers() async {
    if (!_hasMore || _isLoading) return;
    _currentPage++;
    await _fetchUsers(query: _searchController.text);
  }

  Future<void> _refreshUsers() async {
    _searchController.clear();
    await _fetchUsers(reset: true);
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    await _fetchUsers(reset: true, query: query);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final contactNumberController = TextEditingController();
    final emailController = TextEditingController();
    final remarksController = TextEditingController();
    String? selectedStatus = 'ACTIVE';
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = const Uuid().v4();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          title: Text('创建新用户', style: themeData.textTheme.titleLarge),
          backgroundColor: themeData.colorScheme.surfaceContainer,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: '用户名',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) => value!.isEmpty ? '用户名不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: '密码',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    obscureText: true,
                    validator: (value) => value!.isEmpty ? '密码不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactNumberController,
                    decoration: InputDecoration(
                      labelText: '联系电话',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: '邮箱',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isNotEmpty &&
                          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: '状态',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    items: ['ACTIVE', 'INACTIVE', 'SUSPENDED']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) => selectedStatus = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: '备注',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消',
                  style: TextStyle(color: themeData.colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final newUser = UserManagement(
                      userId: 0,
                      // Backend assigns userId
                      username: usernameController.text,
                      password: passwordController.text,
                      contactNumber: contactNumberController.text.isEmpty
                          ? null
                          : contactNumberController.text,
                      email: emailController.text.isEmpty
                          ? null
                          : emailController.text,
                      status: selectedStatus,
                      remarks: remarksController.text.isEmpty
                          ? null
                          : remarksController.text,
                      idempotencyKey: idempotencyKey,
                    );
                    await userApi.apiUsersPost(userManagement: newUser);
                    _showSnackBar('用户创建成功');
                    Navigator.pop(context);
                    await _refreshUsers();
                  } catch (e) {
                    _showSnackBar('创建用户失败: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
              ),
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditUserDialog(UserManagement user) async {
    final usernameController = TextEditingController(text: user.username);
    final contactNumberController =
        TextEditingController(text: user.contactNumber);
    final emailController = TextEditingController(text: user.email);
    final remarksController = TextEditingController(text: user.remarks);
    String? selectedStatus = user.status;
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = const Uuid().v4();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          title: Text('编辑用户', style: themeData.textTheme.titleLarge),
          backgroundColor: themeData.colorScheme.surfaceContainer,
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: usernameController,
                    decoration: InputDecoration(
                      labelText: '用户名',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    validator: (value) => value!.isEmpty ? '用户名不能为空' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactNumberController,
                    decoration: InputDecoration(
                      labelText: '联系电话',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: '邮箱',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value!.isNotEmpty &&
                          !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: '状态',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    items: ['ACTIVE', 'INACTIVE', 'SUSPENDED']
                        .map((status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ))
                        .toList(),
                    onChanged: (value) => selectedStatus = value,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: remarksController,
                    decoration: InputDecoration(
                      labelText: '备注',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消',
                  style: TextStyle(color: themeData.colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final updatedUser = UserManagement(
                      userId: user.userId,
                      username: usernameController.text,
                      contactNumber: contactNumberController.text.isEmpty
                          ? null
                          : contactNumberController.text,
                      email: emailController.text.isEmpty
                          ? null
                          : emailController.text,
                      status: selectedStatus,
                      remarks: remarksController.text.isEmpty
                          ? null
                          : remarksController.text,
                      idempotencyKey: idempotencyKey,
                    );
                    await userApi.apiUsersUserIdPut(
                      userId: user.userId.toString(),
                      userManagement: updatedUser,
                    );
                    _showSnackBar('用户更新成功');
                    Navigator.pop(context);
                    await _refreshUsers();
                  } catch (e) {
                    _showSnackBar('更新用户失败: $e', isError: true);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.primary,
                foregroundColor: themeData.colorScheme.onPrimary,
              ),
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除此用户吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消',
                style: TextStyle(
                    color:
                        controller.currentBodyTheme.value.colorScheme.error)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  controller.currentBodyTheme.value.colorScheme.error,
              foregroundColor:
                  controller.currentBodyTheme.value.colorScheme.onError,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await userApi.apiUsersUserIdDelete(userId: userId);
        _showSnackBar('用户删除成功');
        await _refreshUsers();
      } catch (e) {
        _showSnackBar('删除用户失败: $e', isError: true);
      }
    }
  }

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return await _fetchAutocompleteSuggestions(
                    textEditingValue.text);
              },
              onSelected: (String selection) {
                _searchController.text = selection;
                _searchUsers();
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                _searchController.text = controller.text;
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: _searchType == 'username'
                        ? '搜索用户名'
                        : _searchType == 'status'
                            ? '搜索状态'
                            : _searchType == 'contactNumber'
                                ? '搜索联系电话'
                                : '搜索邮箱',
                    hintStyle: TextStyle(
                        color:
                            themeData.colorScheme.onSurface.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search,
                        color: themeData.colorScheme.primary),
                    suffixIcon: controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                color: themeData.colorScheme.onSurfaceVariant),
                            onPressed: () {
                              controller.clear();
                              _searchController.clear();
                              _fetchUsers(reset: true);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0)),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color:
                              themeData.colorScheme.outline.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: themeData.colorScheme.primary, width: 1.5),
                    ),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainerLowest,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 16.0),
                  ),
                  onSubmitted: (value) => _searchUsers(),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _searchType,
            onChanged: (String? newValue) {
              setState(() {
                _searchType = newValue!;
                _searchController.clear();
                _fetchUsers(reset: true);
              });
            },
            items: <String>['username', 'status', 'contactNumber', 'email']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value == 'username'
                      ? '按用户名'
                      : value == 'status'
                          ? '按状态'
                          : value == 'contactNumber'
                              ? '按联系电话'
                              : '按邮箱',
                  style: TextStyle(color: themeData.colorScheme.onSurface),
                ),
              );
            }).toList(),
            dropdownColor: themeData.colorScheme.surfaceContainer,
            icon: Icon(Icons.arrow_drop_down,
                color: themeData.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = controller.currentBodyTheme.value;

    return Scaffold(
      backgroundColor: themeData.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '用户管理',
          style: themeData.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: themeData.colorScheme.onPrimaryContainer,
          ),
        ),
        backgroundColor: themeData.colorScheme.primaryContainer,
        foregroundColor: themeData.colorScheme.onPrimaryContainer,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
            tooltip: '刷新用户列表',
          ),
          IconButton(
            icon: Icon(themeData.brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode),
            onPressed: controller.toggleBodyTheme,
            tooltip: '切换主题',
          ),
        ],
      ),
      floatingActionButton: _isAdmin
          ? FloatingActionButton(
              onPressed: _showCreateUserDialog,
              backgroundColor: themeData.colorScheme.primary,
              child: Icon(Icons.add, color: themeData.colorScheme.onPrimary),
              tooltip: '创建新用户',
            )
          : null,
      body: RefreshIndicator(
        onRefresh: _refreshUsers,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (_isAdmin) _buildSearchField(themeData),
              const SizedBox(height: 12),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollInfo) {
                    if (scrollInfo.metrics.pixels ==
                            scrollInfo.metrics.maxScrollExtent &&
                        _hasMore &&
                        _isAdmin) {
                      _loadMoreUsers();
                    }
                    return false;
                  },
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(
                                  themeData.colorScheme.primary)))
                      : _errorMessage.isNotEmpty && _userList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _errorMessage,
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                      color: themeData.colorScheme.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_errorMessage.contains('未授权') ||
                                      _errorMessage.contains('仅管理员'))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pushReplacementNamed(
                                                context, '/login'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              themeData.colorScheme.primary,
                                          foregroundColor:
                                              themeData.colorScheme.onPrimary,
                                        ),
                                        child: const Text('重新登录'),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _userList.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _userList.length && _hasMore) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final user = _userList[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  elevation: 3,
                                  color: themeData.colorScheme.surfaceContainer,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16.0)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    title: Text(
                                      '用户名: ${user.username ?? '未知用户'}',
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData.colorScheme.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '状态: ${user.status ?? '未知状态'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '联系电话: ${user.contactNumber ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '邮箱: ${user.email ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '创建时间: ${user.createdTime?.toString() ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '修改时间: ${user.modifiedTime?.toString() ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '备注: ${user.remarks ?? '无'}',
                                          style: themeData.textTheme.bodyMedium
                                              ?.copyWith(
                                            color: themeData
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: _isAdmin
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: themeData
                                                        .colorScheme.primary),
                                                onPressed: () =>
                                                    _showEditUserDialog(user),
                                                tooltip: '编辑用户',
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: themeData
                                                        .colorScheme.error),
                                                onPressed: () => _deleteUser(
                                                    user.userId.toString()),
                                                tooltip: '删除用户',
                                              ),
                                            ],
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
