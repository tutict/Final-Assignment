// ignore_for_file: use_build_context_synchronously
import 'dart:convert';

import 'package:final_assignment_front/features/api/driver_information_controller_api.dart';
import 'package:final_assignment_front/features/api/vehicle_information_controller_api.dart';
import 'package:final_assignment_front/features/dashboard/views/manager/manager_dashboard_screen.dart';
import 'package:final_assignment_front/features/dashboard/views/shared/widgets/dashboard_page_template.dart';
import 'package:final_assignment_front/features/model/driver_information.dart';
import 'package:final_assignment_front/features/model/user_management.dart';
import 'package:final_assignment_front/features/model/vehicle_information.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:final_assignment_front/utils/services/auth_token_store.dart';

// Utility methods for validation
bool isValidLicensePlate(String value) {
  final regex = RegExp(r'^[\u4e00-\u9fa5][A-Za-z][A-Za-z0-9]{5,6}$');
  return regex.hasMatch(value);
}

bool isValidIdCardNumber(String value) {
  final regex = RegExp(r'^\d{15}$|^\d{17}[\dX]$');
  return regex.hasMatch(value);
}

bool isValidPhoneNumber(String value) {
  final regex = RegExp(r'^1[3-9]\d{9}$');
  return regex.hasMatch(value);
}

String generateIdempotencyKey() {
  return DateTime.now().millisecondsSinceEpoch.toString();
}

