// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:final_assignment_front/features/api/offense_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/utils/helpers/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/config/routes/app_pages.dart';
import 'package:final_assignment_front/features/api/fine_information_controller_api.dart';
import 'package:final_assignment_front/features/model/fine_information.dart';
import 'package:get/get.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

/// å¯ä¸æ è¯çæå·¥å
·
String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

/// æ ¼å¼åæ¥æçå
¨å±æ¹æ³
String formatDate(DateTime? date) {
  if (date == null) return 'æ ';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

DateTime? _resolvedFineDate(FineInformation fine) {
  return fine.fineDate ??
      (fine.fineTime != null ? DateTime.tryParse(fine.fineTime!) : null);
}

DateTime _comparableFineDate(FineInformation fine) {
  return _resolvedFineDate(fine) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// FineList é¡µé¢ï¼ç®¡çåæè½è®¿é®
class FineList extends StatefulWidget {
  const FineList({super.key});

  @override
  State<FineList> createState() => _FineListState();
}

class _FineListState extends State<FineList> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<FineInformation> _fineList = [];
  List<FineInformation> _cachedFineList = [];
  List<FineInformation> _filteredFineList = [];
  String _searchType = 'payee';
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startDate;
  DateTime? _endDate;
  final DashboardController controller = Get.find<DashboardController>();
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = 'æªææï¼è¯·éæ°ç»å½');
      return false;
    }
    try {
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
        await fineApi.initializeWithJwt();
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = 'æ æçç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½');
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) return null;
    try {
      final response = await http.post(
        Uri.parse('http://localhost:8081/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (response.statusCode == 200) {
        final newJwt = jsonDecode(response.body)['jwtToken'];
        await AuthTokenStore.instance.setJwtToken(newJwt);
        return newJwt;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      await fineApi.initializeWithJwt();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN' ||
          (decodedToken['roles'] is List &&
              decodedToken['roles'].contains('ADMIN'));
      if (!_isAdmin) {
        setState(() => _errorMessage = 'æéä¸è¶³ï¼ä»
ç®¡çåå¯è®¿é®æ­¤é¡µé¢');
        return;
      }
      await _fetchFines(reset: true);
    } catch (e) {
      setState(() => _errorMessage = 'åå§åå¤±è´¥: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ignore: unused_element
  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ADMIN'));
        if (!_isAdmin) {
          setState(() => _errorMessage = 'æéä¸è¶³ï¼ä»
ç®¡çåå¯è®¿é®æ­¤é¡µé¢');
        }
      } else {
        throw Exception('éªè¯å¤±è´¥ï¼${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'éªè¯è§è²å¤±è´¥: $e');
    }
  }

  Future<void> _fetchFines(
      {bool reset = false, String? query, int retries = 5}) async {
    if (!_isAdmin || !_hasMore) return;

    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _fineList.clear();
      _filteredFineList.clear();
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      List<FineInformation> fines = [];
      final searchQuery = query?.trim() ?? '';
      for (int attempt = 1; attempt <= retries; attempt++) {
        try {
          if (searchQuery.isEmpty && _startDate == null && _endDate == null) {
            fines = await fineApi.apiFinesGet();
            fines.sort((a, b) =>
                _comparableFineDate(b).compareTo(_comparableFineDate(a)));
          } else if (_searchType == 'payee' && searchQuery.isNotEmpty) {
            fines = await fineApi.apiFinesPayeePayeeGet(payee: searchQuery);
          } else if (_searchType == 'timeRange' &&
              _startDate != null &&
              _endDate != null) {
            fines = await fineApi.apiFinesTimeRangeGet(
              startDate: _startDate!.toIso8601String().split('T').first,
              endDate: _endDate!
                  .add(const Duration(days: 1))
                  .toIso8601String()
                  .split('T')
                  .first,
            );
          }
          break;
        } catch (e) {
          if (attempt == retries) {
            rethrow;
          }
          await Future.delayed(Duration(milliseconds: 1000 * attempt));
        }
      }

      setState(() {
        _fineList.addAll(fines);
        _cachedFineList = List.from(fines);
        _hasMore = fines.length == _pageSize;
        _applyFilters(query ?? _searchController.text);
        if (_filteredFineList.isEmpty) {
          _errorMessage =
          searchQuery.isNotEmpty || (_startDate != null && _endDate != null)
              ? 'æªæ¾å°ç¬¦åæ¡ä»¶çç½æ¬¾ä¿¡æ¯'
              : 'å½åæ²¡æç½æ¬¾è®°å½';
        }
        _currentPage++;
        if (reset && _scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('403')) {
          _errorMessage = 'æªææï¼è¯·éæ°ç»å½';
          Navigator.pushReplacementNamed(context, AppPages.login);
        } else if (e.toString().contains('404')) {
          _errorMessage = 'æªæ¾å°ç½æ¬¾è®°å½';
          _hasMore = false;
        } else {
          _errorMessage = 'è·åç½æ¬¾ä¿¡æ¯å¤±è´¥: $e';
        }
        if (_cachedFineList.isNotEmpty) {
          _fineList.addAll(_cachedFineList);
          _applyFilters(query ?? _searchController.text);
          _errorMessage = 'è·åææ°ç½æ¬¾å¤±è´¥ï¼æ¾ç¤ºç¼å­æ°æ®';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return [];
      }
      if (_searchType == 'payee') {
        final fines = await fineApi.apiFinesPayeePayeeGet(payee: prefix.trim());
        return fines
            .map((fine) => fine.payee ?? '')
            .where((payee) =>
                payee.toLowerCase().contains(prefix.toLowerCase()))
            .take(5)
            .toList();
      }
      return [];
    } catch (e) {
      setState(() => _errorMessage = 'è·åå»ºè®®å¤±è´¥: $e');
      return [];
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredFineList.clear();
      _filteredFineList = _fineList.where((fine) {
        final payee = (fine.payee ?? '').toLowerCase();
        final fineDate = _resolvedFineDate(fine);

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty && _searchType == 'payee') {
          matchesQuery = payee.contains(searchQuery);
        }

        bool matchesDateRange = true;
        if (_startDate != null && _endDate != null) {
          if (fineDate == null) {
            matchesDateRange = false;
          } else {
            final inclusiveEnd = _endDate!.add(const Duration(days: 1));
            matchesDateRange =
                !fineDate.isBefore(_startDate!) && fineDate.isBefore(inclusiveEnd);
          }
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredFineList.isEmpty && _fineList.isNotEmpty) {
        _errorMessage = 'æªæ¾å°ç¬¦åæ¡ä»¶çç½æ¬¾ä¿¡æ¯';
      } else {
        _errorMessage =
        _filteredFineList.isEmpty && _fineList.isEmpty ? 'å½åæ²¡æç½æ¬¾è®°å½' : '';
      }
    });
  }

  // ignore: unused_element
  Future<void> _searchFines() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  Future<void> _refreshFines({String? query}) async {
    setState(() {
      _fineList.clear();
      _filteredFineList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startDate = null;
        _endDate = null;
        _searchType = 'payee';
      }
    });
    await _fetchFines(reset: true, query: query);
    if (_errorMessage.isEmpty && _fineList.isNotEmpty) {
      _showSnackBar('ç½æ¬¾åè¡¨å·²å·æ°');
    }
  }

  Future<void> _loadMoreFines() async {
    if (!_isLoading && _hasMore) {
      await _fetchFines();
    }
  }

  void _createFine() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddFinePage()),
    ).then((value) {
      if (value == true) {
        _refreshFines();
      }
    });
  }

  void _editFine(FineInformation fine) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddFinePage(fine: fine, isEditMode: true)),
    ).then((value) {
      if (value == true) {
        _refreshFines();
      }
    });
  }

  void _goToDetailPage(FineInformation fine) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FineDetailPage(fine: fine)),
    ).then((value) {
      if (value == true) {
        _refreshFines();
      }
    });
  }

  Future<void> _deleteFine(int fineId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ç¡®è®¤å é¤'),
        content: const Text('ç¡®å®è¦å é¤æ­¤ç½æ¬¾ä¿¡æ¯åï¼æ­¤æä½ä¸å¯æ¤éã'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('åæ¶'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('å é¤', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (!await _validateJwtToken()) {
          Navigator.pushReplacementNamed(context, AppPages.login);
          return;
        }
        await fineApi.apiFinesFineIdDelete(fineId: fineId);
        _showSnackBar('å é¤ç½æ¬¾æåï¼');
        await _refreshFines();
      } catch (e) {
        _showSnackBar('å é¤ç½æ¬¾å¤±è´¥: $e', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
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

  Widget _buildSearchField(ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty ||
                        _searchType != 'payee') {
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
                    _searchController.text = controller.text;
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      style: TextStyle(color: themeData.colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText:
                        _searchType == 'payee' ? 'æç´¢ç¼´æ¬¾äºº' : 'æç´¢æ¶é´èå´ï¼å·²éæ©ï¼',
                        hintStyle: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search,
                            color: themeData.colorScheme.primary),
                        suffixIcon: controller.text.isNotEmpty ||
                            (_startDate != null && _endDate != null)
                            ? IconButton(
                          icon: Icon(Icons.clear,
                              color:
                              themeData.colorScheme.onSurfaceVariant),
                          onPressed: () {
                            controller.clear();
                            _searchController.clear();
                            setState(() {
                              _startDate = null;
                              _endDate = null;
                              _searchType = 'payee';
                            });
                            _applyFilters('');
                          },
                        )
                            : null,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: themeData.colorScheme.outline
                                  .withValues(alpha: 0.3)),
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
                      onChanged: (value) => _applyFilters(value),
                      onSubmitted: (value) => _applyFilters(value),
                      enabled: _searchType == 'payee',
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
                    _startDate = null;
                    _endDate = null;
                    _applyFilters('');
                  });
                },
                items: <String>['payee', 'timeRange']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'payee' ? 'æç¼´æ¬¾äºº' : 'ææ¶é´èå´',
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
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  _startDate != null && _endDate != null
                      ? 'ç½æ¬¾æ¥æèå´: ${formatDate(_startDate)} è³ ${formatDate(_endDate)}'
                      : 'éæ©ç½æ¬¾æ¥æèå´',
                  style: themeData.textTheme.bodyMedium?.copyWith(
                    color: _startDate != null && _endDate != null
                        ? themeData.colorScheme.onSurface
                        : themeData.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.date_range,
                    color: themeData.colorScheme.primary),
                tooltip: 'æç½æ¬¾æ¥æèå´æç´¢',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: 'éæ©ç½æ¬¾æ¥æèå´',
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
                      _startDate = range.start;
                      _endDate = range.end;
                      _searchType = 'timeRange';
                    });
                    _applyFilters(_searchController.text);
                  }
                },
              ),
              if (_startDate != null && _endDate != null)
                IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  tooltip: 'æ¸
