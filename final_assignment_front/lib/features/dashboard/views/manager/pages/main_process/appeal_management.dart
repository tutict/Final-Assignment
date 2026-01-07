// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/appeal_management_controller_api.dart';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/appeal_record.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

String generateIdempotencyKey() {
  return const Uuid().v4();
}

String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'æªæä¾';
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
}

// New function to map English processStatus to Chinese for display
String getDisplayStatus(String? status) {
  switch (status) {
    case 'Pending':
      return 'å¾
å¤ç';
    case 'Approved':
      return 'å·²éè¿';
    case 'Rejected':
      return 'å·²é©³å';
    default:
      return status ?? 'æªç¥';
  }
}

class AppealManagementAdmin extends StatefulWidget {
  const AppealManagementAdmin({super.key});

  @override
  State<AppealManagementAdmin> createState() => _AppealManagementAdminState();
}

class _AppealManagementAdminState extends State<AppealManagementAdmin> {
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  final OffenseInformationControllerApi offenseApi =
      OffenseInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  List<AppealRecordModel> _appeals = [];
  List<AppealRecordModel> _filteredAppeals = [];
  String _searchType = 'appealReason';
  DateTime? _startTime;
  DateTime? _endTime;
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  static const int _maxOffenseBatch = 20;
  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
    _searchController.addListener(() {
      _applyFilters(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = 'æªææï¼æªæ¾å°ç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = 'ç»å½å·²è¿æï¼è¯·éæ°ç»å½');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = 'æ°ç»å½ä¿¡æ¯å·²è¿æï¼è¯·éæ°ç»å½');
          return false;
        }
        await appealApi.initializeWithJwt();
      }
      developer
          .log('JWT Token validated successfully: sub=${decodedToken['sub']}');
      return true;
    } catch (e) {
      setState(() => _errorMessage = 'æ æçç»å½ä¿¡æ¯ï¼$eï¼è¯·éæ°ç»å½');
      developer.log('JWT validation failed: $e',
          stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      developer.log('No refresh token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await AuthTokenStore.instance.setJwtToken(newJwt);
        developer.log('JWT token refreshed successfully');
        return newJwt;
      }
      developer.log(
          'Refresh token request failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      developer.log('Error refreshing JWT token: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await appealApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await _checkUserRole();
      if (_isAdmin) {
        await _loadAppeals(reset: true);
      } else {
        setState(() => _errorMessage = 'æéä¸è¶³ï¼ä»
ç®¡çåå¯è®¿é®æ­¤é¡µé¢');
      }
    } catch (e) {
      setState(() => _errorMessage = 'åå§åå¤±è´¥: $e');
      developer.log('Initialization failed: $e',
          stackTrace: StackTrace.current);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;

      // Try backend API first
      try {
        final response = await http.get(
          Uri.parse('http://localhost:8081/api/users/me'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(utf8.decode(response.bodyBytes));
          developer.log('User data from /api/users/me: $userData');
          final roles = (userData['roles'] as List<dynamic>?)
              ?.map((r) => r.toString().toUpperCase())
              .toList();
          if (roles != null && roles.contains('ADMIN')) {
            setState(() => _isAdmin = true);
            return;
          }
          developer.log(
              'No valid roles in /api/users/me response, falling back to JWT');
        } else {
          developer.log(
              'Failed to fetch user roles: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        developer.log('Error fetching user roles from API: $e');
      }

      // Fallback to JWTSwe token roles
      await _checkRolesFromJwt();
    } catch (e) {
      setState(() => _errorMessage = 'éªè¯è§è²å¤±è´¥: $e');
      developer.log('Role check failed: $e', stackTrace: StackTrace.current);
    }
  }

  Future<void> _checkRolesFromJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      developer.log('JWT decoded: $decodedToken');
      final rawRoles = decodedToken['roles'];
      List<String> roles;
      if (rawRoles is String) {
        roles = rawRoles
            .split(',')
            .map((role) => role.trim().toUpperCase())
            .toList();
      } else if (rawRoles is List<dynamic>) {
        roles = rawRoles.map((role) => role.toString().toUpperCase()).toList();
      } else {
        roles = [];
      }
      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = 'æéä¸è¶³ï¼JWTè§è²ä¸º $rolesï¼éç®¡çå');
      }
      developer.log('Roles from JWT: $roles, isAdmin: $_isAdmin');
    } catch (e) {
      setState(() => _errorMessage = 'ä»JWTéªè¯è§è²å¤±è´¥: $e');
      developer.log('JWT role check failed: $e',
          stackTrace: StackTrace.current);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    if (prefix.isEmpty) return [];
    final normalized = prefix.toLowerCase();
    Iterable<String> values = const Iterable.empty();
    switch (_searchType) {
      case 'appealReason':
        values = _appeals.map((appeal) => appeal.appealReason ?? '');
        break;
      case 'appellantName':
        values = _appeals.map((appeal) => appeal.appellantName ?? '');
        break;
      case 'processStatus':
        values =
            _appeals.map((appeal) => getDisplayStatus(appeal.processStatus));
        break;
      default:
        return [];
    }
    return values
        .where((value) => value.isNotEmpty)
        .where((value) => value.toLowerCase().contains(normalized))
        .toSet()
        .take(5)
        .toList();
  }

  Future<List<AppealRecordModel>> _fetchAllAppeals({int pageSize = 50}) async {
    if (!await _validateJwtToken()) {
      Get.offAllNamed(AppPages.login);
      return [];
    }
    await appealApi.initializeWithJwt();
    await offenseApi.initializeWithJwt();
    final offenses = await offenseApi.apiOffensesGet();
    final List<AppealRecordModel> results = [];
    for (final offense in offenses.take(_maxOffenseBatch)) {
      final offenseId = offense.offenseId;
      if (offenseId == null) continue;
      try {
        final subset = await appealApi.apiAppealsGet(
          offenseId: offenseId,
          page: 1,
          size: pageSize,
        );
        results.addAll(subset);
      } catch (e) {
        developer.log('Failed to load appeals for offense $offenseId: $e',
            name: 'AppealManagement');
      }
    }
    return results;
  }

  Future<void> _loadAppeals({bool reset = false, String? query}) async {
    if (!_isAdmin) return;

    if (reset) {
      _appeals.clear();
      _filteredAppeals.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final appeals = await _fetchAllAppeals();
      setState(() {
        _appeals = appeals;
        _applyFilters(query ?? _searchController.text);
        if (_filteredAppeals.isEmpty) {
          _errorMessage = (_searchController.text.isNotEmpty ||
                  (_startTime != null && _endTime != null))
              ? 'æªæ¾å°ç¬¦åæ¡ä»¶çç³è¯è®°å½'
              : 'ææ ç³è¯è®°å½';
        }
      });
      developer.log('Loaded appeals: ${_appeals.length}');
    } catch (e) {
      developer.log('Error fetching appeals: $e',
          stackTrace: StackTrace.current);
      setState(() {
        _appeals.clear();
        _filteredAppeals.clear();
        if (e is ApiException && e.code == 403) {
          _errorMessage = 'æªææï¼è¯·éæ°ç»å½';
          Get.offAllNamed(AppPages.login);
        } else {
          _errorMessage = 'å è½½ç³è¯ä¿¡æ¯å¤±è´¥: ${_formatErrorMessage(e)}';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredAppeals = _appeals.where((appeal) {
        final reason = (appeal.appealReason ?? '').toLowerCase();
        final name = (appeal.appellantName ?? '').toLowerCase();
        final status = getDisplayStatus(appeal.processStatus)
            .toLowerCase(); // Use Chinese status for filtering
        final appealTime = appeal.appealTime;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'appealReason') {
            matchesQuery = reason.contains(searchQuery);
          } else if (_searchType == 'appellantName') {
            matchesQuery = name.contains(searchQuery);
          } else if (_searchType == 'processStatus') {
            matchesQuery = status.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startTime != null && _endTime != null && appealTime != null) {
          matchesDateRange = appealTime.isAfter(_startTime!) &&
              appealTime.isBefore(_endTime!.add(const Duration(days: 1)));
        } else if (_startTime != null &&
            _endTime != null &&
            appealTime == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredAppeals.isEmpty && _appeals.isNotEmpty) {
        _errorMessage = 'æªæ¾å°ç¬¦åæ¡ä»¶çç³è¯è®°å½';
      } else {
        _errorMessage =
            _filteredAppeals.isEmpty && _appeals.isEmpty ? 'ææ ç³è¯è®°å½' : '';
      }
    });
  }

  Future<void> _refreshAppeals({String? query}) async {
    setState(() {
      _appeals.clear();
      _filteredAppeals.clear();
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startTime = null;
        _endTime = null;
        _searchType = 'appealReason';
      }
    });
    await _loadAppeals(reset: true, query: query);
  }

  void _goToDetailPage(AppealRecordModel appeal) {
    Get.to(() => AppealDetailPage(
          appeal: appeal,
          onAppealUpdated: (updatedAppeal) {
            setState(() {
              final index = _appeals
                  .indexWhere((a) => a.appealId == updatedAppeal.appealId);
              if (index != -1) {
                _appeals[index] = updatedAppeal;
              }
              _applyFilters(_searchController.text);
            });
          },
        ))?.then((value) {
      if (value == true && mounted) _refreshAppeals();
    });
  }

  // ignore: unused_element
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
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

  Widget _buildSearchBar(ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.isEmpty ||
                          _searchType == 'timeRange') {
                        return const Iterable<String>.empty();
                      }
                      return await _fetchAutocompleteSuggestions(
                          textEditingValue.text);
                    },
                    onSelected: (String selection) {
                      _searchController.text = selection;
                      _applyFilters(selection);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                      return TextField(
                        controller: _searchController,
                        focusNode: focusNode,
                        style: themeData.textTheme.bodyMedium
                            ?.copyWith(color: themeData.colorScheme.onSurface),
                        decoration: InputDecoration(
                          hintText: _searchType == 'appealReason'
                              ? 'æç´¢ç³è¯åå '
                              : _searchType == 'appellantName'
                                  ? 'æç´¢ç³è¯äººå§å'
                                  : _searchType == 'processStatus'
                                      ? 'æç´¢å¤çç¶æ' // Updated to Chinese
                                      : 'æç´¢æ¶é´èå´ï¼å·²éæ©ï¼',
                          hintStyle: themeData.textTheme.bodyMedium?.copyWith(
                            color: themeData.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                          prefixIcon: Icon(Icons.search,
                              color: themeData.colorScheme.primary),
                          suffixIcon: _searchController.text.isNotEmpty ||
                                  (_startTime != null && _endTime != null)
                              ? IconButton(
                                  icon: Icon(Icons.clear,
                                      color: themeData
                                          .colorScheme.onSurfaceVariant),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _startTime = null;
                                      _endTime = null;
                                      _searchType = 'appealReason';
                                    });
                                    _applyFilters('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: themeData.colorScheme.surfaceContainer,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                        ),
                        onChanged: (value) => _applyFilters(value),
                        onSubmitted: (value) => _applyFilters(value),
                        enabled: _searchType != 'timeRange',
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
                      _startTime = null;
                      _endTime = null;
                      _applyFilters('');
                    });
                  },
                  items: <String>[
                    'appealReason',
                    'appellantName',
                    'processStatus',
                    'timeRange'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value == 'appealReason'
                            ? 'æç³è¯åå '
                            : value == 'appellantName'
                                ? 'æç³è¯äººå§å'
                                : value == 'processStatus'
                                    ? 'æå¤çç¶æ' // Updated to Chinese
                                    : 'ææ¶é´èå´',
                        style:
                            TextStyle(color: themeData.colorScheme.onSurface),
                      ),
                    );
                  }).toList(),
                  dropdownColor: themeData.colorScheme.surfaceContainer,
                  icon: Icon(Icons.arrow_drop_down,
                      color: themeData.colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _startTime != null && _endTime != null
                        ? 'æ¥æèå´: ${formatDateTime(_startTime)} è³ ${formatDateTime(_endTime)}'
                        : 'éæ©æ¥æèå´',
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: _startTime != null && _endTime != null
                          ? themeData.colorScheme.onSurface
                          : themeData.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.date_range,
                      color: themeData.colorScheme.primary),
                  tooltip: 'ææ¥æèå´æç´¢',
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      locale: const Locale('zh', 'CN'),
                      helpText: 'éæ©æ¥æèå´',
                      cancelText: 'åæ¶',
                      confirmText: 'ç¡®å®',
                      fieldStartHintText: 'å¼å§æ¥æ',
                      fieldEndHintText: 'ç»ææ¥æ',
                      builder: (BuildContext context, Widget? child) {
                        return Theme(
                          data: themeData.copyWith(
                            colorScheme: themeData.colorScheme.copyWith(
                              primary: themeData.colorScheme.primary,
                              onPrimary: themeData.colorScheme.onPrimary,
                            ),
                            textButtonTheme: TextButtonThemeData(
                              style: TextButton.styleFrom(
                                foregroundColor: themeData.colorScheme.primary,
                              ),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (range != null) {
                      setState(() {
                        _startTime = range.start;
                        _endTime = range.end;
                        _searchType = 'timeRange';
                        _searchController.clear();
                      });
                      _applyFilters('');
                    }
                  },
                ),
                if (_startTime != null && _endTime != null)
                  IconButton(
                    icon: Icon(Icons.clear,
                        color: themeData.colorScheme.onSurfaceVariant),
                    tooltip: 'æ¸
é¤æ¥æèå´',
                    onPressed: () {
                      setState(() {
                        _startTime = null;
                        _endTime = null;
                        _searchType = 'appealReason';
                        _searchController.clear();
                      });
                      _applyFilters('');
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppealCard(AppealRecordModel appeal, ThemeData themeData) {
    return Card(
      elevation: 4,
      color: themeData.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        title: Text(
          'ç³è¯äºº: ${appeal.appellantName ?? "æªç¥"} (ID: ${appeal.appealId ?? "æ "})',
          style: themeData.textTheme.titleMedium?.copyWith(
            color: themeData.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'åå : ${appeal.appealReason ?? "æ "}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'ç¶æ: ${getDisplayStatus(appeal.processStatus)}',
                // Use Chinese status
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: appeal.processStatus == 'Approved'
                      ? Colors.green
                      : appeal.processStatus == 'Rejected'
                          ? Colors.red
                          : themeData.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'æ¶é´: ${formatDateTime(appeal.appealTime)}',
                style: themeData.textTheme.bodyMedium?.copyWith(
                  color: themeData.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        trailing: Icon(
          CupertinoIcons.forward,
          color: themeData.colorScheme.primary,
          size: 18,
        ),
        onTap: () => _goToDetailPage(appeal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;

      return DashboardPageTemplate(
        theme: themeData,
        title: 'ç³è¯å®¡æ¹ç®¡ç',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          DashboardPageBarAction(
            icon: Icons.refresh,
            onPressed: () => _refreshAppeals(),
            tooltip: 'å·æ°åè¡¨',
          ),
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchBar(themeData),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CupertinoActivityIndicator(
                          color: themeData.colorScheme.primary,
                          radius: 16.0,
                        ),
                      )
                    : _errorMessage.isNotEmpty
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
                                  style: themeData.textTheme.titleMedium
                                      ?.copyWith(
                                    color: themeData.colorScheme.error,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_errorMessage.contains('æªææ') ||
                                    _errorMessage.contains('ç»å½') ||
                                    _errorMessage.contains('æéä¸è¶³'))
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(top: 20.0),
                                    child: ElevatedButton(
                                      onPressed: () =>
                                          Get.offAllNamed(AppPages.login),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            themeData.colorScheme.primary,
                                        foregroundColor:
                                            themeData.colorScheme.onPrimary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24.0, vertical: 12.0),
                                      ),
                                      child: const Text('éæ°ç»å½'),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : _filteredAppeals.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.doc,
                                      color: themeData
                                          .colorScheme.onSurfaceVariant,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage.isNotEmpty
                                          ? _errorMessage
                                          : 'ææ ç³è¯è®°å½',
                                      style: themeData.textTheme.titleMedium
                                          ?.copyWith(
                                        color: themeData
                                            .colorScheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            : CupertinoScrollbar(
                                thumbVisibility: true,
                                thickness: 6.0,
                                thicknessWhileDragging: 10.0,
                                child: RefreshIndicator(
                                  onRefresh: () => _refreshAppeals(),
                                  color: themeData.colorScheme.primary,
                                  backgroundColor:
                                      themeData.colorScheme.surfaceContainer,
                                  child: ListView.builder(
                                    itemCount: _filteredAppeals.length,
                                    itemBuilder: (context, index) {
                                      final appeal = _filteredAppeals[index];
                                      return _buildAppealCard(appeal, themeData);
                                    },
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class AppealDetailPage extends StatefulWidget {
  final AppealRecordModel appeal;
  final Function(AppealRecordModel)? onAppealUpdated;

  const AppealDetailPage(
      {super.key, required this.appeal, this.onAppealUpdated});

  @override
  State<AppealDetailPage> createState() => _AppealDetailPageState();
}

class _AppealDetailPageState extends State<AppealDetailPage> {
  final AppealManagementControllerApi appealApi =
      AppealManagementControllerApi();
  final TextEditingController _rejectionReasonController =
      TextEditingController();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final DashboardController controller = Get.find<DashboardController>();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = 'æªææï¼æªæ¾å°ç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      if (JwtDecoder.isExpired(jwtToken)) {
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = 'ç»å½å·²è¿æï¼è¯·éæ°ç»å½');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = 'æ°ç»å½ä¿¡æ¯å·²è¿æï¼è¯·éæ°ç»å½');
          return false;
        }
        await appealApi.initializeWithJwt();
      }
      developer
          .log('JWT Token validated successfully: sub=${decodedToken['sub']}');
      return true;
    } catch (e) {
      setState(() => _errorMessage = 'æ æçç»å½ä¿¡æ¯ï¼$eï¼è¯·éæ°ç»å½');
      developer.log('JWT validation failed: $e',
          stackTrace: StackTrace.current);
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      developer.log('No refresh token found');
      return null;
    }
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await AuthTokenStore.instance.setJwtToken(newJwt);
        developer.log('JWT token refreshed successfully');
        return newJwt;
      }
      developer.log(
          'Refresh token request failed: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      developer.log('Error refreshing JWT token: $e',
          stackTrace: StackTrace.current);
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      await appealApi.initializeWithJwt();
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = 'åå§åå¤±è´¥: $e');
      developer.log('Initialization failed: $e',
          stackTrace: StackTrace.current);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Get.offAllNamed(AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;

      // Try backend API first
      try {
        final response = await http.get(
          Uri.parse('http://localhost:8081/api/users/me'),
          headers: {
            'Authorization': 'Bearer $jwtToken',
            'Content-Type': 'application/json',
          },
        );
        if (response.statusCode == 200) {
          final userData = jsonDecode(utf8.decode(response.bodyBytes));
          developer.log('User data from /api/users/me: $userData');
          final roles = (userData['roles'] as List<dynamic>?)
              ?.map((r) => r.toString().toUpperCase())
              .toList();
          if (roles != null && roles.contains('ADMIN')) {
            setState(() => _isAdmin = true);
            return;
          }
          developer.log(
              'No valid roles in /api/users/me response, falling back to JWT');
        } else {
          developer.log(
              'Failed to fetch user roles: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        developer.log('Error fetching user roles from API: $e');
      }

      // Fallback to JWT token roles
      await _checkRolesFromJwt();
    } catch (e) {
      setState(() => _errorMessage = 'éªè¯è§è²å¤±è´¥: $e');
      developer.log('Role check failed: $e', stackTrace: StackTrace.current);
    }
  }

  Future<void> _checkRolesFromJwt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      developer.log('JWT decoded: $decodedToken');
      final rawRoles = decodedToken['roles'];
      List<String> roles;
      if (rawRoles is String) {
        roles = rawRoles
            .split(',')
            .map((role) => role.trim().toUpperCase())
            .toList();
      } else if (rawRoles is List<dynamic>) {
        roles = rawRoles.map((role) => role.toString().toUpperCase()).toList();
      } else {
        roles = [];
      }
      setState(() => _isAdmin = roles.contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = 'æéä¸è¶³ï¼JWTè§è²ä¸º $rolesï¼éç®¡çå');
      }
      developer.log('Roles from JWT: $roles, isAdmin: $_isAdmin');
    } catch (e) {
      setState(() => _errorMessage = 'ä»JWTéªè¯è§è²å¤±è´¥: $e');
      developer.log('JWT role check failed: $e',
          stackTrace: StackTrace.current);
    }
  }

  Future<void> _approveAppeal(int appealId) async {
    if (widget.appeal.appealId == null) {
      _showSnackBar('ç³è¯IDæ æ', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final updatedAppeal = widget.appeal.copyWith(
        processStatus: 'Approved', // Keep English for backend
        processResult: 'ç³è¯å·²éè¿',
      );
      developer.log(
          'Approving appeal ID: $appealId, Payload: ${updatedAppeal.toJson()}');
      await appealApi
          .apiAppealsAppealIdPut(
            appealId: appealId,
            appealRecord: updatedAppeal,
            idempotencyKey: generateIdempotencyKey(),
          )
          .timeout(const Duration(seconds: 5));
      _showSnackBar('ç³è¯å·²å®¡æ¹éè¿ï¼');
      widget.onAppealUpdated?.call(updatedAppeal);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      developer.log('Error approving appeal: $e',
          stackTrace: StackTrace.current);
      _showSnackBar(_formatErrorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAppeal(int appealId) async {
    final themeData = controller.currentBodyTheme.value;
    showDialog(
      context: context,
      builder: (ctx) => Theme(
        data: themeData,
        child: Dialog(
          backgroundColor: themeData.colorScheme.surfaceContainerLowest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'é©³åç³è¯',
                  style: themeData.textTheme.titleLarge?.copyWith(
                    color: themeData.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _rejectionReasonController,
                  decoration: InputDecoration(
                    labelText: 'é©³ååå ',
                    labelStyle: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                    ),
                    filled: true,
                    fillColor: themeData.colorScheme.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: themeData.colorScheme.primary,
                        width: 2.0,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: themeData.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'åæ¶',
                        style: themeData.textTheme.labelLarge?.copyWith(
                          color: themeData.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final reason = _rejectionReasonController.text.trim();
                        if (reason.isEmpty) {
                          _showSnackBar('è¯·å¡«åé©³ååå ', isError: true);
                          return;
                        }
                        if (widget.appeal.appealId == null) {
                          _showSnackBar('ç³è¯IDæ æ', isError: true);
                          Navigator.pop(ctx);
                          return;
                        }
                        setState(() => _isLoading = true);
                        try {
                          final updatedAppeal = widget.appeal.copyWith(
                            processStatus: 'Rejected',
                            // Keep English for backend
                            processResult: reason,
                          );
                          developer.log(
                              'Rejecting appeal ID: $appealId, Payload: ${updatedAppeal.toJson()}');
                          await appealApi
                              .apiAppealsAppealIdPut(
                                appealId: appealId,
                                appealRecord: updatedAppeal,
                                idempotencyKey: generateIdempotencyKey(),
                              )
                              .timeout(const Duration(seconds: 5));
                          _showSnackBar('ç³è¯å·²é©³åï¼ç¨æ·å¯éæ°æäº¤');
                          widget.onAppealUpdated?.call(updatedAppeal);
                          Navigator.pop(ctx);
                          if (mounted) Navigator.pop(context, true);
                        } catch (e) {
                          developer.log('Error rejecting appeal: $e',
                              stackTrace: StackTrace.current);
                          _showSnackBar(_formatErrorMessage(e), isError: true);
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.error,
                        foregroundColor: themeData.colorScheme.onError,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                      ),
                      child: Text(
                        'ç¡®è®¤é©³å',
                        style: themeData.textTheme.labelLarge?.copyWith(
                          color: themeData.colorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    final themeData = controller.currentBodyTheme.value;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError
                ? themeData.colorScheme.onError
                : themeData.colorScheme.onPrimary,
          ),
        ),
        backgroundColor: isError
            ? themeData.colorScheme.error
            : themeData.colorScheme.primary,
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

  Widget _buildDetailRow(String label, String value, ThemeData themeData,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              label == 'å¤çç¶æ' ? getDisplayStatus(value) : value,
              // Use Chinese status for display
              style: themeData.textTheme.bodyLarge?.copyWith(
                color: valueColor ?? themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      final appealId = widget.appeal.appealId?.toString() ?? 'æªæä¾';
      final offenseId = widget.appeal.offenseId?.toString() ?? 'æªæä¾';
      final name = widget.appeal.appellantName ?? 'æªæä¾';
      final idCard = widget.appeal.appellantIdCard ?? 'æªæä¾';
      final contact = widget.appeal.appellantContact ?? 'æªæä¾';
      final reason = widget.appeal.appealReason ?? 'æªæä¾';
      final time = formatDateTime(widget.appeal.appealTime);
      final status = widget.appeal.processStatus ?? 'æªæä¾';
      final result = widget.appeal.processResult ?? 'æªæä¾';

      return DashboardPageTemplate(
        theme: themeData,
        title: 'ç³è¯è¯¦æ
',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: themeData.colorScheme.primary,
                    radius: 16.0,
                  ),
                )
              : _errorMessage.isNotEmpty
                  ? Column(
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
                        if (_errorMessage.contains('æªææ') ||
                            _errorMessage.contains('ç»å½') ||
                            _errorMessage.contains('æéä¸è¶³'))
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ElevatedButton(
                              onPressed: () => Get.offAllNamed(AppPages.login),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeData.colorScheme.primary,
                                foregroundColor:
                                    themeData.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 12.0),
                              ),
                              child: const Text('éæ°ç»å½'),
                            ),
                          ),
                      ],
                    )
                  : CupertinoScrollbar(
                      controller: ScrollController(),
                      thumbVisibility: true,
                      thickness: 6.0,
                      thicknessWhileDragging: 10.0,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              elevation: 4,
                              color: themeData
                                  .colorScheme.surfaceContainerLowest,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0)),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow('ç³è¯ID', appealId, themeData),
                                    _buildDetailRow(
                                        'è¿æ³è®°å½ID', offenseId, themeData),
                                    _buildDetailRow('ä¸è¯äººå§å', name, themeData),
                                    _buildDetailRow(
                                        'èº«ä»½è¯å·ç ', idCard, themeData),
                                    _buildDetailRow('èç³»çµè¯', contact, themeData),
                                    _buildDetailRow('ä¸è¯åå ', reason, themeData),
                                    _buildDetailRow('ä¸è¯æ¶é´', time, themeData),
                                    _buildDetailRow('å¤çç¶æ', status, themeData,
                                        valueColor: status == 'Approved'
                                            ? Colors.green
                                            : status == 'Rejected'
                                                ? Colors.red
                                                : themeData.colorScheme
                                                    .onSurfaceVariant),
                                    _buildDetailRow('å¤çç»æ', result, themeData),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            if (_isAdmin && status == 'Pending') ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _approveAppeal(
                                        widget.appeal.appealId ?? 0),
                                    icon: const Icon(CupertinoIcons.checkmark,
                                        size: 20),
                                    label: const Text('éè¿'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 12.0),
                                      elevation: 2,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _rejectAppeal(
                                        widget.appeal.appealId ?? 0),
                                    icon: const Icon(CupertinoIcons.xmark,
                                        size: 20),
                                    label: const Text('é©³å'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          themeData.colorScheme.error,
                                      foregroundColor:
                                          themeData.colorScheme.onError,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.0)),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20.0, vertical: 12.0),
                                      elevation: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ] else
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 20.0),
                                  decoration: BoxDecoration(
                                    color: themeData
                                        .colorScheme.surfaceContainer,
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: Text(
                                    _isAdmin
                                        ? 'æ­¤ç³è¯å·²å¤çï¼æ æ³åæ¬¡å®¡æ¹'
                                        : 'æéä¸è¶³ï¼ä»
ç®¡çåå¯å®¡æ¹ç³è¯',
                                    style: themeData.textTheme.bodyLarge
                                        ?.copyWith(
                                      color: themeData
                                          .colorScheme.onSurfaceVariant,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
        ),
      );
    });
  }
}
