import 'dart:async';
import 'dart:convert';

import 'package:final_assignment_front/core/network/api_client.dart';
import 'package:final_assignment_front/core/utils/app_logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppealStatusChange {
  const AppealStatusChange({
    required this.appealId,
    required this.newStatus,
    this.updatedAt,
  });

  final int appealId;
  final String newStatus;
  final DateTime? updatedAt;

  factory AppealStatusChange.fromJson(Map<String, dynamic> json) {
    return AppealStatusChange(
      appealId: _asInt(json['appealId']),
      newStatus: json['newStatus']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class PaymentStatusChange {
  const PaymentStatusChange({
    required this.paymentId,
    required this.newStatus,
    this.fineId,
    this.updatedAt,
  });

  final int paymentId;
  final int? fineId;
  final String newStatus;
  final DateTime? updatedAt;

  factory PaymentStatusChange.fromJson(Map<String, dynamic> json) {
    return PaymentStatusChange(
      paymentId: _asInt(json['paymentId']),
      fineId: _nullableInt(json['fineId']),
      newStatus: json['newStatus']?.toString() ?? '',
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class BusinessEventListener extends GetxService {
  BusinessEventListener({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;
  StreamSubscription<String>? _wsSubscription;
  bool _started = false;

  final appealStatusChanges = StreamController<AppealStatusChange>.broadcast();
  final paymentStatusChanges =
      StreamController<PaymentStatusChange>.broadcast();
  final reconnectSignal = StreamController<void>.broadcast();

  Future<void> startListening() async {
    if (_started) {
      return;
    }

    _wsSubscription = _apiClient.wsMessageStream.listen(
      _handleMessage,
      onError: (Object error) {
        AppLogger.error('Business WebSocket listener error: $error');
      },
    );

    try {
      await _apiClient.connectWebSocket('/eventbus/websocket', const []);
      _started = true;
    } catch (error) {
      await _wsSubscription?.cancel();
      _wsSubscription = null;
      AppLogger.error('Business WebSocket connection failed: $error');
      rethrow;
    }
  }

  void _handleMessage(String message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String?;
      switch (type) {
        case 'APPEAL_STATUS_CHANGED':
          appealStatusChanges.add(AppealStatusChange.fromJson(data));
          break;
        case 'PAYMENT_STATUS_CHANGED':
          paymentStatusChanges.add(PaymentStatusChange.fromJson(data));
          break;
        case 'ASYNC_OPERATION_FAILED':
          Get.snackbar(
            '操作提示',
            data['message']?.toString() ?? '操作处理失败，请刷新页面确认',
            backgroundColor: Colors.orange.shade100,
            duration: const Duration(seconds: 5),
          );
          break;
        default:
          AppLogger.debug('Ignored business WebSocket event: $data');
      }
    } catch (error) {
      AppLogger.error('Failed to parse business WebSocket event: $error');
    }
  }

  void resumeSubscriptions() {
    if (!_started) return;
    AppLogger.debug(
      'BusinessEventListener: resuming subscriptions after reconnect',
    );
    _notifyReconnected();
  }

  void _notifyReconnected() {
    if (!reconnectSignal.isClosed) {
      reconnectSignal.add(null);
    }
  }

  @override
  void onClose() {
    _wsSubscription?.cancel();
    _apiClient.closeWebSocket();
    appealStatusChanges.close();
    paymentStatusChanges.close();
    reconnectSignal.close();
    super.onClose();
  }
}

int _asInt(dynamic value) {
  return _nullableInt(value) ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
