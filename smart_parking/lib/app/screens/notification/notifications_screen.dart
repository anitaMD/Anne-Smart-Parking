import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// PROVIDER — watchNotifications stream
// ─────────────────────────────────────────────────────────────

final notificationsStreamProvider =
    StreamProvider<List<NotificationModel>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  return ref
      .read(firestoreServiceProvider)
      .watchNotifications(authState.user.id);
});

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsStreamProvider);
    final authState = ref.watch(authProvider);
    final uid = authState is AuthAuthenticated ? authState.user.id : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spaceM, AppSizes.spaceL,
              AppSizes.spaceM, AppSizes.spaceS),
          child: Row(
            children: [
              notifsAsync.when(
                data: (notifs) {
                  final unread = notifs.where((n) => !n.isRead).toList();
                  if (unread.isEmpty) return const SizedBox.shrink();
                  return TextButton.icon(
                    onPressed: () => _markAllRead(ref, uid, unread),
                    icon: const Icon(Icons.done_all, size: 16),
                    label:
                        const Text('Tout lire', style: TextStyle(fontSize: 12)),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // ── Liste ─────────────────────────────────────────
        Expanded(
          child: notifsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (notifs) {
              if (notifs.isEmpty) return const _EmptyNotifications();
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
                itemCount: notifs.length,
                itemBuilder: (_, i) => _NotificationTile(
                  notification: notifs[i],
                  uid: uid,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _markAllRead(
      WidgetRef ref, String uid, List<NotificationModel> unread) async {
    final fs = ref.read(firestoreServiceProvider);
    for (final n in unread) {
      await fs.markNotificationRead(uid, n.id);
    }
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION TILE
// ─────────────────────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final String uid;

  const _NotificationTile({required this.notification, required this.uid});

  IconData get _icon {
    final t = notification.title.toLowerCase();
    if (t.contains('réservation') ||
        t.contains('booking') ||
        t.contains('place')) {
      return Icons.bookmark_outlined;
    }
    if (t.contains('wallet') ||
        t.contains('rechargement') ||
        t.contains('spm')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (t.contains('rappel') ||
        t.contains('minutes') ||
        t.contains('bientôt')) {
      return Icons.alarm_outlined;
    }
    if (t.contains('annul')) return Icons.cancel_outlined;
    return Icons.notifications_outlined;
  }

  Color get _iconColor {
    final t = notification.title.toLowerCase();
    if (t.contains('annul')) return AppColors.error;
    if (t.contains('wallet') || t.contains('rechargement') || t.contains('✅')) {
      return AppColors.success;
    }
    if (t.contains('rappel') ||
        t.contains('minutes') ||
        t.contains('⚠️') ||
        t.contains('⏰')) {
      return AppColors.warning;
    }
    return AppColors.primary;
  }

  bool get _isReminder {
    final t = notification.title.toLowerCase();
    return t.contains('rappel') ||
        t.contains('minutes') ||
        t.contains('bientôt') ||
        t.contains('⚠️') ||
        t.contains('⏰');
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return DateFormat('d MMM yyyy', 'fr').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.spaceL),
        margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: const Icon(Icons.done_outlined, color: AppColors.error),
      ),
      onDismissed: (_) async {
        await ref
            .read(firestoreServiceProvider)
            .markNotificationRead(uid, notification.id);
      },
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(firestoreServiceProvider)
                .markNotificationRead(uid, notification.id);
          }
          if (_isReminder && context.mounted) {
            _showSnooze(context);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
          padding: const EdgeInsets.all(AppSizes.spaceM),
          decoration: BoxDecoration(
            color: notification.isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            border: Border.all(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.primary.withValues(alpha: 0.2),
              width: notification.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _iconColor, size: 20),
              ),
              const SizedBox(width: AppSizes.spaceM),

              // Contenu
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(notification.title,
                            style: TextStyle(
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                fontSize: 14)),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ]),
                    const SizedBox(height: 4),
                    Text(notification.body,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.access_time,
                          size: 11, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(_formatDate(notification.receivedAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                      if (_isReminder) ...[
                        const SizedBox(width: AppSizes.spaceM),
                        const Icon(Icons.snooze,
                            size: 11, color: AppColors.warning),
                        const SizedBox(width: 3),
                        const Text('Tap pour snooze',
                            style: TextStyle(
                                fontSize: 10, color: AppColors.warning)),
                      ],
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnooze(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(AppSizes.spaceL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: AppSizes.spaceM),
            Row(children: [
              const Icon(Icons.snooze, color: AppColors.warning),
              const SizedBox(width: AppSizes.spaceS),
              const Text('Reporter le rappel',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            const SizedBox(height: AppSizes.spaceL),
            ...[5, 10, 15, 30].map((mins) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.alarm,
                        color: AppColors.warning, size: 20),
                  ),
                  title: Text('Dans $mins minutes'),
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColors.textSecondary),
                  onTap: () async {
                    Navigator.pop(context);
                    await NotificationService().snoozeReminder(
                      title: notification.title,
                      body: notification.body,
                      minutes: mins,
                      bookingId: '',
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Rappel reporté de $mins minutes'),
                          backgroundColor: AppColors.warning,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                )),
            const SizedBox(height: AppSizes.spaceS),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSizes.spaceM),
          const Text('Aucune notification',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSizes.spaceXS),
          const Text(
            'Vos rappels et alertes apparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
