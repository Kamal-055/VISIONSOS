import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vision/core/services/sos_service.dart';

// SOS status enum is defined in sos_service.dart
export 'package:vision/core/services/sos_service.dart' show SOSStatus;

final sosServiceProvider = Provider<SOSService>((ref) {
  final service = SOSService();
  ref.onDispose(service.dispose);
  return service;
});

// State class representing the current SOS session
class SOSState {
  final SOSStatus status;
  final String? alertId;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;
  final DateTime? activatedAt;

  const SOSState({
    this.status = SOSStatus.idle,
    this.alertId,
    this.latitude,
    this.longitude,
    this.errorMessage,
    this.activatedAt,
  });

  SOSState copyWith({
    SOSStatus? status,
    String? alertId,
    double? latitude,
    double? longitude,
    String? errorMessage,
    DateTime? activatedAt,
  }) {
    return SOSState(
      status: status ?? this.status,
      alertId: alertId ?? this.alertId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: errorMessage,
      activatedAt: activatedAt ?? this.activatedAt,
    );
  }

  bool get isIdle => status == SOSStatus.idle;
  bool get isActivating => status == SOSStatus.activating;
  bool get isActive => status == SOSStatus.active;
  bool get isCancelling => status == SOSStatus.cancelling;
}

class SOSNotifier extends StateNotifier<SOSState> {
  final SOSService _sosService;

  SOSNotifier(this._sosService) : super(const SOSState());

  Future<void> activateSOS() async {
    if (state.status != SOSStatus.idle) return;

    state = state.copyWith(status: SOSStatus.activating, errorMessage: null);

    try {
      final alertId = await _sosService.activateSOS();
      state = state.copyWith(
        status: SOSStatus.active,
        alertId: alertId,
        activatedAt: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        status: SOSStatus.idle,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> cancelSOS() async {
    final alertId = state.alertId;
    if (alertId == null || state.status != SOSStatus.active) return;

    state = state.copyWith(status: SOSStatus.cancelling, errorMessage: null);

    try {
      await _sosService.cancelSOS(alertId);
      state = const SOSState(); // Reset to idle
    } catch (e) {
      state = state.copyWith(
        status: SOSStatus.active,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> resolveAlert() async {
    final alertId = state.alertId;
    if (alertId == null) return;

    try {
      await _sosService.resolveAlert(alertId);
      state = const SOSState(); // Reset to idle
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final sosNotifierProvider = StateNotifierProvider<SOSNotifier, SOSState>((ref) {
  final sosService = ref.watch(sosServiceProvider);
  return SOSNotifier(sosService);
});
