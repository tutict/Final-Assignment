// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'dart:convert';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/auth_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
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

import '../../../../../model/register_request.dart';
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
    'Active': 'æ´»è·',
    'Inactive': 'ç¦ç¨',
  };

  // Dropdown items for status
  static const List<Map<String, String>> _statusDropdownItems = [
    {'value': 'Active', 'label': 'æ´»è·'},
    {'value': 'Inactive', 'label': 'ç¦ç¨'},
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
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = 'æªææï¼è¯·éæ°ç»å½');
      _logger.warning('No JWT token found');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = 'ç»å½å·²è¿æï¼è¯·éæ°ç»å½');
          _logger.warning('JWT token refresh failed');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = 'æ°ç»å½ä¿¡æ¯å·²è¿æï¼è¯·éæ°ç»å½');
          _logger.warning('Refreshed JWT token is expired');
          return false;
        }
        await userApi.initializeWithJwt();
      }
      _currentUsername = decodedToken['sub'] ?? '';
      _logger.info('JWT Token validated: sub=$_currentUsername');
      return true;
    } catch (e) {
      setState(() => _errorMessage = 'æ æçç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½: $e');
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
        Get.offAllNamed(AppPages.login);
        return;
      }
      await userApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
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
        setState(() => _errorMessage = 'ä»
ç®¡çåå¯è®¿é®ç¨æ·ç®¡çé¡µé¢');
      }
    } catch (e) {
      setState(() => _errorMessage = 'åå§åå¤±è´¥: $e');
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
      return false; // ç¨æ·å­å¨
    } catch (e) {
      if (e is ApiException && e.code == 404) {
        _logger.info('Username $username is available');
        return true; // ç¨æ·ä¸å­å¨ï¼å¯ç¨
      }
      _logger.severe('Failed to check username availability: $e', StackTrace.current);
      rethrow; // å
¶ä»éè¯¯ï¼æåºå¼å¸¸
    }
  }

  Future<void> _fetchUsers({bool reset = false, String? query}) async {
    if (!_isAdmin) {
      setState(() => _errorMessage = 'ä»
ç®¡çåå¯è®¿é®ç¨æ·ç®¡çé¡µé¢');
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
        Get.offAllNamed(AppPages.login);
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
          _errorMessage = searchQuery.isNotEmpty ? 'æªæ¾å°ç¬¦åæ¡ä»¶çç¨æ·' : 'å½åæ²¡æç¨æ·è®°å½';
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
              _errorMessage = 'æªææï¼è¯·éæ°ç»å½';
              Get.offAllNamed(AppPages.login);
              break;
            case 404:
              _errorMessage = 'æªæ¾å°ç¬¦åæ¡ä»¶çç¨æ·';
              _hasMore = false;
              break;
            default:
              _errorMessage = 'è·åç¨æ·å¤±è´¥: ${e.message}';
          }
        } else {
          _errorMessage = 'è·åç¨æ·å¤±è´¥: $e';
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
        Get.offAllNamed(AppPages.login);
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
          return 'è¯·æ±éè¯¯: ${error.message}';
        case 403:
          return 'æ æé: ${error.message}';
        case 404:
          return 'æªæ¾å°: ${error.message}';
        case 409:
          return 'éå¤è¯·æ±: ${error.message}';
        default:
          return 'æå¡å¨éè¯¯: ${error.message}';
      }
    }
    return 'æä½å¤±è´¥: $error';
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
            title: Text('åå»ºæ°ç¨æ·', style: themeData.textTheme.titleLarge),
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
                        labelText: 'è´¦å·',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'è´¦å·ä¸è½ä¸ºç©º';
                        if (value.length > 50) return 'è´¦å·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'å¯ç ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      obscureText: true,
                      maxLength: 255,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'å¯ç ä¸è½ä¸ºç©º';
                        if (value.length > 255) return 'å¯ç ä¸è½è¶
