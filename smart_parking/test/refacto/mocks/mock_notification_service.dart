import 'package:flutter/material.dart';
import 'package:smart_parking/app/models/booking_model.dart';
import 'package:smart_parking/app/services/notification_service.dart';

/// Mock NotificationService — zéro Firebase, zéro plugin natif
///
/// Le vrai NotificationService instancie FirebaseMessaging.instance
/// dans son constructeur, qui plante en environnement de test sans
/// Firebase.initializeApp(). Ce mock permet de tester la logique
/// des viewmodels (BookingNotifier.cancelBooking, createBooking) sans
/// dépendre de Firebase ni des plugins natifs de notification.
class MockNotificationService implements NotificationService {
  final List<String> canceledBookingIds = [];
  final List<String> scheduledBookingIds = [];

  @override
  Future<void> cancelBookingReminders(String bookingId) async {
    canceledBookingIds.add(bookingId);
  }

  @override
  Future<void> scheduleBookingReminders(
    BookingModel booking, {
    required Locale locale,
    bool remind30min = true,
    bool remind10min = true,
    bool remindStart = true,
    bool remindEnd15min = true,
  }) async {
    scheduledBookingIds.add(booking.id);
  }

  @override
  Future<void> snoozeReminder({
    required String title,
    required String body,
    required int minutes,
    required String bookingId,
  }) async {}

  @override
  Future<void> show({
    required String title,
    required String body,
    String? uid,
  }) async {}

  @override
  Future<void> init() async {}

  @override
  Future<String?> getToken() async => null;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> requestExactAlarmPermission() async => true;

  @override
  Future<void> saveFcmToken(String uid) async {}
}