String formatDate(DateTime? date) {
  if (date == null) return 'æªè®¾ç½®';
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

class VehicleList extends StatefulWidget {
  const VehicleList({super.key});

  @override
  State<VehicleList> createState() => _VehicleListState();
}

class _VehicleListState extends State<VehicleList> {
  final DashboardController controller = Get.find<DashboardController>();
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final TextEditingController _searchController = TextEditingController();
  final List<VehicleInformation> _vehicleList = [];
  List<VehicleInformation> _filteredVehicleList = [];
  String _searchType = 'licensePlate';
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isAdmin = false;
  DateTime? _startDate;
  DateTime? _endDate;

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
    debugPrint('Retrieved JWT: $jwtToken');
    if (jwtToken == null || jwtToken.isEmpty) {
      debugPrint('JWT token not found or empty');
      setState(() => _errorMessage = 'æªææï¼è¯·éæ°ç»å½');
      return false;
    }
    try {
      final decodedToken = JwtDecoder.decode(jwtToken);
      debugPrint('Decoded JWT: $decodedToken');
      if (JwtDecoder.isExpired(jwtToken)) {
        debugPrint('JWT token is expired: ${decodedToken['exp']}');
        jwtToken = await _refreshJwtToken();
        if (jwtToken == null) {
          setState(() => _errorMessage = 'ç»å½å·²è¿æï¼è¯·éæ°ç»å½');
          return false;
        }
        await AuthTokenStore.instance.setJwtToken(jwtToken);
        final newDecodedToken = JwtDecoder.decode(jwtToken);
        debugPrint('New JWT decoded: $newDecodedToken');
        if (JwtDecoder.isExpired(jwtToken)) {
          setState(() => _errorMessage = 'æ°ç»å½ä¿¡æ¯å·²è¿æï¼è¯·éæ°ç»å½');
          return false;
        }
        await vehicleApi.initializeWithJwt();
      }
      debugPrint('JWT token is valid. Subject: ${decodedToken['sub']}');
      return true;
    } catch (e) {
      debugPrint('JWT decode error: $e');
      setState(() => _errorMessage = 'æ æçç»å½ä¿¡æ¯ï¼è¯·éæ°ç»å½');
      return false;
    }
  }

  Future<String?> _refreshJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null) {
      debugPrint('Refresh token not found');
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
        debugPrint('Refreshed JWT: $newJwt');
        return newJwt;
      }
      debugPrint(
          'Failed to refresh JWT: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Refresh token error: $e');
      return null;
    }
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await vehicleApi.initializeWithJwt(); // ç¡®ä¿åå§å JWT
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken())!;
      final decodedToken = JwtDecoder.decode(jwtToken);
      _isAdmin = decodedToken['roles'] == 'ADMIN'; // ä¿®æ­£å­æ®µå
      await _checkUserRole();
      await _fetchVehicles(reset: true);
    } catch (e) {
      setState(() {
        _errorMessage = 'åå§åå¤±è´¥: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
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
            (JwtDecoder.decode(jwtToken)['roles'] is String
                ? [JwtDecoder.decode(jwtToken)['roles']]
                : []);
        debugPrint('User roles from /api/users/me: $roles');
        debugPrint('Full userData: $userData');
        setState(() => _isAdmin = roles.contains('ADMIN')); // Changed to ADMIN
      } else {
        debugPrint(
            'Role check failed: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('éªè¯å¤±è´¥ï¼${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking role: $e');
      setState(() => _errorMessage = 'éªè¯è§è²å¤±è´¥: $e');
    }
  }

  Future<void> _fetchVehicles({bool reset = false, String? query}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
      _vehicleList.clear();
      _filteredVehicleList.clear();
    }
    if (!_hasMore) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      List<VehicleInformation> vehicles =
          await vehicleApi.apiVehiclesGet(); // æ åé¡µåæ°

      setState(() {
        _vehicleList.addAll(vehicles);
        _hasMore = false; // åç«¯è¿åå
¨éæ°æ®ï¼æ éåé¡µ
        _applyFilters(query ?? _searchController.text);
        if (_filteredVehicleList.isEmpty) {
          _errorMessage = query?.isNotEmpty ??
                  false || (_startDate != null && _endDate != null)
              ? 'æªæ¾å°ç¬¦åæ¡ä»¶çè½¦è¾'
              : 'å½åæ²¡æè½¦è¾è®°å½';
        }
        _currentPage++;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('403')) {
          _errorMessage = 'æªææï¼è¯·éæ°ç»å½';
          Navigator.pushReplacementNamed(context, '/login');
        } else if (e.toString().contains('404')) {
          _vehicleList.clear();
          _filteredVehicleList.clear();
          _errorMessage = 'æªæ¾å°è½¦è¾è®°å½';
          _hasMore = false;
        } else {
          _errorMessage = 'è·åè½¦è¾ä¿¡æ¯å¤±è´¥: $e';
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _fetchAutocompleteSuggestions(String prefix) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return [];
      }
      if (_searchType == 'licensePlate') {
        final suggestions = await vehicleApi.apiVehiclesSearchLicenseGlobalGet(
          prefix: prefix,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      } else {
        final suggestions =
            await vehicleApi.apiVehiclesAutocompleteTypesGlobalGet(
          prefix: prefix,
        );
        return suggestions
            .where((s) => s.toLowerCase().contains(prefix.toLowerCase()))
            .toList();
      }
    } catch (e) {
      setState(() => _errorMessage = 'è·åå»ºè®®å¤±è´¥: $e');
      return [];
    }
  }

  void _applyFilters(String query) {
    final searchQuery = query.trim().toLowerCase();
    setState(() {
      _filteredVehicleList.clear();
      _filteredVehicleList = _vehicleList.where((vehicle) {
        final licensePlate = (vehicle.licensePlate ?? '').toLowerCase();
        final vehicleType = (vehicle.vehicleType ?? '').toLowerCase();
        final registrationDate = vehicle.firstRegistrationDate;

        bool matchesQuery = true;
        if (searchQuery.isNotEmpty) {
          if (_searchType == 'licensePlate') {
            matchesQuery = licensePlate.contains(searchQuery);
          } else if (_searchType == 'vehicleType') {
            matchesQuery = vehicleType.contains(searchQuery);
          }
        }

        bool matchesDateRange = true;
        if (_startDate != null &&
            _endDate != null &&
            registrationDate != null) {
          matchesDateRange = registrationDate.isAfter(_startDate!) &&
              registrationDate.isBefore(_endDate!.add(const Duration(days: 1)));
        } else if (_startDate != null &&
            _endDate != null &&
            registrationDate == null) {
          matchesDateRange = false;
        }

        return matchesQuery && matchesDateRange;
      }).toList();

      if (_filteredVehicleList.isEmpty && _vehicleList.isNotEmpty) {
        _errorMessage = 'æªæ¾å°ç¬¦åæ¡ä»¶çè½¦è¾';
      } else {
        _errorMessage = _filteredVehicleList.isEmpty && _vehicleList.isEmpty
            ? 'å½åæ²¡æè½¦è¾è®°å½'
            : '';
      }
    });
  }

  // ignore: unused_element
  Future<void> _searchVehicles() async {
    final query = _searchController.text.trim();
    _applyFilters(query);
  }

  Future<void> _refreshVehicleList({String? query}) async {
    setState(() {
      _vehicleList.clear();
      _filteredVehicleList.clear();
      _currentPage = 1;
      _hasMore = true;
      _isLoading = true;
      if (query == null) {
        _searchController.clear();
        _startDate = null;
        _endDate = null;
        _searchType = 'licensePlate';
      }
    });
    await _fetchVehicles(reset: true, query: query);
  }

  Future<void> _loadMoreVehicles() async {
    if (!_isLoading && _hasMore) {
      await _fetchVehicles();
    }
  }

  void _goToDetailPage(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VehicleDetailPage(vehicle: vehicle),
      ),
    );
  }

  void _createVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddVehiclePage()),
    ).then((value) {
      if (value == true) {
        _refreshVehicleList();
      }
    });
  }

  void _editVehicle(VehicleInformation vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehiclePage(vehicle: vehicle),
      ),
    ).then((value) {
      if (value == true) {
        _refreshVehicleList();
      }
    });
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ç¡®è®¤å é¤'),
        content: const Text('ç¡®å®è¦å é¤æ­¤è½¦è¾ä¿¡æ¯åï¼æ­¤æä½ä¸å¯æ¤éã'),
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
          Navigator.pushReplacementNamed(context, '/login');
          return;
        }
        await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
        await _refreshVehicleList();
      } catch (e) {
        setState(() {
          _errorMessage = 'å é¤è½¦è¾å¤±è´¥: $e';
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
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
                    if (textEditingValue.text.isEmpty) {
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
                            _searchType == 'licensePlate' ? 'æç´¢è½¦çå·' : 'æç´¢è½¦è¾ç±»å',
                        hintStyle: TextStyle(
                            color: themeData.colorScheme.onSurface
                                .withValues(alpha: 0.6)),
                        prefixIcon: Icon(Icons.search,
                            color: themeData.colorScheme.primary),
                        suffixIcon: controller.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color:
                                        themeData.colorScheme.onSurfaceVariant),
                                onPressed: () {
                                  controller.clear();
                                  _searchController.clear();
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
                items: <String>['licensePlate', 'vehicleType']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value == 'licensePlate' ? 'æè½¦çå·' : 'æè½¦è¾ç±»å',
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
                      ? 'é¦æ¬¡æ³¨åæ¥æ: ${formatDate(_startDate)} è³ ${formatDate(_endDate)}'
                      : 'éæ©é¦æ¬¡æ³¨åæ¥æèå´',
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
                tooltip: 'æé¦æ¬¡æ³¨åæ¥æèå´æç´¢',
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    locale: const Locale('zh', 'CN'),
                    helpText: 'éæ©é¦æ¬¡æ³¨åæ¥æèå´',
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
        title: 'è½¦è¾ç®¡ç',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          if (_isAdmin) ...[
            DashboardPageBarAction(
              icon: Icons.add,
              onPressed: _createVehicle,
              tooltip: 'æ·»å è½¦è¾',
            ),
            DashboardPageBarAction(
              icon: Icons.refresh,
              onPressed: () => _refreshVehicleList(),
              tooltip: 'å·æ°åè¡¨',
            ),
          ],
        ],
        onThemeToggle: controller.toggleBodyTheme,
        body: RefreshIndicator(
          onRefresh: () => _refreshVehicleList(),
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
                        _loadMoreVehicles();
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
                        : _errorMessage.isNotEmpty &&
                                _filteredVehicleList.isEmpty
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
                                    if (_errorMessage.contains('æªææ') ||
                                        _errorMessage.contains('ç»å½'))
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 16.0),
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
                                          child: const Text('éæ°ç»å½'),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredVehicleList.length +
                                    (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == _filteredVehicleList.length &&
                                      _hasMore) {
                                    return const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  final vehicle = _filteredVehicleList[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    elevation: 3,
                                    color:
                                        themeData.colorScheme.surfaceContainer,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16.0, vertical: 12.0),
                                      title: Text(
                                        'è½¦çå·: ${vehicle.licensePlate ?? 'æªç¥è½¦ç'}',
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
                                            'ç±»å: ${vehicle.vehicleType ?? 'æªç¥ç±»å'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'è½¦ä¸»: ${vehicle.ownerName ?? 'æªç¥è½¦ä¸»'}',
                                            style: themeData
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          Text(
                                            'ç¶æ: ${vehicle.currentStatus ?? 'æ '}',
                                            style: themeData
                                                .textTheme.bodyMedium
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
                                                  icon: const Icon(Icons.edit,
                                                      size: 18),
                                                  color: themeData
                                                      .colorScheme.primary,
                                                  onPressed: () =>
                                                      _editVehicle(vehicle),
                                                  tooltip: 'ç¼è¾è½¦è¾',
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    size: 18,
                                                    color: themeData
                                                        .colorScheme.error,
                                                  ),
                                                  onPressed: () {
                                                    final vehicleId =
                                                        vehicle.vehicleId;
                                                    if (vehicleId == null) {
                                                      _showSnackBar(
                                                          'æ æ³å é¤ï¼ç¼ºå°è½¦è¾ID',
                                                          isError: true);
                                                      return;
                                                    }
                                                    _deleteVehicle(vehicleId);
                                                  },
                                                  tooltip: 'å é¤è½¦è¾',
                                                ),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  color: themeData.colorScheme
                                                      .onSurfaceVariant,
                                                  size: 18,
                                                ),
                                              ],
                                            )
                                          : Icon(
                                              Icons.arrow_forward_ios,
                                              color: themeData
                                                  .colorScheme.onSurfaceVariant,
                                              size: 18,
                                            ),
                                      onTap: () => _goToDetailPage(vehicle),
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
}