è¿255ä¸ªå­ç¬¦';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberController,
                      decoration: InputDecoration(
                        labelText: 'èç³»çµè¯',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length > 20) {
                          return 'èç³»çµè¯ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'é®ç®±',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length > 100) return 'é®ç®±ä¸è½è¶
è¿100ä¸ªå­ç¬¦';
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'è¯·è¾å
¥ææçé®ç®±å°å';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'ç¶æ',
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
                      validator: (value) => value == null ? 'è¯·éæ©ç¶æ' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: InputDecoration(
                        labelText: 'è§è²',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      items: ['USER', 'ADMIN']
                          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
                          .toList(),
                      onChanged: (value) => selectedRole = value,
                      validator: (value) => value == null ? 'è¯·éæ©è§è²' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: 'å¤æ³¨',
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
                child: Text('åæ¶', style: TextStyle(color: themeData.colorScheme.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!await _validateJwtToken()) {
                      Get.offAllNamed(AppPages.login);
                      return;
                    }
                    final username = usernameController.text.trim();
                    try {
                      _logger.info('Checking username availability: $username');
                      final isUsernameAvailable = await _checkUsernameAvailability(username);
                      if (!isUsernameAvailable) {
                        _showSnackBar('è´¦å·å·²å­å¨ï¼è¯·éæ©å
¶ä»è´¦å·', isError: true);
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
                      _showSnackBar('ç¨æ·åå»ºæå');
                      Navigator.pop(context);
                      await _refreshUserList();
                    } catch (e) {
                      _logger.severe('User creation failed: $e', StackTrace.current);
                      if (e is ApiException && e.code == 409) {
                        _showSnackBar('è´¦å·å·²è¢«å ç¨ï¼è¯·å°è¯å
¶ä»è´¦å·', isError: true);
                      } else if (e is ApiException && e.code == 400) {
                        _showSnackBar('è¯·æ±æ æï¼è¯·æ£æ¥è¾å
¥', isError: true);
                      } else {
                        _showSnackBar('åå»ºç¨æ·å¤±è´¥: ${_formatErrorMessage(e)}', isError: true);
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.colorScheme.primary,
                  foregroundColor: themeData.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: const Text('åå»º'),
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
            title: Text('ç¼è¾ç¨æ·', style: themeData.textTheme.titleLarge),
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
                        labelText: 'è´¦å·',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'è´¦å·ä¸è½ä¸ºç©º';
                        if (value.length > 50) return 'è´¦å·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactNumberController,
                      decoration: InputDecoration(
                        labelText: 'èç³»çµè¯',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.phone,
                      maxLength: 20,
                      validator: (value) {
                        if (value != null && value.isNotEmpty && value.length > 20) {
                          return 'èç³»çµè¯ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'å¯ç ',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      obscureText: true,
                      maxLength: 255,
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'å¯ç ä¸è½ä¸ºç©º';
                        if (value.length > 255) return 'å¯ç ä¸è½è¶
è¿255ä¸ªå­ç¬¦';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'é®ç®±',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        filled: true,
                        fillColor: themeData.colorScheme.surfaceContainer,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      maxLength: 100,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length > 100) return 'é®ç®±ä¸è½è¶
è¿100ä¸ªå­ç¬¦';
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'è¯·è¾å
¥ææçé®ç®±å°å';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'ç¶æ',
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
                      validator: (value) => value == null ? 'è¯·éæ©ç¶æ' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: remarksController,
                      decoration: InputDecoration(
                        labelText: 'å¤æ³¨',
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
                child: Text('åæ¶', style: TextStyle(color: themeData.colorScheme.error)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    if (!await _validateJwtToken()) {
                      Get.offAllNamed(AppPages.login);
                      return;
                    }
                    final username = usernameController.text.trim();
                    if (username != user.username) {
                      final isUsernameAvailable = await _checkUsernameAvailability(username);
                      if (!isUsernameAvailable) {
                        _showSnackBar('è´¦å·å·²å­å¨ï¼è¯·éæ©å
¶ä»è´¦å·', isError: true);
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
                      _showSnackBar('ç¨æ·æ´æ°æå');
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
                child: const Text('ä¿å­'),
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
          title: const Text('ç¡®è®¤å é¤'),
          content: const Text('ç¡®å®è¦å é¤æ­¤ç¨æ·åï¼æ­¤æä½ä¸å¯æ¤éã'),
          backgroundColor: themeData.colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('åæ¶', style: TextStyle(color: themeData.colorScheme.error)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              child: const Text('å é¤'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      try {
        _logger.info('Deleting user: $userId');
        await userApi.apiUsersUserIdDelete(userId: userId);
        _showSnackBar('ç¨æ·å é¤æå');
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
                          ? 'æç´¢è´¦å·'
                          : _searchType == 'status'
                          ? 'æç´¢ç¶æ'
                          : _searchType == 'department'
                          ? 'æç´¢é¨é¨'
                          : _searchType == 'contactNumber'
                          ? 'æç´¢èç³»çµè¯'
                          : 'æç´¢é®ç®±',
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
                        ? 'æè´¦å·'
                        : value == 'status'
                        ? 'æç¶æ'
                        : value == 'department'
                        ? 'æé¨é¨'
                        : value == 'contactNumber'
                        ? 'æèç³»çµè¯'
                        : 'æé®ç®±',
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
        title: 'ç¨æ·ç®¡ç',
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
                                if (_errorMessage.contains('æªææ') || _errorMessage.contains('ç»å½'))
                                  Padding(
                                    padding: const EdgeInsets.only(top: 20.0),
                                    child: ElevatedButton(
                                      onPressed: () => Get.offAllNamed(AppPages.login),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: themeData.colorScheme.primary,
                                        foregroundColor: themeData.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                                      ),
                                      child: const Text('éæ°ç»å½'),
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
                                  _errorMessage.isNotEmpty ? _errorMessage : 'å½åæ²¡æç¨æ·è®°å½',
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
                                        'è´¦å·: ${user.username ?? 'æªç¥ç¨æ·'}',
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
                                            'ç¶æ: ${_statusDisplayMap[user.status] ?? 'æªç¥ç¶æ'}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'èç³»çµè¯: ${user.contactNumber ?? 'æ '}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'é®ç®±: ${user.email ?? 'æ '}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'åå»ºæ¶é´: ${user.createdTime?.toString() ?? 'æ '}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'ä¿®æ¹æ¶é´: ${user.modifiedTime?.toString() ?? 'æ '}',
                                            style: themeData.textTheme.bodyMedium?.copyWith(
                                              color: themeData.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'å¤æ³¨: ${user.remarks ?? 'æ '}',
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
                                            tooltip: 'ç¼è¾ç¨æ·',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.delete, color: themeData.colorScheme.error),
                                            onPressed: () => _deleteUser(user.userId.toString()),
                                            tooltip: 'å é¤ç¨æ·',
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
                              child: const Text('åå»ºæ°ç¨æ·', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                      ],
                    ),
                  ),
      );
    });
  }
}
