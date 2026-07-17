import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_parking/app/services/notification_service.dart';
import '../models/user_model.dart';
import '../models/vehicle_model.dart';
import '../models/wallet_model.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'auth_viewmodel.dart';
import 'dart:io';

// ─────────────────────────────────────────────────────────────
// USER STATE
// ─────────────────────────────────────────────────────────────

class UserState {
  final UserModel? user;
  final WalletModel? wallet;
  final List<VehicleModel> vehicles;
  final List<NotificationModel> notifications;
  final bool isLoading;
  final String? error;

  const UserState({
    this.user,
    this.wallet,
    this.vehicles = const [],
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  // Getters utiles
  bool get hasVehicles => vehicles.isNotEmpty;
  bool get hasNotifications => notifications.isNotEmpty;
  int get unreadNotificationsCount =>
      notifications.where((n) => !n.isRead).length;
  VehicleModel? get defaultVehicle =>
      vehicles.where((v) => v.isCurrentlySelected).firstOrNull ??
      vehicles.firstOrNull;

  UserState copyWith({
    UserModel? user,
    WalletModel? wallet,
    List<VehicleModel>? vehicles,
    List<NotificationModel>? notifications,
    bool? isLoading,
    String? error,
  }) =>
      UserState(
        user: user ?? this.user,
        wallet: wallet ?? this.wallet,
        vehicles: vehicles ?? this.vehicles,
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─────────────────────────────────────────────────────────────
// USER VIEWMODEL
// ─────────────────────────────────────────────────────────────

class UserNotifier extends Notifier<UserState> {
  late FirestoreServiceBase _firestoreService;
  late StorageService _storageService;
  StreamSubscription? _notifSubscription;
  StreamSubscription? _walletSubscription;
  int _loadGeneration = 0;

  @override
  UserState build() {
    _firestoreService = ref.read(firestoreServiceProvider);
    _storageService = ref.read(storageServiceProvider);
    ref.listen(authProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        loadUserData(next.user.id);
      } else if (next is AuthUnauthenticated) {
        _loadGeneration++; // ← invalide tout appel en cours
        _notifSubscription?.cancel();
        _walletSubscription?.cancel();
        state = const UserState();
      }
    });

    final authState = ref.read(authProvider);
    if (authState is AuthAuthenticated) {
      loadUserData(authState.user.id);
    }

    ref.onDispose(() {
      _notifSubscription?.cancel();
      _walletSubscription?.cancel();
    });

    return const UserState();
  }

  Future<void> loadUserData(String uid) async {
    final myGeneration = ++_loadGeneration; // ← snapshot de génération
    state = state.copyWith(isLoading: true);
    try {
      final results = await Future.wait([
        _firestoreService.getUser(uid),
        _firestoreService.getWallet(uid),
        _firestoreService.getVehicles(uid),
        _firestoreService.watchNotifications(uid).first,
      ]);

      // Si un appel plus récent a démarré entre-temps, on abandonne
      if (myGeneration != _loadGeneration) return;

      state = UserState(
        user: results[0] as UserModel?,
        wallet: results[1] as WalletModel?,
        vehicles: results[2] as List<VehicleModel>,
        notifications: results[3] as List<NotificationModel>,
        isLoading: false,
      );

      bool isFirstEmission = true; // ← nouveau flag propre par souscription

      await _notifSubscription?.cancel();
      _notifSubscription =
          _firestoreService.watchNotifications(uid).listen((notifs) {
        if (myGeneration != _loadGeneration) return; // ← ignore si obsolète
        if (state.user == null) return;

        if (!isFirstEmission) {
          final previousIds = state.notifications.map((n) => n.id).toSet();
          final newOnes =
              notifs.where((n) => !previousIds.contains(n.id)).toList();
          for (final notif in newOnes) {
            NotificationService().show(
              title: notif.title,
              body: notif.body,
            );
          }
        }
        isFirstEmission = false;

        state = state.copyWith(notifications: notifs);
      });

      await _walletSubscription?.cancel();
      _walletSubscription = _firestoreService.watchWallet(uid).listen((wallet) {
        if (myGeneration != _loadGeneration) return;
        if (wallet != null) {
          state = state.copyWith(wallet: wallet);
        }
      });

      debugPrint('[User] Données chargées pour $uid (gen $myGeneration)');
    } catch (e) {
      debugPrint('[User] Erreur chargement: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Profil ────────────────────────────────────────────────

  Future<void> updateProfilePicture(File file, String uid) async {
    final url = await _storageService.uploadProfilePicture(
      file: file,
      uid: uid,
    );
    if (url != null) {
      await _firestoreService.updateUser(uid, {'profileImageUrl': url});
      state = state.copyWith(
        user: state.user?.copyWith(profileImageUrl: url),
      );
    }
  }

  // ── Véhicules ─────────────────────────────────────────────

  Future<void> addVehicle(String uid, VehicleModel vehicle) async {
    await _firestoreService.addVehicle(uid, vehicle);
    await loadUserData(uid);
  }

  Future<void> deleteVehicle(String uid, String vehicleId) async {
    await _firestoreService.deleteVehicle(uid, vehicleId);
    final updated = state.vehicles.where((v) => v.id != vehicleId).toList();
    state = state.copyWith(vehicles: updated);
  }

  Future<void> setDefaultVehicle(String uid, String vehicleId) async {
    await _firestoreService.setDefaultVehicle(uid, vehicleId);
    final updated = state.vehicles.map((v) {
      return v.copyWith(isCurrentlySelected: v.id == vehicleId);
    }).toList();
    state = state.copyWith(vehicles: updated);
  }

  // ── Notifications ─────────────────────────────────────────

  Future<void> markNotificationRead(String uid, String notifId) async {
    // Mise à jour optimiste immédiate du state
    final updated = state.notifications.map((n) {
      return n.id == notifId ? n.copyWith(isRead: true) : n;
    }).toList();
    state = state.copyWith(notifications: updated);

    // Puis persist en arrière-plan
    await _firestoreService.markNotificationRead(uid, notifId);
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);

/// Accès direct au wallet
final walletProvider = Provider<WalletModel?>((ref) {
  return ref.watch(userProvider).wallet;
});

/// Accès direct aux véhicules
final vehiclesProvider = Provider<List<VehicleModel>>((ref) {
  return ref.watch(userProvider).vehicles;
});

/// Nombre de notifications non lues — pour le badge
final unreadNotificationsProvider = Provider<int>((ref) {
  return ref.watch(userProvider).unreadNotificationsCount;
});
