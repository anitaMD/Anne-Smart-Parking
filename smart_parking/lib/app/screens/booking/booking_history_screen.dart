import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking/app/screens/settings/settings_screen.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/booking_model.dart';
import '../../models/parking_model.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/parking_viewmodel.dart';
import 'booking_screen.dart';

enum _Filter { all, ongoing, upcoming, past, canceled }

class BookingHistoryScreen extends ConsumerStatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  ConsumerState<BookingHistoryScreen> createState() =>
      _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends ConsumerState<BookingHistoryScreen> {
  _Filter _filter = _Filter.all;
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 15;
  int _visibleCount = 15;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        setState(() => _visibleCount += _pageSize);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingState = ref.watch(bookingProvider);
    final parkings = ref.watch(parkingProvider).parkings;
    final all = bookingState.allBookings;

    final ongoing = all.where((b) => b.isOngoing).toList();
    final upcoming = all
        .where((b) => b.hasNotStarted && b.status == BookingStatus.upcoming)
        .toList();
    // Passées = bookingEnd dans le passé ET pas annulée
    final past =
        all.where((b) => b.bookingEnd.isBefore(DateTime.now())).toList();
    final canceled =
        all.where((b) => b.status == BookingStatus.canceled).toList();
    final l10n = AppLocalizations.of(context)!;

    debugPrint('[History] all: ${all.length}');
    debugPrint(
        '[History] unArchived: ${bookingState.unArchivedBookings.length}');
    debugPrint(
        '[History] archived: ${bookingState.allArchivedBookings.length}');
    for (final b in all) {
      debugPrint(
          '[History] ${b.id} status=${b.status} isArchived=${b.isArchived} end=${b.bookingEnd}');
    }
    List<BookingModel> filtered;
    switch (_filter) {
      case _Filter.all:
        filtered = all;
      case _Filter.ongoing:
        filtered = ongoing;
      case _Filter.upcoming:
        filtered = upcoming;
      case _Filter.past:
        filtered = past;
      case _Filter.canceled:
        filtered = canceled;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Titre ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spaceM, AppSizes.spaceL,
              AppSizes.spaceM, AppSizes.spaceS),
        ),

        // ── Chips filtre ──────────────────────────────────
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
            children: [
              _FilterChip(
                label: l10n.bookingFilterAll,
                count: all.length,
                selected: _filter == _Filter.all,
                onTap: () => setState(() {
                  _filter = _Filter.all;
                  _visibleCount = _pageSize;
                }),
              ),
              const SizedBox(width: AppSizes.spaceS),
              _FilterChip(
                label: l10n.bookingFilterOngoing,
                count: ongoing.length,
                selected: _filter == _Filter.ongoing,
                onTap: () => setState(() {
                  _filter = _Filter.ongoing;
                  _visibleCount = _pageSize;
                }),
                color: AppColors.success, // vert comme dashboard
              ),
              const SizedBox(width: AppSizes.spaceS),
              _FilterChip(
                label: l10n.bookingFilterUpcoming,
                count: upcoming.length,
                selected: _filter == _Filter.upcoming,
                onTap: () => setState(() {
                  _filter = _Filter.upcoming;
                  _visibleCount = _pageSize;
                }),
                color: AppColors.warning, // orange comme dashboard
              ),
              const SizedBox(width: AppSizes.spaceS),
              _FilterChip(
                label: l10n.bookingFilterPast,
                count: past.length,
                selected: _filter == _Filter.past,
                onTap: () => setState(() {
                  _filter = _Filter.past;
                  _visibleCount = _pageSize;
                }),
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSizes.spaceS),
              _FilterChip(
                label: l10n.bookingFilterCanceled,
                count: canceled.length,
                selected: _filter == _Filter.canceled,
                onTap: () => setState(() {
                  _filter = _Filter.canceled;
                  _visibleCount = _pageSize;
                }),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSizes.spaceM),

        // ── Liste ────────────────────────────────────────
        Expanded(
          child: bookingState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? _EmptyState(filter: _filter)
                  : Builder(builder: (_) {
                      final visible = filtered.take(_visibleCount).toList();
                      final hasMore = filtered.length > _visibleCount;
                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.spaceM),
                        itemCount: visible.length + (hasMore ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == visible.length) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSizes.spaceL),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          final b = visible[i];
                          final parking = parkings.firstWhere(
                            (p) => p.id == b.parkingId,
                            orElse: () => ParkingModel.empty(),
                          );
                          return _BookingCard(booking: b, parking: parking);
                        },
                      );
                    }),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FILTER CHIP
// ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceM, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          border: Border.all(color: selected ? color : AppColors.border),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              ),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : color)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOOKING CARD
// ─────────────────────────────────────────────────────────────

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;
  final ParkingModel parking;

  const _BookingCard({required this.booking, required this.parking});

  String _fmt(DateTime dt) => DateFormat('HH:mm').format(dt);
  String _fmtDate(DateTime dt) => DateFormat('EEE d MMM yyyy', 'fr').format(dt);

  String get _duration {
    final mins = booking.durationMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  Color get _statusColor {
    if (booking.isOngoing) return AppColors.success;
    if (booking.status == BookingStatus.canceled) return AppColors.error;
    if (booking.isExpired) return AppColors.textSecondary;
    return AppColors.warning;
  }

  String _statusLabel(AppLocalizations l10n) {
    if (booking.isOngoing) return l10n.bookingStatusOngoing;
    if (booking.status == BookingStatus.canceled) {
      return l10n.bookingStatusCanceled;
    }
    if (booking.isExpired) return l10n.bookingStatusDone;
    if (booking.wasEdited) return l10n.bookingStatusUpcomingEdited;
    return l10n.bookingStatusUpcoming;
  }

  IconData get _statusIcon {
    if (booking.isOngoing) return Icons.radio_button_checked;
    if (booking.status == BookingStatus.canceled) return Icons.cancel_outlined;
    if (booking.isExpired) return Icons.check_circle_outline;
    return Icons.schedule_outlined;
  }

  bool get _canEdit =>
      booking.hasNotStarted && booking.status == BookingStatus.upcoming;
  bool get _canCancel =>
      booking.hasNotStarted && booking.status == BookingStatus.upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: booking.isOngoing
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.border,
          width: booking.isOngoing ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header status
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceM, vertical: AppSizes.spaceS),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusL)),
            ),
            child: Row(children: [
              Icon(_statusIcon, color: _statusColor, size: 15),
              const SizedBox(width: 5),
              Text(_statusLabel(l10n),
                  style: TextStyle(
                      color: _statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5)),
              const Spacer(),
              if (booking.wasEdited)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Text(l10n.bookingEdited,
                      style: TextStyle(
                          fontSize: 9,
                          color: AppColors.info,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSizes.spaceM, AppSizes.spaceS,
                AppSizes.spaceM, AppSizes.spaceS),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.local_parking,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      parking.name.isEmpty ? booking.parkingId : parking.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: Text(l10n.bookingSpotLabel(booking.spotId),
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
                  ),
                ]),
                const SizedBox(height: AppSizes.spaceS),
                _Row(
                    icon: Icons.calendar_today_outlined,
                    text: _fmtDate(booking.bookingStart)),
                const SizedBox(height: 4),
                _Row(
                  icon: Icons.schedule_outlined,
                  text:
                      '${_fmt(booking.bookingStart)} → ${_fmt(booking.bookingEnd)} · $_duration',
                ),
                const SizedBox(height: 4),
                _Row(
                  icon: Icons.monetization_on_outlined,
                  text: '${booking.totalCost} SPM',
                  bold: true,
                ),
                if (_canEdit || _canCancel) ...[
                  const SizedBox(height: AppSizes.spaceM),
                  const Divider(height: 1),
                  const SizedBox(height: AppSizes.spaceS),
                  Row(children: [
                    if (_canEdit)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onEdit(context, ref),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: Text(l10n.bookingEditAction,
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 34),
                          ),
                        ),
                      ),
                    if (_canEdit && _canCancel)
                      const SizedBox(width: AppSizes.spaceS),
                    if (_canCancel)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _onCancel(context, ref),
                          icon: const Icon(Icons.close_outlined, size: 14),
                          label: Text(l10n.bookingCancelAction,
                              style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            minimumSize: const Size(0, 34),
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onEdit(BuildContext context, WidgetRef ref) {
    final parkings = ref.read(parkingProvider).parkings;
    final p = parkings.firstWhere(
      (p) => p.id == booking.parkingId,
      orElse: () => ParkingModel.empty(),
    );
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                BookingScreen(parking: p, existingBooking: booking)));
  }

  void _onCancel(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.bookingCancelTitle),
        content: Builder(
          builder: (context) {
            final locale = ref.watch(localeProvider).languageCode;
            return Text(
              l10n.bookingCancelContent(
                booking.spotId,
                DateFormat('d MMM', locale).format(booking.bookingStart),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonNo),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(bookingProvider.notifier).cancelBooking(booking.id);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.bookingConfirmCancelYes),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool bold;
  const _Row({required this.icon, required this.text, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 13, color: AppColors.textSecondary),
      const SizedBox(width: 5),
      Expanded(
        child: Text(text,
            style: TextStyle(
                color: bold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12)),
      ),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  final _Filter filter;
  const _EmptyState({required this.filter});

  String get _message {
    switch (filter) {
      case _Filter.upcoming:
        return 'Aucune réservation à venir';
      case _Filter.past:
        return 'Aucune réservation passée';
      case _Filter.canceled:
        return 'Aucune réservation annulée';
      default:
        return 'Aucune réservation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border_outlined,
              size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSizes.spaceM),
          Text(_message,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSizes.spaceXS),
          const Text('Vos réservations apparaîtront ici',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
