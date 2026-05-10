import 'dart:async';

import 'package:final_assignment_front/core/network/interceptor.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class AppLifecycleObserver extends GetxService with WidgetsBindingObserver {
  AppLifecycleObserver({required LogEventWriter logWriter})
      : _logWriter = logWriter;

  final LogEventWriter _logWriter;
  bool _started = false;
  String? _lastRoute;

  AppLifecycleObserver start() {
    if (_started) return this;
    WidgetsBinding.instance.addObserver(this);
    _started = true;
    unawaited(_logAppStartup());
    return this;
  }

  void stop() {
    if (!_started) return;
    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  void onRouteChanged(Routing? routing) {
    final currentRoute = routing?.current;
    if (currentRoute == null ||
        currentRoute.isEmpty ||
        currentRoute == _lastRoute) {
      return;
    }

    final previousRoute = routing?.previous;
    _lastRoute = currentRoute;
    unawaited(
      _logWriter.writeOperationEvent(
        type: 'NAVIGATION',
        module: 'App',
        function: 'RouteChanged',
        content: 'Navigated to $currentRoute',
        remarks: previousRoute == null || previousRoute.isEmpty
            ? null
            : 'From $previousRoute',
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final stateName = state.name;
    unawaited(
      Future.wait([
        _logWriter.writeSystemEvent(
          logType: 'APP_LIFECYCLE',
          content: 'App lifecycle changed to $stateName',
        ),
        _logWriter.writeOperationEvent(
          type: 'APP_LIFECYCLE',
          module: 'App',
          function: 'LifecycleChanged',
          content: 'App lifecycle changed',
          remarks: stateName,
        ),
      ]),
    );
  }

  Future<void> _logAppStartup() async {
    await Future.wait([
      _logWriter.writeSystemEvent(
        logType: 'SYSTEM_EVENT',
        content: 'Application started',
        remarks: 'Traffic Violation Management System started',
      ),
      _logWriter.writeOperationEvent(
        type: 'SYSTEM_EVENT',
        module: 'App',
        function: 'Startup',
        content: 'Application started',
        remarks: 'User launched the app',
      ),
    ]);
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