class AddVehiclePage extends StatefulWidget {
  final VoidCallback? onVehicleAdded;

  const AddVehiclePage({super.key, this.onVehicleAdded});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _firstRegistrationDateController = TextEditingController();
  final _currentStatusController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();

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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      if (jwtToken == null) throw Exception('æªæ¾å° JWT');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT ä¸­æªæ¾å°ç¨æ·å');
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      setState(() {
        _contactNumberController.text = '';
      });
    } catch (e) {
      _showSnackBar('åå§åå¤±è´¥: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _engineNumberController.dispose();
    _frameNumberController.dispose();
    _vehicleColorController.dispose();
    _firstRegistrationDateController.dispose();
    _currentStatusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    final licensePlate = 'é»A${_licensePlateController.text.trim()}';
    if (!isValidLicensePlate(licensePlate)) {
      _showSnackBar('è½¦çå·æ ¼å¼æ æï¼è¯·è¾å
¥ææè½¦çå·ï¼ä¾å¦ï¼é»A12345ï¼', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (await vehicleApi.apiVehiclesExistsLicensePlateGet(
        licensePlate: licensePlate)) {
      _showSnackBar('è½¦çå·å·²å­å¨ï¼è¯·ä½¿ç¨å
¶ä»è½¦çå·', isError: true);
      return;
    }
    final idCardNumber = _idCardNumberController.text.trim();
    if (!isValidIdCardNumber(idCardNumber)) {
      _showSnackBar('èº«ä»½è¯å·ç æ ¼å¼æ æï¼è¯·è¾å
¥ææç15æ18ä½èº«ä»½è¯å·ç ', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final vehiclePayload = {
        'vehicleId': null,
        'licensePlate': licensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'idCardNumber': idCardNumber,
        'contactNumber': _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        'engineNumber': _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        'frameNumber': _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        'firstRegistrationDate': _firstRegistrationDateController.text.isEmpty
            ? null
            : '${_firstRegistrationDateController.text.trim()}T00:00:00.000',
        'currentStatus': _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      };
      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      final response = await http.post(
        Uri.parse(
            'http://localhost:8081/api/vehicles?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(vehiclePayload),
      );
      if (response.statusCode != 201) {
        throw Exception(
            'Failed to create vehicle: ${response.statusCode} - ${response.body}');
      }
      _showSnackBar('åå»ºè½¦è¾æåï¼');
      if (mounted) {
        Navigator.pop(context, true);
        widget.onVehicleAdded?.call();
      }
    } catch (e) {
      _showSnackBar('åå»ºè½¦è¾å¤±è´¥: $e', isError: true);
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
                  : themeData.colorScheme.onPrimary),
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
      initialDate: DateTime.now(),
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
      setState(
          () => _firstRegistrationDateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix,
      int? maxLength,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == 'è½¦çå·'
              ? 'è¯·è¾å
¥è½¦çå·åç¼ï¼ä¾å¦ï¼12345'
              : label == 'èº«ä»½è¯å·ç '
                  ? 'è¯·è¾å
¥15æ18ä½èº«ä»½è¯å·ç '
                  : label == 'èç³»çµè¯'
                      ? 'è¯·è¾å
¥11ä½ææºå·ç '
                      : null,
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
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly && label == 'é¦æ¬¡å½å
¥è½¦çå·çæ¥æ'
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
              if (label == 'è½¦çå·' && trimmedValue.isNotEmpty) {
                final fullPlate = 'é»A$trimmedValue';
                if (fullPlate.length > 20) return 'è½¦çå·ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                if (!isValidLicensePlate(fullPlate)) {
                  return 'è½¦çå·æ ¼å¼æ æï¼ä¾å¦ï¼é»A12345ï¼';
                }
              }
              if (label == 'è½¦è¾ç±»å' && trimmedValue.length > 50) {
                return 'è½¦è¾ç±»åä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'è½¦ä¸»å§å' && trimmedValue.length > 100) {
                return 'è½¦ä¸»å§åä¸è½è¶
è¿100ä¸ªå­ç¬¦';
              }
              if (label == 'èº«ä»½è¯å·ç ') {
                if (trimmedValue.isEmpty) return 'èº«ä»½è¯å·ç ä¸è½ä¸ºç©º';
                if (trimmedValue.length > 18) {
                  return 'èº«ä»½è¯å·ç ä¸è½è¶
è¿18ä¸ªå­ç¬¦';
                }
                if (!isValidIdCardNumber(trimmedValue)) {
                  return 'èº«ä»½è¯å·ç æ ¼å¼æ æ';
                }
              }
              if (label == 'èç³»çµè¯' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return 'èç³»çµè¯ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                if (!isValidPhoneNumber(trimmedValue)) {
                  return 'è¯·è¾å
¥ææç11ä½ææºå·ç ';
                }
              }
              if (label == 'åå¨æºå·' && trimmedValue.length > 50) {
                return 'åå¨æºå·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'è½¦æ¶å·' && trimmedValue.length > 50) {
                return 'è½¦æ¶å·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'è½¦èº«é¢è²' && trimmedValue.length > 50) {
                return 'è½¦èº«é¢è²ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'é¦æ¬¡å½å
¥è½¦çå·çæ¥æ' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return 'æ æçæ¥ææ ¼å¼';
                if (date.isAfter(DateTime.now())) {
                  return 'é¦æ¬¡å½å
¥æ¥æä¸è½æäºå½åæ¥æ';
                }
              }
              if (label == 'å½åç¶æ' && trimmedValue.length > 50) {
                return 'å½åç¶æä¸è½è¶
è¿50ä¸ªå­ç¬¦';
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
        title: 'æ·»å æ°è½¦è¾',
        pageType: widget.onVehicleAdded != null
            ? DashboardPageType.custom
            : DashboardPageType.manager,
        appBar: widget.onVehicleAdded != null
            ? null
            : AppBar(
                title: Text('æ·»å æ°è½¦è¾',
                    style: themeData.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: themeData.colorScheme.onPrimaryContainer)),
                backgroundColor: themeData.colorScheme.primaryContainer,
                foregroundColor: themeData.colorScheme.onPrimaryContainer,
                elevation: 2,
              ),
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
                                if (widget.onVehicleAdded != null)
                                  Text(
                                    'æ¨å½åæ²¡æè½¦è¾è®°å½ï¼è¯·æ·»å æ°è½¦è¾',
                                    style: themeData.textTheme.titleMedium
                                        ?.copyWith(
                                            color:
                                                themeData.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold),
                                  ),
                                if (widget.onVehicleAdded != null)
                                  const SizedBox(height: 16),
                                _buildTextField(
                                    'è½¦çå·', _licensePlateController, themeData,
                                    required: true,
                                    prefix: 'é»A',
                                    maxLength: 17),
                                _buildTextField(
                                    'è½¦è¾ç±»å', _vehicleTypeController, themeData,
                                    required: true, maxLength: 50),
                                _buildTextField(
                                    'è½¦ä¸»å§å', _ownerNameController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    'èº«ä»½è¯å·ç ', _idCardNumberController, themeData,
                                    required: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 18),
                                _buildTextField(
                                    'èç³»çµè¯', _contactNumberController, themeData,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 20),
                                _buildTextField(
                                    'åå¨æºå·', _engineNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    'è½¦æ¶å·', _frameNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    'è½¦èº«é¢è²', _vehicleColorController, themeData,
                                    maxLength: 50),
                                _buildTextField('é¦æ¬¡å½å
¥è½¦çå·çæ¥æ',
                                    _firstRegistrationDateController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField(
                                    'å½åç¶æ', _currentStatusController, themeData,
                                    maxLength: 50),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitVehicle,
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
                          child: const Text('æäº¤'),
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

class EditVehiclePage extends StatefulWidget {
  final VehicleInformation vehicle;

  const EditVehiclePage({super.key, required this.vehicle});

  @override
  State<EditVehiclePage> createState() => _EditVehiclePageState();
}

class _EditVehiclePageState extends State<EditVehiclePage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  final DriverInformationControllerApi driverApi =
      DriverInformationControllerApi();
  final _formKey = GlobalKey<FormState>();
  final _licensePlateController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _idCardNumberController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _frameNumberController = TextEditingController();
  final _vehicleColorController = TextEditingController();
  final _firstRegistrationDateController = TextEditingController();
  final _currentStatusController = TextEditingController();
  bool _isLoading = false;
  final DashboardController controller = Get.find<DashboardController>();

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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await vehicleApi.initializeWithJwt();
      await driverApi.initializeWithJwt();
      _initializeFields();
    } catch (e) {
      _showSnackBar('åå§åå¤±è´¥: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _initializeFields() {
    setState(() {
      _licensePlateController.text =
          widget.vehicle.licensePlate?.replaceFirst('é»A', '') ?? '';
      _vehicleTypeController.text = widget.vehicle.vehicleType ?? '';
      _ownerNameController.text = widget.vehicle.ownerName ?? '';
      _idCardNumberController.text = widget.vehicle.idCardNumber ?? '';
      _contactNumberController.text = widget.vehicle.contactNumber ?? '';
      _engineNumberController.text = widget.vehicle.engineNumber ?? '';
      _frameNumberController.text = widget.vehicle.frameNumber ?? '';
      _vehicleColorController.text = widget.vehicle.vehicleColor ?? '';
      _firstRegistrationDateController.text =
          formatDate(widget.vehicle.firstRegistrationDate);
      _currentStatusController.text = widget.vehicle.currentStatus ?? '';
    });
  }

  @override
  void dispose() {
    _licensePlateController.dispose();
    _vehicleTypeController.dispose();
    _ownerNameController.dispose();
    _idCardNumberController.dispose();
    _contactNumberController.dispose();
    _engineNumberController.dispose();
    _frameNumberController.dispose();
    _vehicleColorController.dispose();
    _firstRegistrationDateController.dispose();
    _currentStatusController.dispose();
    super.dispose();
  }

  Future<void> _submitVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    final newLicensePlate = 'é»A${_licensePlateController.text.trim()}';
    if (!isValidLicensePlate(newLicensePlate)) {
      _showSnackBar('è½¦çå·æ ¼å¼æ æï¼è¯·è¾å
¥ææè½¦çå·ï¼ä¾å¦ï¼é»A12345ï¼', isError: true);
      return;
    }
    if (!await _validateJwtToken()) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (newLicensePlate != widget.vehicle.licensePlate &&
        await vehicleApi.apiVehiclesExistsLicensePlateGet(
            licensePlate: newLicensePlate)) {
      _showSnackBar('è½¦çå·å·²å­å¨ï¼è¯·ä½¿ç¨å
¶ä»è½¦çå·', isError: true);
      return;
    }
    final idCardNumber = _idCardNumberController.text.trim();
    if (!isValidIdCardNumber(idCardNumber)) {
      _showSnackBar('èº«ä»½è¯å·ç æ ¼å¼æ æï¼è¯·è¾å
¥ææç15æ18ä½èº«ä»½è¯å·ç ', isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final vehiclePayload = {
        'vehicleId': widget.vehicle.vehicleId,
        'licensePlate': newLicensePlate,
        'vehicleType': _vehicleTypeController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'idCardNumber': idCardNumber,
        'contactNumber': _contactNumberController.text.trim().isEmpty
            ? null
            : _contactNumberController.text.trim(),
        'engineNumber': _engineNumberController.text.trim().isEmpty
            ? null
            : _engineNumberController.text.trim(),
        'frameNumber': _frameNumberController.text.trim().isEmpty
            ? null
            : _frameNumberController.text.trim(),
        'vehicleColor': _vehicleColorController.text.trim().isEmpty
            ? null
            : _vehicleColorController.text.trim(),
        'firstRegistrationDate': _firstRegistrationDateController.text.isEmpty
            ? null
            : '${_firstRegistrationDateController.text.trim()}T00:00:00.000',
        'currentStatus': _currentStatusController.text.trim().isEmpty
            ? 'Active'
            : _currentStatusController.text.trim(),
      };
      final idempotencyKey = generateIdempotencyKey();
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      final response = await http.put(
        Uri.parse(
            'http://localhost:8081/api/vehicles/${widget.vehicle.vehicleId}?idempotencyKey=$idempotencyKey'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(vehiclePayload),
      );
      if (response.statusCode != 200) {
        throw Exception(
            'Failed to update vehicle: ${response.statusCode} - ${response.body}');
      }
      _showSnackBar('æ´æ°è½¦è¾æåï¼');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('æ´æ°è½¦è¾å¤±è´¥: $e', isError: true);
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
                  : themeData.colorScheme.onPrimary),
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
      initialDate: widget.vehicle.firstRegistrationDate ?? DateTime.now(),
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
      setState(
          () => _firstRegistrationDateController.text = formatDate(pickedDate));
    }
  }

  Widget _buildTextField(
      String label, TextEditingController controller, ThemeData themeData,
      {TextInputType? keyboardType,
      bool readOnly = false,
      VoidCallback? onTap,
      bool required = false,
      String? prefix,
      int? maxLength,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: themeData.colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: themeData.colorScheme.onSurfaceVariant),
          helperText: label == 'è½¦çå·'
              ? 'è¯·è¾å
¥è½¦çå·åç¼ï¼ä¾å¦ï¼12345'
              : label == 'èº«ä»½è¯å·ç '
                  ? 'è¯·è¾å
¥15æ18ä½èº«ä»½è¯å·ç '
                  : label == 'èç³»çµè¯'
                      ? 'è¯·è¾å
¥11ä½ææºå·ç '
                      : null,
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
          prefixText: prefix,
          prefixStyle: TextStyle(
              color: themeData.colorScheme.onSurface,
              fontWeight: FontWeight.bold),
          suffixIcon: readOnly && label == 'é¦æ¬¡å½å
¥è½¦çå·çæ¥æ'
              ? Icon(Icons.calendar_today,
                  size: 18, color: themeData.colorScheme.primary)
              : null,
          hintText: readOnly && label == 'èº«ä»½è¯å·ç ' ? 'è¯·å¨ç¨æ·ä¿¡æ¯ç®¡çä¸­ä¿®æ¹èº«ä»½è¯å·ç ' : null,
          hintStyle: TextStyle(
              color: themeData.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
        ),
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLength: maxLength,
        validator: validator ??
            (value) {
              final trimmedValue = value?.trim() ?? '';
              if (required && trimmedValue.isEmpty) return '$labelä¸è½ä¸ºç©º';
              if (label == 'è½¦çå·' && trimmedValue.isNotEmpty) {
                final fullPlate = 'é»A$trimmedValue';
                if (fullPlate.length > 20) return 'è½¦çå·ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                if (!isValidLicensePlate(fullPlate)) {
                  return 'è½¦çå·æ ¼å¼æ æï¼ä¾å¦ï¼é»A12345ï¼';
                }
              }
              if (label == 'è½¦è¾ç±»å' && trimmedValue.length > 50) {
                return 'è½¦è¾ç±»åä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'è½¦ä¸»å§å' && trimmedValue.length > 100) {
                return 'è½¦ä¸»å§åä¸è½è¶
è¿100ä¸ªå­ç¬¦';
              }
              if (label == 'èº«ä»½è¯å·ç ') {
                if (trimmedValue.isEmpty) return 'èº«ä»½è¯å·ç ä¸è½ä¸ºç©º';
                if (trimmedValue.length > 18) {
                  return 'èº«ä»½è¯å·ç ä¸è½è¶
è¿18ä¸ªå­ç¬¦';
                }
                if (!isValidIdCardNumber(trimmedValue)) {
                  return 'èº«ä»½è¯å·ç æ ¼å¼æ æ';
                }
              }
              if (label == 'èç³»çµè¯' && trimmedValue.isNotEmpty) {
                if (trimmedValue.length > 20) return 'èç³»çµè¯ä¸è½è¶
è¿20ä¸ªå­ç¬¦';
                if (!isValidPhoneNumber(trimmedValue)) {
                  return 'è¯·è¾å
¥ææç11ä½ææºå·ç ';
                }
              }
              if (label == 'åå¨æºå·' && trimmedValue.length > 50) {
                return 'åå¨æºå·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'è½¦æ¶å·' && trimmedValue.length > 50) {
                return 'è½¦æ¶å·ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'è½¦èº«é¢è²' && trimmedValue.length > 50) {
                return 'è½¦èº«é¢è²ä¸è½è¶
è¿50ä¸ªå­ç¬¦';
              }
              if (label == 'é¦æ¬¡å½å
¥è½¦çå·çæ¥æ' && trimmedValue.isNotEmpty) {
                final date = DateTime.tryParse('$trimmedValue 00:00:00.000');
                if (date == null) return 'æ æçæ¥ææ ¼å¼';
                if (date.isAfter(DateTime.now())) {
                  return 'é¦æ¬¡å½å
¥æ¥æä¸è½æäºå½åæ¥æ';
                }
              }
              if (label == 'å½åç¶æ' && trimmedValue.length > 50) {
                return 'å½åç¶æä¸è½è¶
è¿50ä¸ªå­ç¬¦';
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
        title: 'ç¼è¾è½¦è¾ä¿¡æ¯',
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
                                    'è½¦çå·', _licensePlateController, themeData,
                                    required: true,
                                    prefix: 'é»A',
                                    maxLength: 17),
                                _buildTextField(
                                    'è½¦è¾ç±»å', _vehicleTypeController, themeData,
                                    required: true, maxLength: 50),
                                _buildTextField(
                                    'è½¦ä¸»å§å', _ownerNameController, themeData,
                                    required: true, maxLength: 100),
                                _buildTextField(
                                    'èº«ä»½è¯å·ç ', _idCardNumberController, themeData,
                                    required: true,
                                    readOnly: true,
                                    keyboardType: TextInputType.number,
                                    maxLength: 18),
                                _buildTextField(
                                    'èç³»çµè¯', _contactNumberController, themeData,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 20),
                                _buildTextField(
                                    'åå¨æºå·', _engineNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    'è½¦æ¶å·', _frameNumberController, themeData,
                                    maxLength: 50),
                                _buildTextField(
                                    'è½¦èº«é¢è²', _vehicleColorController, themeData,
                                    maxLength: 50),
                                _buildTextField('é¦æ¬¡å½å
¥è½¦çå·çæ¥æ',
                                    _firstRegistrationDateController, themeData,
                                    readOnly: true, onTap: _pickDate),
                                _buildTextField(
                                    'å½åç¶æ', _currentStatusController, themeData,
                                    maxLength: 50),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _submitVehicle,
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
                          child: const Text('ä¿å­'),
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

class VehicleDetailPage extends StatefulWidget {
  final VehicleInformation vehicle;

  const VehicleDetailPage({super.key, required this.vehicle});

  @override
  State<VehicleDetailPage> createState() => _VehicleDetailPageState();
}

class _VehicleDetailPageState extends State<VehicleDetailPage> {
  final VehicleInformationControllerApi vehicleApi =
      VehicleInformationControllerApi();
  bool _isLoading = false;
  bool _isEditable = false;
  String _errorMessage = '';
  String? _currentDriverName;
  final DashboardController controller = Get.find<DashboardController>();

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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      if (jwtToken == null) throw Exception('æªæ¾å° JWTï¼è¯·éæ°ç»å½');
      final decodedToken = JwtDecoder.decode(jwtToken);
      final username = decodedToken['sub'] ?? '';
      if (username.isEmpty) throw Exception('JWT ä¸­æªæ¾å°ç¨æ·å');
      await vehicleApi.initializeWithJwt();
      final user = await _fetchUserManagement();
      final driverInfo = user?.userId != null
          ? await _fetchDriverInformation(user!.userId!)
          : null;
      _currentDriverName = driverInfo?.name ?? username;
      await _checkUserRole();
    } catch (e) {
      setState(() => _errorMessage = 'åå§åå¤±è´¥: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<UserManagement?> _fetchUserManagement() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return null;
      }
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = (await AuthTokenStore.instance.getJwtToken());
      final response = await http.get(
        Uri.parse('http://localhost:8081/api/users/me'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        return UserManagement.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      }
      return null;
    } catch (e) {
      setState(() => _errorMessage = 'è·åç¨æ·ä¿¡æ¯å¤±è´¥: $e');
      return null;
    }
  }

  Future<DriverInformation?> _fetchDriverInformation(int userId) async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return null;
      }
      final driverApi = DriverInformationControllerApi();
      await driverApi.initializeWithJwt();
      return await driverApi.apiDriversDriverIdGet(driverId: userId);
    } catch (e) {
      setState(() => _errorMessage = 'è·åå¸æºä¿¡æ¯å¤±è´¥: $e');
      return null;
    }
  }

  Future<void> _checkUserRole() async {
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
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
            (JwtDecoder.decode(jwtToken)['roles'] is String
                ? [JwtDecoder.decode(jwtToken)['roles']]
                : []);
        debugPrint('User roles from /api/users/me: $roles');
        debugPrint('Full userData: $userData');
        setState(
            () => _isEditable = roles.contains('ADMIN') || // Changed to ADMIN
                (_currentDriverName == widget.vehicle.ownerName));
      } else {
        debugPrint(
            'Role check failed: Status ${response.statusCode}, Body: ${response.body}');
        throw Exception('éªè¯å¤±è´¥ï¼${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking role: $e');
      setState(() => _errorMessage = 'å è½½æéå¤±è´¥: $e');
    }
  }

  Future<void> _deleteVehicle(int vehicleId) async {
    setState(() => _isLoading = true);
    try {
      if (!await _validateJwtToken()) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await vehicleApi.apiVehiclesVehicleIdDelete(vehicleId: vehicleId);
      _showSnackBar('å é¤è½¦è¾æåï¼');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('å é¤å¤±è´¥: $e', isError: true);
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
                  : themeData.colorScheme.onPrimary),
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
          Text('$label: ',
              style: themeData.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          Expanded(
              child: Text(value,
                  style: themeData.textTheme.bodyMedium?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant))),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        final themeData = controller.currentBodyTheme.value;
        return AlertDialog(
          backgroundColor: themeData.colorScheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('ç¡®è®¤å é¤',
              style: themeData.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: themeData.colorScheme.onSurface)),
          content: Text('æ¨ç¡®å®è¦$actionæ­¤è½¦è¾åï¼æ­¤æä½ä¸å¯æ¤éã',
              style: themeData.textTheme.bodyMedium
                  ?.copyWith(color: themeData.colorScheme.onSurfaceVariant)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('åæ¶',
                  style: themeData.textTheme.labelLarge?.copyWith(
                      color: themeData.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: themeData.colorScheme.error,
                foregroundColor: themeData.colorScheme.onError,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('å é¤'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final themeData = controller.currentBodyTheme.value;
      if (_errorMessage.isNotEmpty) {
                return DashboardPageTemplate(
          theme: themeData,
          title: 'è½¦è¾è¯¦æ
',
          pageType: DashboardPageType.manager,
          bodyIsScrollable: true,
          padding: EdgeInsets.zero,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_errorMessage,
                    style: themeData.textTheme.titleMedium?.copyWith(
                        color: themeData.colorScheme.error,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center),
                if (_errorMessage.contains('ç»å½'))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: themeData.colorScheme.primary,
                          foregroundColor: themeData.colorScheme.onPrimary),
                      child: const Text('åå¾ç»å½'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

        return DashboardPageTemplate(
        theme: themeData,
        title: 'è½¦è¾è¯¦æ
',
        pageType: DashboardPageType.manager,
        bodyIsScrollable: true,
        padding: EdgeInsets.zero,
        actions: [
          if (_isEditable) ...[
            DashboardPageBarAction(
              icon: Icons.edit,
              onPressed: () {
                Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                EditVehiclePage(vehicle: widget.vehicle)))
                    .then((value) {
                  if (value == true && mounted) {
                    Navigator.pop(context, true);
                  }
                });
              },
              tooltip: 'ç¼è¾è½¦è¾ä¿¡æ¯',
            ),
            DashboardPageBarAction(
              icon: Icons.delete,
              color: themeData.colorScheme.error,
              onPressed: () {
                final vehicleId = widget.vehicle.vehicleId;
                if (vehicleId == null) {
                  _showSnackBar('è½¦è¾IDä¸ºç©ºï¼æ æ³å é¤', isError: true);
                  return;
                }
                _showDeleteConfirmationDialog(
                  'å é¤',
                  () => _deleteVehicle(vehicleId),
                );
              },
              tooltip: 'å é¤è½¦è¾',
            ),
          ],
        ],
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation(themeData.colorScheme.primary)))
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 3,
                  color: themeData.colorScheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('è½¦è¾ç±»å',
                              widget.vehicle.vehicleType ?? 'æªç¥ç±»å', themeData),
                          _buildDetailRow('è½¦çå·',
                              widget.vehicle.licensePlate ?? 'æªç¥è½¦ç', themeData),
                          _buildDetailRow('è½¦ä¸»å§å',
                              widget.vehicle.ownerName ?? 'æªç¥è½¦ä¸»', themeData),
                          _buildDetailRow('è½¦è¾ç¶æ',
                              widget.vehicle.currentStatus ?? 'æ ', themeData),
                          _buildDetailRow('èº«ä»½è¯å·ç ',
                              widget.vehicle.idCardNumber ?? 'æ ', themeData),
                          _buildDetailRow('èç³»çµè¯',
                              widget.vehicle.contactNumber ?? 'æ ', themeData),
                          _buildDetailRow('åå¨æºå·',
                              widget.vehicle.engineNumber ?? 'æ ', themeData),
                          _buildDetailRow('è½¦æ¶å·',
                              widget.vehicle.frameNumber ?? 'æ ', themeData),
                          _buildDetailRow('è½¦èº«é¢è²',
                              widget.vehicle.vehicleColor ?? 'æ ', themeData),
                          _buildDetailRow(
                              'é¦æ¬¡å½å
¥è½¦çå·çæ¥æ',
                              formatDate(widget.vehicle.firstRegistrationDate),
                              themeData),
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
