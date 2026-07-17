import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/utils/connectivity_check_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// État de connectivité
class ConnectivityState {
  final ConnectivityResult status;
  final bool hasRealInternet;
  final bool isInitialized;

  const ConnectivityState({
    this.status = ConnectivityResult.none,
    this.hasRealInternet = false,
    this.isInitialized = false,
  });

  bool get isConnected => hasRealInternet;
  bool get isWifi => status == ConnectivityResult.wifi;
  bool get isMobile => status == ConnectivityResult.mobile;

  ConnectivityState copyWith({
    ConnectivityResult? status,
    bool? hasRealInternet,
    bool? isInitialized,
  }) =>
      ConnectivityState(
        status: status ?? this.status,
        hasRealInternet: hasRealInternet ?? this.hasRealInternet,
        isInitialized: isInitialized ?? this.isInitialized,
      );
}

/// Provider Riverpod de connectivité
///
/// BONNE PRATIQUE Riverpod : on utilise Notifier pour
/// gérer un état complexe avec des méthodes.
/// Accessible partout via ref.watch(connectivityProvider)
class ConnectivityNotifier extends Notifier<ConnectivityState> {
  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  @override
  ConnectivityState build() {
    // Initialiser au premier appel
    _init();
    // Cleanup automatique quand le provider est détruit
    ref.onDispose(() => _subscription?.cancel());
    return const ConnectivityState();
  }

  Future<void> _init() async {
    final results = await _connectivity.checkConnectivity();
    final hasInternet = await checkRealInternet(results.first);
    state = ConnectivityState(
      status: results.first,
      hasRealInternet: hasInternet,
      isInitialized: true,
    );

    _subscription = _connectivity.onConnectivityChanged.listen(
      (results) async {
        final newStatus = results.first;
        final hasInternet = await checkRealInternet(newStatus);
        state = state.copyWith(
          status: newStatus,
          hasRealInternet: hasInternet,
        );
      },
    );
  }

  /// Force une re-vérification — bouton "Réessayer"
  Future<void> recheck() async {
    final hasInternet = await checkRealInternet(state.status);
    state = state.copyWith(hasRealInternet: hasInternet);
  }
}

/// Le provider global — utilisé dans toute l'app
final connectivityProvider =
    NotifierProvider<ConnectivityNotifier, ConnectivityState>(
  ConnectivityNotifier.new,
);