é¤æ¥æèå´',
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _searchType = 'payee';
                    });
                    _applyFilters(_searchController.text);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: 'ç½æ¬¾ç®¡ç',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          if (_isAdmin) ...[
            DashboardPageBarAction(
              icon: Icons.add,
              onPressed: _createFine,
              tooltip: 'æ·»å ç½æ¬¾ä¿¡æ¯',
            ),
            DashboardPageBarAction(
              icon: Icons.refresh,
              onPressed: () => _refreshFines(),
              tooltip: 'å·æ°åè¡¨',
            ),
          ],
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: RefreshIndicator(
          onRefresh: () => _refreshFines(),
          color: themeData.colorScheme.primary,
          backgroundColor: themeData.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildSearchField(themeData),
                const SizedBox(height: 12),
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (scrollInfo) {
                      if (scrollInfo.metrics.pixels ==
                          scrollInfo.metrics.maxScrollExtent &&
                          _hasMore) {
                        _loadMoreFines();
                      }
                      return false;
                    },
                    child: _isLoading && _currentPage == 1
                        ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            themeData.colorScheme.primary),
                      ),
                    )
                        : _errorMessage.isNotEmpty && _filteredFineList.isEmpty
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
                          if (_errorMessage.contains('è·åç½æ¬¾ä¿¡æ¯å¤±è´¥'))
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 16.0),
                              child: ElevatedButton(
                                onPressed: () => _refreshFines(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  themeData.colorScheme.primary,
                                  foregroundColor:
                                  themeData.colorScheme.onPrimary,
                                ),
                                child: const Text('éè¯'),
                              ),
                            ),
                          if (_errorMessage.contains('è·åç½æ¬¾ä¿¡æ¯å¤±è´¥') &&
                              _cachedFineList.isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 16.0),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _fineList.clear();
                                    _fineList.addAll(_cachedFineList);
                                    _applyFilters(
                                        _searchController.text);
                                    _errorMessage = '';
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  themeData.colorScheme.secondary,
                                  foregroundColor: themeData
                                      .colorScheme.onSecondary,
                                ),
                                child: const Text('æ¢å¤ç¼å­æ°æ®'),
                              ),
                            ),
                          if (_errorMessage.contains('æªææ') ||
                              _errorMessage.contains('ç»å½'))
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 16.0),
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.pushReplacementNamed(
                                        context, AppPages.login),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  themeData.colorScheme.primary,
                                  foregroundColor:
                                  themeData.colorScheme.onPrimary,
                                ),
                                child: const Text('éæ°ç»å½'),
                              ),
                            ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      controller: _scrollController,
                      itemCount: _filteredFineList.length +
                          (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _filteredFineList.length &&
                            _hasMore) {
                          return const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Center(
                                child: CircularProgressIndicator()),
                          );
                        }
                        final fijne = _filteredFineList[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0),
                          elevation: 3,
                          color:
                          themeData.colorScheme.surfaceContainer,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(16.0)),
                          child: ListTile(
                            contentPadding:
                            const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            title: Text(
                              'éé¢: ${fijne.fineAmount ?? 0} å
',
                              style: themeData.textTheme.titleMedium
                                  ?.copyWith(
                                color:
                                themeData.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'ç¼´æ¬¾äºº: ${fijne.payee ?? 'æªç¥'}',
                                  style: themeData
                                      .textTheme.bodyMedium
                                      ?.copyWith(
                                    color: themeData
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'æ¶é´: ${formatDate(_resolvedFineDate(fijne))}',
                                  style: themeData
                                      .textTheme.bodyMedium
                                      ?.copyWith(
                                    color: themeData
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  'ç¶æ: ${fijne.status ?? 'æ­£å¨å¤ç'}',
                                  style: themeData
                                      .textTheme.bodyMedium
                                      ?.copyWith(
                                    color: themeData
                                        .colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit,
                                      size: 18,
                                      color: themeData
                                          .colorScheme.primary),
                                  onPressed: () => _editFine(fijne),
                                  tooltip: 'ç¼è¾ç½æ¬¾',
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete,
                                      size: 18,
                                      color: themeData
                                          .colorScheme.error),
                                  onPressed: () =>
                                      _deleteFine(fijne.fineId ?? 0),
                                  tooltip: 'å é¤ç½æ¬¾',
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: themeData
                                      .colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                              ],
                            ),
                            onTap: () => _goToDetailPage(fijne),
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
    });
  }
}

