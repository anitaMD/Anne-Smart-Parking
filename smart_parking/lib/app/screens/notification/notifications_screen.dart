import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final Set<String> _dismissedIds = {}; // ← ajoute ce state local

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userState = ref.watch(userProvider);
    final authState = ref.watch(authProvider);
    final uid = authState is AuthAuthenticated ? authState.user.id : '';

    // Filtre les notifications déjà dismissées localement
    final notifications = userState.notifications
        .where((n) => !_dismissedIds.contains(n.id))
        .toList();

    final unread = notifications.where((n) => !n.isRead).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spaceM, AppSizes.spaceL,
              AppSizes.spaceM, AppSizes.spaceS),
          child: Row(
            children: [
              if (unread.isNotEmpty)
                TextButton.icon(
                  onPressed: () async {
                    for (final n in unread) {
                      await ref
                          .read(userProvider.notifier)
                          .markNotificationRead(uid, n.id);
                    }
                  },
                  icon: const Icon(Icons.done_all, size: 16),
                  label: Text(l10n.notificationsMarkAllRead,
                      style: const TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),

        // ── Liste ─────────────────────────────────────────
        Expanded(
          child: notifications.isEmpty
              ? _EmptyNotifications(l10n: l10n)
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
                  itemCount: notifications.length,
                  itemBuilder: (_, i) => _NotificationTile(
                    notification: notifications[i],
                    uid: uid,
                    onDismissed: () => setState(() =>
                        _dismissedIds.add(notifications[i].id)), // ← ajoute
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// NOTIFICATION TILE
// ─────────────────────────────────────────────────────────────

class _NotificationTile extends ConsumerWidget {
  final NotificationModel notification;
  final String uid;
  final VoidCallback onDismissed;

  const _NotificationTile(
      {required this.notification,
      required this.uid,
      required this.onDismissed});
  IconData get _icon {
    final t = notification.title.toLowerCase();
    if (t.contains('réservation') ||
        t.contains('booking') ||
        t.contains('place') ||
        t.contains('confirmed')) {
      return Icons.bookmark_outlined;
    }
    if (t.contains('wallet') ||
        t.contains('rechargement') ||
        t.contains('reçu') ||
        t.contains('received') ||
        t.contains('spm')) {
      return Icons.account_balance_wallet_outlined;
    }
    if (t.contains('rappel') ||
        t.contains('minutes') ||
        t.contains('bientôt') ||
        t.contains('reminder')) {
      return Icons.alarm_outlined;
    }
    if (t.contains('annul') || t.contains('cancel')) {
      return Icons.cancel_outlined;
    }
    if (t.contains('fin') || t.contains('end') || t.contains('terminé')) {
      return Icons.timer_off_outlined;
    }
    return Icons.notifications_outlined;
  }

  Color get _iconColor {
    final t = notification.title.toLowerCase();
    if (t.contains('annul') || t.contains('cancel')) return AppColors.error;
    if (t.contains('wallet') ||
        t.contains('rechargement') ||
        t.contains('reçu') ||
        t.contains('received')) {
      return AppColors.success;
    }
    if (t.contains('rappel') ||
        t.contains('minutes') ||
        t.contains('⚠️') ||
        t.contains('⏰') ||
        t.contains('fin')) {
      return AppColors.warning;
    }
    if (t.contains('✅') || t.contains('confirmée') || t.contains('confirmed')) {
      return AppColors.success;
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
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return DateFormat('d MMM yyyy', 'fr').format(dt);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.spaceL),
        margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: const Icon(Icons.done_outlined, color: AppColors.success),
      ),
      onDismissed: (_) async {
        onDismissed();
        ref.read(userProvider.notifier).markNotificationRead(
            uid, notification.id); // persist en arrière-plan
      },
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(userProvider.notifier)
                .markNotificationRead(uid, notification.id);
          }
          if (_isReminder && context.mounted) {
            _showSnooze(context, l10n);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
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
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceM, vertical: AppSizes.spaceXS),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _iconColor, size: 20),
            ),
            title: Row(children: [
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(notification.body,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
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
                    Text(l10n.notificationsSnooze,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.warning)),
                  ],
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnooze(BuildContext context, AppLocalizations l10n) {
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
              Text(l10n.notificationsSnooze,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
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
                  title: Text('$mins minutes'),
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
                          content: Text('$mins minutes'),
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
  final AppLocalizations l10n;
  const _EmptyNotifications({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSizes.spaceM),
          Text(l10n.notificationsEmpty,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSizes.spaceXS),
          Text(
            'Vos rappels et alertes apparaîtront ici',
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
