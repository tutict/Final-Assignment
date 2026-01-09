// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_routes.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/controllers/manager_dashboard_controller.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/api/user_management_controller_api.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';

import 'package:final_assignment_front/features/model/register_request.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

String generateIdempotencyKey() => const Uuid().v4();

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final TextEditingController _searchController = TextEditingController();
  final UserManagementControllerApi userApi = UserManagementControllerApi();
  final List<UserManagement> _userList = [];
  List<UserManagement>? _cachedAllUsers;
  final ScrollController _scrollController = ScrollController();
  final DashboardController controller = Get.find<DashboardController>();
  final Logger _logger = Logger('UserManagementPage');
  bool _isLoading = true;
  String _errorMessage = '';
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  String _searchType = 'username';
  String? _currentUsername;
  bool _isAdmin = false;
  Timer? _debounce;

  // Status mapping: English to Chinese
  static const Map<String, String> _statusDisplayMap = {
    'Active': '活跃',
    'Inactive': '禁用',
  };

  // Dropdown items for status
  static const List<Map<String, String>> _statusDropdownItems = [
    {'value': 'Active', 'label': '活跃'},
    {'value': 'Inactive', 'label': '禁用'},
  ];

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _searchUsers);
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
          _hasMore &&
          !_isLoading) {
        _loadMoreUsers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = '未授权，请重新登录');
      _logger.warning('No JWT token found');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = '登录已过期，请重新登录');
          _logger.warning('JWT token refresh failed');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = '新登录信息已过期，请重新登录');
          _logger.warning('Refreshed JWT token is expired');
          return false;
        }
        await userApi.initializeWithJwt();
      }
      _currentUsername = decodedToken['sub'] ?? '';
      _logger.info('JWT Token validated: sub=$_currentUsername');
      return true;
    } catch (e) {
      setState(() => _errorMessage = '无效的登录信息，请重新登录: $e');
      _logger.severe('JWT validation failed: $e', StackTrace.current);
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      _logger.warning('No refresh token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newJwt = data['jwtToken'];
        final newRefreshToken = data['refreshToken'];
        await AuthTokenStore.instance.setJwtToken(newJwt);
        if (newRefreshToken != null) {
          await prefs.setString('refreshToken', newRefreshToken);
        }
        _logger.info('JWT token refreshed successfully');
        return newJwt;
      }
      _logger.warning('Refresh token request failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      _logger.severe('Error refreshing JWT token: $e', StackTrace.current);
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return;
      }
      await userApi.initializeWithJwt();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      final roles = decodedToken['roles'] is List
          ? (decodedToken['roles'] as List).map((r) => r.toString()).toList()
          : decodedToken['roles'] is String
          ? [decodedToken['roles'].toString()]
          : [];
      _isAdmin = roles.contains('ADMIN') || roles.contains('ROLE_ADMIN');
      _logger.info('User roles: $roles, isAdmin: $_isAdmin');

      if (_isAdmin) {
        await _fetchUsers(reset: true);
      } else {
        setState(() => _errorMessage = '仅管理员可访问用户管理页面');
      }
    } catch (e) {
      setState(() => _errorMessage = '初始化失败: $e');
      _logger.severe('Initialization error: $e', StackTrace.current);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    try {
      _logger.info('Checking username availability: $username');
      await userApi.apiUsersUsernameUsernameGet(username: username);
      _logger.info('Username $username already exists');
      return false; // 用户存在
    } catch (e) {
      if (e is ApiException && e.code == 404) {
        _logger.info('Username $username is available');
        return true; // 用户不存在，可用
      }
      _logger.severe('Failed to check username availability: $e', StackTrace.current);
      rethrow; // 其他错误，抛出异常
    }
  }

  Future<void> _fetchUsers({bool reset = false, String? query}) async {
    if (!_isAdmin) {
      setState(() => _errorMessage = '仅管理员可访问用户管理页面');
      return;
    }
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _userList.clear();
      _cachedAllUsers = null;
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final searchQuery = query?.trim() ?? '';
    _logger.info('Fetching users: query=$searchQuery, page=$_currentPage, type=$_searchType');

    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return;
      }
      List<UserManagement> users = [];
      bool hasMoreResults = false;

      if (searchQuery.isEmpty) {
        final allUsers = await _loadAllUsers();
        final startIndex = (_currentPage - 1) * _pageSize;
        if (startIndex < allUsers.length) {
          final endIndex = startIndex + _pageSize;
          final actualEnd = endIndex > allUsers.length ? allUsers.length : endIndex;
          users = allUsers.sublist(startIndex, actualEnd);
          hasMoreResults = actualEnd < allUsers.length;
        } else {
          users = [];
          hasMoreResults = false;
        }
      } else if (_searchType == 'username') {
        final user = await userApi.apiUsersUsernameUsernameGet(username: searchQuery);
        users = user != null ? [user] : [];
      } else if (_searchType == 'status') {
        users = await userApi.apiUsersSearchStatusGet(
          status: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
        hasMoreResults = users.length == _pageSize;
      } else if (_searchType == 'department') {
        users = await userApi.apiUsersSearchDepartmentGet(
          department: searchQuery,
          page: _currentPage,
          size: _pageSize,
        );
        hasMoreResults = users.length == _pageSize;
      } else if (_searchType == 'contactNumber') {
        final allUsers = await _loadAllUsers();
        users = allUsers.where((u) => u.contactNumber?.contains(searchQuery) ?? false).toList();
      } else if (_searchType == 'email') {
        final allUsers = await _loadAllUsers();
        users = allUsers
            .where((u) => u.email?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false)
            .toList();
      }

      users = users.where((u) => u.username != _currentUsername).toList();

      setState(() {
        _userList.addAll(users);
        _hasMore = hasMoreResults;
        if (_userList.isEmpty && _currentPage == 1) {
          _errorMessage = searchQuery.isNotEmpty ? '未找到符合条件的用户' : '当前没有用户记录';
        }
        if (users.isNotEmpty) {
          _currentPage++;
        } else {
          _hasMore = false;
        }
      });
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          switch (e.code) {
            case 403:
              _errorMessage = '未授权，请重新登录';
              Get.offAllNamed(Routes.login);
              break;
            case 404:
              _errorMessage = '未找到符合条件的用户';
              _hasMore = false;
              break;
            default:
              _errorMessage = '获取用户失败: ${e.message}';
          }
        } else {
          _errorMessage = '获取用户失败: $e';
        }
      });
      _logger.severe('Fetch users error: $e', StackTrace.current);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return [];
      }
      final lowerPrefix = prefix.toLowerCase();
      if (_searchType == 'username') {
        final suggestions = await userApi.apiUsersAutocompleteUsernamesGet(prefix: prefix);
        return suggestions
            .where((s) => s.toLowerCase().contains(lowerPrefix))
            .take(5)
            .toList();
      }
      if (_searchType == 'status') {
        return _statusDropdownItems
            .map((item) => item['value'])
            .whereType<String>()
            .where((value) => value.toLowerCase().contains(lowerPrefix))
            .toList();
      }
      if (_searchType == 'contactNumber') {
        return await _buildLocalSuggestions(prefix, (user) => user.contactNumber);
      }
      if (_searchType == 'email') {
        return await _buildLocalSuggestions(prefix, (user) => user.email);
      }
      if (_searchType == 'department') {
        return await _buildLocalSuggestions(prefix, (user) => user.department);
      }
      return [];
    } catch (e) {
      _logger.severe('Failed to fetch autocomplete suggestions: $e', StackTrace.current);
      return [];
    }
  }

  Future<List<String>> _buildLocalSuggestions(
    String prefix,
    String? Function(UserManagement user) valueSelector,
  ) async {
    try {
      final records = await _loadAllUsers();
      final seen = <String>{};
      final lowerPrefix = prefix.toLowerCase();
      return records
          .map(valueSelector)
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .where((value) => value.toLowerCase().contains(lowerPrefix))
          .where((value) => seen.add(value))
          .take(5)
          .toList();
    } catch (e) {
      _logger.severe('Failed to build local suggestions: $e', StackTrace.current);
      return [];
    }
  }

  Future<List<UserManagement>> _loadAllUsers() async {
    if (_cachedAllUsers != null) {
      return _cachedAllUsers!;
    }
    final allUsers = await userApi.apiUsersGet();
    _cachedAllUsers = List<UserManagement>.from(allUsers);
    return _cachedAllUsers!;
  }

  Future<void> _loadMoreUsers() async {
    if (!_hasMore || _isLoading) return;
    await _fetchUsers(query: _searchController.text);
  }

  Future<void> _refreshUserList({String? query}) async {
    setState(() {
      _userList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _searchType = 'username';
      }
    });
    await _fetchUsers(reset: true, query: query);
  }

  Future<void> _searchUsers() async {
    final query = _searchController.text.trim();
    await _refreshUserList(query: query);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? themeData.colorScheme.onError : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError ? themeData.colorScheme.error : themeData.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        margin: const EdgeInsets.all(10.0),
      ),
    );
  }

  String _formatErrorMessage(dynamic error) {
    if (error is ApiException) {
      switch (error.code) {
        case 400:
          return '请求错误: ${error.message}';
        case 403:
          return '无权限: ${error.message}';
        case 404:
          return '未找到: ${error.message}';
        case 409:
          return '重复请求: ${error.message}';
        default:
          return '服务器错误: ${error.message}';
      }
    }
    return '操作失败: $error';
  }

  Future<void> _showCreateUserDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final contactNumberController = TextEditingController();
    final emailController = TextEditingController();
    final remarksController = TextEditingController();
    String? selectedStatus = 'Active';
    String? selectedRole = 'USER';
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = generateIdempotencyKey();
    final authApi = AuthControllerApi();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return Theme(
          data: themeData,
          child: AlertDialog(
            title: Text('创建新用户', style: themeData.textTheme.titleLarge),
            backgroundColor: themeData.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: '账号',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '账号不能为空';
                        if (value.length > 50) return '账号不能超过50个字符';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      obscureText: true,
                      maxLength: 255,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '密码不能为空';
                        if (value.length > 255) return '密码不能超过255个字符';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberController,
                      decoration: InputDecoration(
                        labelText: '联系电话',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length > 20) {
                          return '联系电话不能超过20个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length > 100) return '邮箱不能超过100个字符';
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return '请输入有效的邮箱地址';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: '状态',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      items: _statusDropdownItems
                          .map((item) => DropdownMenuItem(
                        value: item['value'],
                        child: Text(item['label']!),
                      ))
                          .toList(),
                      onChanged: (value) => selectedStatus = value,
                      validator: (value) => value == null ? '请选择状态' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: InputDecoration(
                        labelText: '角色',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      items: ['USER', 'ADMIN']
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(),
                      onChanged: (value) => selectedRole = value,
                      validator: (value) => value == null ? '请选择角色' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
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
                child: Text('取消', style: TextStyle(color: themeData.colorScheme.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!await _validateJwtToken()) {
                      Get.offAllNamed(Routes.login);
                      return;
                    }
                    final username = usernameController.text.trim();
                    try {
                      _logger.info('Checking username availability: $username');
                      final isUsernameAvailable = await _checkUsernameAvailability(username);
                      if (!isUsernameAvailable) {
                        _showSnackBar('账号已存在，请选择其他账号', isError: true);
                        return;
                      }
                      final registerRequest = RegisterRequest(
                        username: username,
                        password: passwordController.text,
                        idempotencyKey: idempotencyKey,
                      );
                      _logger.info('Registering user: $username, idempotencyKey: $idempotencyKey');
                      final response = await authApi.apiAuthRegisterPost(registerRequest: registerRequest);
                      _logger.info('User registration response: $response');
                      _showSnackBar('用户创建成功');
                      Navigator.pop(context);
                      await _refreshUserList();
                    } catch (e) {
                      _logger.severe('User creation failed: $e', StackTrace.current);
                      if (e is ApiException && e.code == 409) {
                        _showSnackBar('账号已被占用，请尝试其他账号', isError: true);
                      } else if (e is ApiException && e.code == 400) {
                        _showSnackBar('请求无效，请检查输入', isError: true);
                      } else {
                        _showSnackBar('创建用户失败: ${_formatErrorMessage(e)}', isError: true);
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('创建'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditUserDialog(UserManagement user) async {
    final usernameController = TextEditingController(text: user.username);
    final contactNumberController = TextEditingController(text: user.contactNumber);
    final passwordController = TextEditingController(text: user.password);
    final emailController = TextEditingController(text: user.email);
    final remarksController = TextEditingController(text: user.remarks);
    String? selectedStatus = user.status ?? 'Active';
    final formKey = GlobalKey<FormState>();
    final idempotencyKey = generateIdempotencyKey();

    await showDialog(
      context: context,
      builder: (context) {
        final themeData = controller.currentBodyTheme.value;
        return Theme(
          data: themeData,
          child: AlertDialog(
            title: Text('编辑用户', style: themeData.textTheme.titleLarge),
            backgroundColor: themeData.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: '账号',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '账号不能为空';
                        if (value.length > 50) return '账号不能超过50个字符';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberController,
                      decoration: InputDecoration(
                        labelText: '联系电话',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length > 20) {
                          return '联系电话不能超过20个字符';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: '密码',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      obscureText: true,
                      maxLength: 255,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '密码不能为空';
                        if (value.length > 255) return '密码不能超过255个字符';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: '邮箱',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length > 100) return '邮箱不能超过100个字符';
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return '请输入有效的邮箱地址';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: InputDecoration(
                        labelText: '状态',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      items: _statusDropdownItems
                          .map((item) => DropdownMenuItem(
                        value: item['value'],
                        child: Text(item['label']!),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedStatus = value),
                      validator: (value) => value == null ? '请选择状态' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: '备注',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
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
                child: Text('取消', style: TextStyle(color: themeData.colorScheme.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!await _validateJwtToken()) {
                      Get.offAllNamed(Routes.login);
                      return;
                    }
                    final username = usernameController.text.trim();
                    if (username != user.username) {
                      final isUsernameAvailable = await _checkUsernameAvailability(username);
                      if (!isUsernameAvailable) {
                        _showSnackBar('账号已存在，请选择其他账号', isError: true);
                        return;
                      }
                    }
                    try {
                      final updatedUser = UserManagement(
                        userId: user.userId,
                        username: username,
                        contactNumber: contactNumberController.text.isEmpty ? null : contactNumberController.text,
                        email: emailController.text.isEmpty ? null : emailController.text,
                        status: selectedStatus,
                        remarks: remarksController.text.isEmpty ? null : remarksController.text,
                      );
                      _logger.info(
                        'Updating user: ${user.userId}, status: $selectedStatus, idempotencyKey: $idempotencyKey',
                      );
                      await userApi.apiUsersUserIdPut(
                        userId: user.userId.toString(),
                        userManagement: updatedUser,
                        idempotencyKey: idempotencyKey,
                      );
                      _showSnackBar('用户更新成功');
                      Navigator.pop(context);
                      await _refreshUserList();
                    } catch (e) {
                      _logger.severe('User update failed: $e', StackTrace.current);
                      _showSnackBar(_formatErrorMessage(e), isError: true);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('保存'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    final themeData = controller.currentBodyTheme.value;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Theme(
        data: themeData,
        child: AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除此用户吗？此操作不可撤销。'),
          backgroundColor: themeData.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('取消', style: TextStyle(color: themeData.colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('删除'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(Routes.login);
        return;
      }
      try {
        _logger.info('Deleting user: $userId');
        await userApi.apiUsersUserIdDelete(userId: userId);
        _showSnackBar('用户删除成功');
        await _refreshUserList();
      } catch (e) {
        _logger.severe('User deletion failed: $e', StackTrace.current);
        _showSnackBar(_formatErrorMessage(e), isError: true);
      }
    }
  }

  Widget _buildSearchField(ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) async {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return await _fetchAutocompleteSuggestions(textEditingValue.text);
                },
                onSelected: (String selection) {
                  _searchController.text = selection;
                  _searchUsers();
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  _searchController.text = controller.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: _searchType == 'username'
                          ? '搜索账号'
                          : _searchType == 'status'
                          ? '搜索状态'
                          : _searchType == 'department'
                          ? '搜索部门'
                          : _searchType == 'contactNumber'
                          ? '搜索联系电话'
                          : '搜索邮箱',
                      hintStyle: TextStyle(color: themeData.colorScheme.onSurface.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search, color: themeData.colorScheme.primary),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: themeData.colorScheme.onSurfaceVariant),
                        onPressed: () {
                          controller.clear();
                          _searchController.clear();
                          _refreshUserList();
                        },
                      )
                          : null,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: themeData.colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
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
                  _refreshUserList();
                });
              },
              items: <String>['username', 'status', 'department', 'contactNumber', 'email']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value == 'username'
                        ? '按账号'
                        : value == 'status'
                        ? '按状态'
                        : value == 'department'
                        ? '按部门'
                        : value == 'contactNumber'
                        ? '按联系电话'
                        : '按邮箱',
                    style: TextStyle(color: themeData.colorScheme.onSurface),
                  ),
                );
              }).toList(),
              dropdownColor: themeData.colorScheme.surfaceContainer,
              icon: Icon(Icons.arrow_drop_down, color: themeData.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: '用户管理',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        onRefresh: _refreshUserList,
        onThemeToggle: controller.toggleBodyTheme,
        body:
        Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isAdmin) _buildSearchField(themeData),
                        const SizedBox(height: 20),
                        Expanded(
                          child: _isLoading && _currentPage == 1
                              ? Center(
                            child: CupertinoActivityIndicator(
                              color: themeData.colorScheme.primary,
                              radius: 16.0,
                            ),
                          )
                              : _errorMessage.isNotEmpty && !_isLoading && _userList.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: themeData.colorScheme.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage,
                                  style: themeData.textTheme.titleMedium?.copyWith(
                                    color: themeData.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_errorMessage.contains('未授权') || _errorMessage.contains('登录'))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: ElevatedButton(
                                      onPressed: () => Get.offAllNamed(Routes.login),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: themeData.colorScheme.primary,
                                        foregroundColor: themeData.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                                      ),
                                      child: const Text('重新登录'),
                                    ),
                                  ),
                              ],
                            ),
                          )
                              : _userList.isEmpty
                              ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.doc,
                                  color: themeData.colorScheme.onSurfaceVariant,
                                  size: 48,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage.isNotEmpty ? _errorMessage : '当前没有用户记录',
                                  style: themeData.textTheme.titleMedium?.copyWith(
                                    color: themeData.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                              : CupertinoScrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            thickness: 6.0,
                            thicknessWhileDragging: 10.0,
                            child: RefreshIndicator(
                              onRefresh: () => _refreshUserList(),
                              color: themeData.colorScheme.primary,
                              backgroundColor: themeData.colorScheme.surfaceContainer,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: _userList.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _userList.length && _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(child: CupertinoActivityIndicator()),
                                    );
                                  }
                                  final user = _userList[index];
                                  return Card(
                                    elevation: 4,
                                    color: themeData.colorScheme.surfaceContainerLowest,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                      title: Text(
                                        '账号: ${user.username ?? '未知用户'}',
                                        style: themeData.textTheme.titleMedium?.copyWith(
                                          color: themeData.colorScheme.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            '状态: ${_statusDisplayMap[user.status] ?? '未知状态'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '联系电话: ${user.contactNumber ?? '无'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '邮箱: ${user.email ?? '无'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '创建时间: ${user.createdTime?.toString() ?? '无'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '修改时间: ${user.modifiedTime?.toString() ?? '无'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            '备注: ${user.remarks ?? '无'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: _isAdmin
                                          ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit, color: themeData.colorScheme.primary),
                                            onPressed: () => _showEditUserDialog(user),
                                            tooltip: '编辑用户',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: themeData.colorScheme.error),
                                            onPressed: () => _deleteUser(user.userId.toString()),
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
                        ),
                        if (_isAdmin)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton(
                              onPressed: _showCreateUserDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeData.colorScheme.primary,
                                foregroundColor: themeData.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                padding: const EdgeInsets.symmetric(vertical: 16.0),
                              ),
                              child: const Text('创建新用户', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                      ],
                    ),
                  ),
      );
    });
  }
}