class AddFinePage extends StatefulWidget {
  final FineInformation? fine;
  final bool isEditMode;

  const AddFinePage({super.key, this.fine, this.isEditMode = false});

  @override
  State<AddFinePage> createState() => _AddFinePageState();
}

class _AddFinePageState extends State<AddFinePage> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  final OffenseInformationControllerApi offenseApi =
  OffenseInformationControllerApi();
  final VehicleInformationControllerApi vehicleApi =
  VehicleInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _plateNumberController = TextEditingController();
  final _fineAmountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _bankController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _remarksController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();
  int? _selectedOffenseId;

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.fine != null) {
      _prepopulateFields(widget.fine!);
    }
    _initialize();
  }

  void _prepopulateFields(FineInformation fine) {
    _plateNumberController.text = ''; // Plate number not stored in FineInformation
    _fineAmountController.text = fine.fineAmount?.toString() ?? '';
    _payeeController.text = fine.payee ?? '';
    _accountNumberController.text = fine.accountNumber ?? '';
    _bankController.text = fine.bank ?? '';
    _receiptNumberController.text = fine.receiptNumber ?? '';
    _remarksController.text = fine.remarks ?? '';
    _dateController.text = fine.fineTime != null
        ? formatDate(DateTime.parse(fine.fineTime!))
        : '';
    _selectedOffenseId = fine.offenseId;
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      _showSnackBar('æªææï¼è¯·éæ°ç»å½', isError: true);
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        _showSnackBar('ç»å½å·²è¿æï¼è¯·éæ°ç»å½', isError: true);
        return false;
      }
      return true;
    } catch (e) {
      _showSnackBar('æ æçç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½', isError: true);
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      await fineApi.initializeWithJwt();
      await offenseApi.initializeWithJwt();
      await vehicleApi.initializeWithJwt();
    } catch (e) {
      _showSnackBar('åå§åå¤±è´¥: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _plateNumberController.dispose();
    _fineAmountController.dispose();
    _payeeController.dispose();
    _accountNumberController.dispose();
    _bankController.dispose();
    _receiptNumberController.dispose();
    _remarksController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<List<String>> _fetchLicensePlateSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return [];
      }
      return await vehicleApi.apiVehiclesSearchLicenseGlobalGet(
        prefix: prefix,
        size: 10,
      );
    } catch (e) {
      _showSnackBar('è·åè½¦çå·å»ºè®®å¤±è´¥: $e', isError: true);
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPayeeSuggestions(
      String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return [];
      }
      if (prefix.trim().isEmpty) return [];
      final offenses = await offenseApi.apiOffensesByDriverNameGet(
        query: prefix.trim(),
        page: 1,
        size: 10,
      );
      return offenses
          .where((o) => o.driverName != null && o.driverName!.isNotEmpty)
          .map((o) => {
        'payee': o.driverName!,
        'offenseId': o.offenseId ?? 0,
        'fineAmount': o.fineAmount ?? 0.0,
        'licensePlate': o.licensePlate ?? '',
      })
          .where(
              (item) => item['payee'].toString().contains(prefix.toLowerCase()))
          .toList();
    } catch (e) {
      if (e is ApiException && e.code == 400 && prefix.trim().isEmpty) {
        return [];
      }
      _showSnackBar('è·åç¼´æ¬¾äººå»ºè®®å¤±è´¥: $e', isError: true);
      return [];
    }
  }

  Future<void> _onLicensePlateSelected(String licensePlate) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final offenses = await offenseApi.apiOffensesByLicensePlateGet(
        query: licensePlate,
        page: 1,
        size: 10,
      );
      if (offenses.isNotEmpty) {
        final latestOffense = offenses.first;
        setState(() {
          _selectedOffenseId = latestOffense.offenseId;
          _payeeController.text = latestOffense.driverName ?? '';
          _fineAmountController.text =
              latestOffense.fineAmount?.toString() ?? '';
        });
      } else {
        _showSnackBar('æªæ¾å°ä¸æ­¤è½¦çç¸å
³çè¿æ³è®°å½', isError: true);
        setState(() {
          _selectedOffenseId = null;
          _payeeController.clear();
          _fineAmountController.clear();
        });
      }
    } catch (e) {
      _showSnackBar('è·åè¿æ³ä¿¡æ¯å¤±è´¥: $e', isError: true);
    }
  }

  Future<void> _onPayeeSelected(Map<String, dynamic> payeeData) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      if (payeeData['offenseId'] == 0) {
        _showSnackBar('æ æçè¿æ³è®°å½', isError: true);
        return;
      }
      setState(() {
        _payeeController.text = payeeData['payee'];
        _selectedOffenseId = payeeData['offenseId'];
        _fineAmountController.text = payeeData['fineAmount']?.toString() ?? '';
        _plateNumberController.text = payeeData['licensePlate'].isNotEmpty
            ? payeeData['licensePlate']
            : _plateNumberController.text;
      });
    } catch (e) {
      _showSnackBar('å è½½ç¼´æ¬¾äººä¿¡æ¯å¤±è´¥: $e', isError: true);
    }
  }

  Future<void> _submitFine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedOffenseId == null) {
      _showSnackBar('è¯·å
éæ©ææçè¿æ³è®°å½', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, AppPages.login);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final idempotencyKey = generateIdempotencyKey();
      final finePayload = FineInformation(
        fineId: widget.isEditMode ? widget.fine?.fineId : null,
        offenseId: _selectedOffenseId!,
        fineAmount: double.tryParse(_fineAmountController.text.trim()) ?? 0.0,
        payee: _payeeController.text.trim(),
        accountNumber: _accountNumberController.text.trim().isEmpty
            ? null
            : _accountNumberController.text.trim(),
        bank: _bankController.text.trim().isEmpty
            ? null
            : _bankController.text.trim(),
        receiptNumber: _receiptNumberController.text.trim().isEmpty
            ? null
            : _receiptNumberController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty
            ? null
            : _remarksController.text.trim(),
        fineTime: _dateController.text.isNotEmpty
            ? DateTime.parse("${_dateController.text.trim()}T00:00:00.000")
            .toIso8601String()
            : null,
        status: widget.isEditMode ? widget.fine?.status : 'æ­£å¨å¤ç',
        idempotencyKey: idempotencyKey,
      );
      if (widget.isEditMode) {
        await fineApi.apiFinesFineIdPut(
          fineId: finePayload.fineId ?? 0,
          fineInformation: finePayload,
          idempotencyKey: idempotencyKey,
        );
        _showSnackBar('æ´æ°ç½æ¬¾æåï¼');
      } else {
        await fineApi.apiFinesPost(
          fineInformation: finePayload,
          idempotencyKey: idempotencyKey,
        );
        _showSnackBar('åå»ºç½æ¬¾æåï¼');
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackBar(
          '${widget.isEditMode ? 'æ´æ°' : 'åå»º'}ç½æ¬¾å¤±è´¥: ${e.message}',
          isError: true);
    } catch (e) {
      _showSnackBar(
          '${widget.isEditMode ? 'æ´æ°' : 'åå»º'}ç½æ¬¾å¤±è´¥: $e',
          isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: widget.isEditMode && widget.fine?.fineTime != null
          ? DateTime.parse(widget.fine!.fineTime!)
          : DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: controller.currentBodyTheme.value.copyWith(
          colorScheme: controller.currentBodyTheme.value.colorScheme.copyWith(
            primary: controller.currentBodyTheme.value.colorScheme.primary,
            onPrimary: controller.currentBodyTheme.value.colorScheme.onPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (pickedDate != null && mounted) {
      setState(() => _dateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
        bool readOnly = false,
        VoidCallback? onTap,
        bool required = false,
        int? maxLength,
        String? Function(String?)? validator}) {
    if (label == 'è½¦çå·' || label == 'ç¼´æ¬¾äºº') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Autocomplete<Map<String, dynamic>>(
          optionsBuilder: (TextEditingValue textEditingValue) async {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<Map<String, dynamic>>.empty();
            }
            final suggestions = label == 'è½¦çå·'
                ? (await _fetchLicensePlateSuggestions(textEditingValue.text))
                .map((s) => {'value': s})
                .toList()
                : await _fetchPayeeSuggestions(textEditingValue.text);
            return suggestions;
          },
          displayStringForOption: (Map<String, dynamic> option) =>
          label == 'è½¦çå·' ? option['value'] : option['payee'],
          onSelected: (Map<String, dynamic> selection) async {
            if (label == 'è½¦çå·') {
              controller.text = selection['value'];
              await _onLicensePlateSelected(selection['value']);
            } else {
              await _onPayeeSelected(selection);
            }
          },
          fieldViewBuilder:
              (context, textEditingController, focusNode, onFieldSubmitted) {
            textEditingController.text = controller.text;
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              style: TextStyle(color: themeData.colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                TextStyle(color: themeData.colorScheme.onSurfaceVariant),
                helperText: label == 'è½¦çå·' ? 'è¯·è¾å
¥è½¦çå·ï¼ä¾å¦ï¼é»AWS34' : null,
                helperStyle: TextStyle(
                    color: themeData.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0)),
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.outline.withValues(alpha: 0.3))),
                focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: themeData.colorScheme.primary, width: 1.5)),
                filled: true,
                fillColor: themeData.colorScheme.surfaceContainerLowest,
                suffixIcon: textEditingController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear,
                      color: themeData.colorScheme.onSurfaceVariant),
                  onPressed: () {
                    textEditingController.clear();
                    controller.clear();
                    if (label == 'è½¦çå·' || label == 'ç¼´æ¬¾äºº') {
                      setState(() {
                        _selectedOffenseId = null;
                        if (label == 'è½¦çå·') {
                          _payeeController.clear();
                          _fineAmountController.clear();
                        }
                      });
                    }
                  },
                )
                    : null,
              ),
              keyboardType: keyboardType,
              maxLength: maxLength,
              validator: validator ??
                      (value) {
                    final trimmedValue = value?.trim() ?? '';
                    if (required && trimmedValue.isEmpty) return '$labelä¸è½ä¸ºç©º';
                    if (label == 'è½¦çå·') {
                      if (trimmedValue.isEmpty) return 'è½¦çå·ä¸è½ä¸ºç©º';
                      if (trimmedValue.length > 20) return 'è½¦çå·ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                      if (!RegExp(r'^[\u4e00-\u9fa5][A-Za-z0-9]{5,7}$')
                          .hasMatch(trimmedValue)) {
                        return 'è¯·è¾å
¥ææè½¦çå·ï¼ä¾å¦ï¼é»AWS34';
                      }
                    }
                    if (label == 'ç¼´æ¬¾äºº' && trimmedValue.length > 100) {
                      return 'ç¼´æ¬¾äººå§åä¸è½è¶
è¿100ä¸ªå­ç¬¦';
                    }
                    return null;
                  },
              onChanged: (value) {
                controller.text = value;
              },
            );
          },
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == 'é¶è¡è´¦å·' ? 'è¯·è¾å
¥é¶è¡è´¦å·ï¼éå¡«ï¼' : null,
          helperStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                  color: themeData.colorScheme.outline.withValues(alpha: 0.3))),
          focusedBorder: OutlineInputBorder(
              borderSide:
              BorderSide(color: themeData.colorScheme.primary, width: 1.5)),
          filled: true,
          fillColor: readOnly
              ? themeData.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : themeData.colorScheme.surfaceContainerLowest,
          suffixIcon: readOnly
              ? Icon(Icons.calendar_today,
              size: 18, color: themeData.colorScheme.primary)
              : null,
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
                (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$labelä¸è½ä¸ºç©º';
              if (label == 'ç½æ¬¾éé¢' && trimmedValue.isNotEmpty) {
                final amount = num.tryParse(trimmedValue);
                if (amount == null) return 'ç½æ¬¾éé¢å¿
é¡»æ¯æ°å­';
                if (amount < 0) return 'ç½æ¬¾éé¢ä¸è½ä¸ºè´æ°';
                if (amount > 99999999.99) return 'ç½æ¬¾éé¢ä¸è½è¶
è¿99999999.99';
                if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(trimmedValue)) {
                  return 'ç½æ¬¾éé¢æå¤ä¿çä¸¤ä½å°æ°';
                }
              }
              if (label == 'é¶è¡è´¦å·' && trimmedValue.length > 50) {
                return 'é¶è¡è´¦å·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'é¶è¡åç§°' && trimmedValue.length > 100) {
                return 'é¶è¡åç§°ä¸è½è¶
è¿100ä¸ªå­ç¬¦';
              }
              if (label == 'æ¶æ®ç¼å·' && trimmedValue.length > 50) {
                return 'æ¶æ®ç¼å·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'å¤æ³¨' && trimmedValue.length > 255) {
                return 'å¤æ³¨ä¸è½è¶
è¿255ä¸ªå­ç¬¦';
              }
              if (label == 'ç½æ¬¾æ¥æ' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return 'æ æçæ¥ææ ¼å¼';
                if (date.isAfter(DateTime.now())) {
                  return 'ç½æ¬¾æ¥æä¸è½æäºå½åæ¥æ';
                }
              }
              return null;
            },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      return DashboardPageTemplate(
        theme: themeData,
        title: widget.isEditMode ? 'ç¼è¾ç½æ¬¾' : 'æ·»å æ°ç½æ¬¾',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    elevation: 3,
                    color: themeData.colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildTextField(
                              'è½¦çå·', _plateNumberController, themeData,
                              required: true, maxLength: 20),
                          _buildTextField(
                              'ç½æ¬¾éé¢', _fineAmountController, themeData,
                              keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                              required: true),
                          _buildTextField(
                              'ç¼´æ¬¾äºº', _payeeController, themeData,
                              required: true, maxLength: 100),
                          _buildTextField(
                              'é¶è¡è´¦å·', _accountNumberController, themeData,
                              maxLength: 50),
                          _buildTextField(
                              'é¶è¡åç§°', _bankController, themeData,
                              maxLength: 100),
                          _buildTextField(
                              'æ¶æ®ç¼å·', _receiptNumberController, themeData,
                              maxLength: 50),
                          _buildTextField(
                              'å¤æ³¨', _remarksController, themeData,
                              maxLength: 255),
                          _buildTextField(
                              'ç½æ¬¾æ¥æ', _dateController, themeData,
                              readOnly: true,
                              onTap: _pickDate,
                              required: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitFine,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeData.colorScheme.primary,
                      foregroundColor: themeData.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14.0, horizontal: 20.0),
                      textStyle: themeData.textTheme.labelLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    child: Text(widget.isEditMode ? 'ä¿å­' : 'æäº¤'),
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


class FineDetailPage extends StatefulWidget {
  final FineInformation fine;

  const FineDetailPage({super.key, required this.fine});

  @override
  State<FineDetailPage> createState() => _FineDetailPageState();
}

class _FineDetailPageState extends State<FineDetailPage> {
  final FineInformationControllerApi fineApi = FineInformationControllerApi();
  bool _isLoading = false;
  bool _isAdmin = false;
  String _errorMessage = '';
  final DashboardController controller = Get.find<DashboardController>();
  late FineInformation _currentFine;

  @override
  void initState() {
    super.initState();
    _currentFine = widget.fine;
    _initialize();
  }

  Future<bool> _validateJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final jwtToken = (await AuthTokenStore.instance.getJwtToken());
    if (jwtToken == null || jwtToken.isEmpty) {
      setState(() => _errorMessage = 'æªææï¼è¯·éæ°ç»å½');
      return false;
    }
    try {
      if (JwtDecoder.isExpired(jwtToken)) {
        setState(() => _errorMessage = 'ç»å½å·²è¿æï¼è¯·éæ°ç»å½');
        return false;
      }
      return true;
    } catch (e) {
      setState(() => _errorMessage = 'æ æçç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½');
      return false;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      await fineApi.initializeWithJwt();
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = 'åå§åå¤±è´¥: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      if (jwtToken == null) throw Exception('æªæ¾å° JWTï¼è¯·éæ°ç»å½');
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final userData = jsonDecode(utf8.decode(response.bodyBytes));
        final roles = (userData['roles'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
            [];
        setState(() => _isAdmin = roles.contains('ADMIN'));
      } else {
        throw Exception('éªè¯å¤±è´¥ï¼${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'å è½½æéå¤±è´¥: $e');
    }
  }

  Future<void> _updateFineStatus(int fineId, String status) async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, AppPages.login);
        return;
      }
      final idempotencyKey = const Uuid().v4();
      final updatedFine = FineInformation(
        fineId: _currentFine.fineId,
        offenseId: _currentFine.offenseId,
        fineAmount: _currentFine.fineAmount,
        payee: _currentFine.payee,
        fineTime: _currentFine.fineTime,
        accountNumber: _currentFine.accountNumber,
        bank: _currentFine.bank,
        receiptNumber: _currentFine.receiptNumber,
        status: status,
        remarks: _currentFine.remarks,
        idempotencyKey: idempotencyKey,
      );
      final result = await fineApi.apiFinesFineIdPut(
        fineId: fineId,
        fineInformation: updatedFine,
        idempotencyKey: idempotencyKey,
      );
      setState(() => _currentFine = result);
      _showSnackBar('ç½æ¬¾è®°å½å·²${status == 'Approved' ? 'æ¹å' : 'æç»'}');
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      _showSnackBar('æ´æ°ç¶æå¤±è´¥: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('æ´æ°ç¶æå¤±è´¥: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteFine(int fineId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ç¡®è®¤å é¤'),
        content: const Text('ç¡®å®è¦å é¤æ­¤ç½æ¬¾ä¿¡æ¯åï¼æ­¤æä½ä¸å¯æ¤éã'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('åæ¶'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('å é¤', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        if (!await _validateJwtToken()) {
          Navigator.pushReplacementNamed(context, AppPages.login);
          return;
        }
        await fineApi.apiFinesFineIdDelete(fineId: fineId);
        _showSnackBar('ç½æ¬¾å é¤æåï¼');
        if (mounted) Navigator.pop(context, true);
      } on ApiException catch (e) {
        _showSnackBar('å é¤å¤±è´¥: ${e.message}', isError: true);
      } catch (e) {
        _showSnackBar('å é¤å¤±è´¥: $e', isError: true);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _editFine() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddFinePage(
          fine: _currentFine,
          isEditMode: true,
        ),
      ),
    ).then((value) {
      if (value == true) {
        Navigator.pop(context, true); // Trigger refresh in FineList
      }
    });
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

  Widget _buildDetailRow(String label, String value, ThemeData themeData) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: themeData.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: themeData.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: themeData.textTheme.bodyMedium?.copyWith(
                color: themeData.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'æªç¥';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      if (_errorMessage.isNotEmpty) {
        return DashboardPageTemplate(
          theme: themeData,
          title: 'ç½æ¬¾è¯¦æ
',
          pageType: DashboardPageType.manager,
          bodyIsScrollable: true,
          padding: EdgeInsets.zero,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _errorMessage,
                  style: themeData.textTheme.titleMedium?.copyWith(
                    color: themeData.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_errorMessage.contains('æªææ') ||
                    _errorMessage.contains('ç»å½'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppPages.login),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeData.colorScheme.primary,
                        foregroundColor: themeData.colorScheme.onPrimary,
                      ),
                      child: const Text('éæ°ç»å½'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      return DashboardPageTemplate(
        theme: themeData,
        title: 'ç½æ¬¾è¯¦æ
',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          if (_isAdmin) ...[
            DashboardPageBarAction(
              icon: Icons.edit,
              onPressed: _editFine,
              tooltip: 'ç¼è¾ç½æ¬¾',
            ),
            if (_currentFine.status == 'æ­£å¨å¤ç') ...[
              DashboardPageBarAction(
                icon: Icons.check,
                onPressed: () => _updateFineStatus(
                    _currentFine.fineId ?? 0, 'æ¹å'),
                tooltip: 'æ¹åç½æ¬¾',
              ),
              DashboardPageBarAction(
                icon: Icons.close,
                onPressed: () => _updateFineStatus(
                    _currentFine.fineId ?? 0, 'é©³å'),
                tooltip: 'æç»ç½æ¬¾',
              ),
            ],
            DashboardPageBarAction(
              icon: Icons.delete,
              color: themeData.colorScheme.error,
              onPressed: () => _deleteFine(_currentFine.fineId ?? 0),
              tooltip: 'å é¤ç½æ¬¾',
            ),
          ],
        ],
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation(themeData.colorScheme.primary),
          ),
        )
            : Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 3,
            color: themeData.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      'ç½æ¬¾éé¢',
                      '${_currentFine.fineAmount ?? 0} å
',
                      themeData,
                    ),
                    _buildDetailRow(
                      'ç¼´æ¬¾äºº',
                      _currentFine.payee ?? 'æªç¥',
                      themeData,
                    ),
                    _buildDetailRow(
                      'ç½æ¬¾æ¶é´',
                      formatDate(_resolvedFineDate(_currentFine)),
                      themeData,
                    ),
                    _buildDetailRow(
                      'ç¶æ',
                      _currentFine.status ?? 'æ­£å¨å¤ç',
                      themeData,
                    ),
                    _buildDetailRow(
                      'é¶è¡è´¦å·',
                      _currentFine.accountNumber ?? 'æ ',
                      themeData,
                    ),
                    _buildDetailRow(
                      'é¶è¡åç§°',
                      _currentFine.bank ?? 'æ ',
                      themeData,
                    ),
                    _buildDetailRow(
                      'æ¶æ®ç¼å·',
                      _currentFine.receiptNumber ?? 'æ ',
                      themeData,
                    ),
                    _buildDetailRow(
                      'å¤æ³¨',
                      _currentFine.remarks ?? 'æ ',
                      themeData,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
