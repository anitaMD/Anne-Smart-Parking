import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle notification YSP Smart Parking
///
/// Collection Firestore : users/{uid}/notifications/{notifId}
/// Champs :
/// {
///   title: string
///   body: string
///   isRead: bool
///   receivedAt: timestamp
/// }
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime receivedAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.receivedAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      isRead: data['isRead'] as bool? ?? false,
      receivedAt:
          (data['receivedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'isRead': isRead,
        'receivedAt': FieldValue.serverTimestamp(),
      };

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        isRead: isRead ?? this.isRead,
        receivedAt: receivedAt,
      );

  @override
  String toString() => 'NotificationModel(id: $id, title: $title)';
}
