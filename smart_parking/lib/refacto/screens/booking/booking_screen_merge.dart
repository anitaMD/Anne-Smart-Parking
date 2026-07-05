import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_parking/refacto/viewmodels/auth_viewmodel.dart';
import 'package:time_range_picker/time_range_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/parking_model.dart';
import '../../models/parking_spot_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/firestore_service.dart';
import '../../viewmodels/parking_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/license_plate_widget.dart';

class BookingStep1 extends ConsumerStatefulWidget {
  final ParkingModel parking;
  final DateTime? selectedDate;
  final String? selectedSlot;
  final int durationMinutes;
  final String? selectedSpotId;
  final VehicleModel? selectedVehicle;

  final void Function(DateTime) onDateChanged;
  final void Function(String) onSlotChanged;
  final void Function(int) onDurationChanged;
  final void Function(String?) onSpotChanged;
  final void Function(VehicleModel) onVehicleChanged;

  const BookingStep1({
    super.key,
    required this.parking,
    required this.selectedDate,
    required this.selectedSlot,
    required this.durationMinutes,
    required this.selectedSpotId,
    required this.selectedVehicle,
    required this.onDateChanged,
    required this.onSlotChanged,
    required this.onDurationChanged,
    required this.onSpotChanged,
    required this.onVehicleChanged,
  });

  @override
  ConsumerState<BookingStep1> createState() => _BookingStep1State();
}

class _BookingStep1State extends ConsumerState<BookingStep1> {
  late DateTime _displayMonth;
  Set<String> _occupiedByBooking = {};
  bool _isLoadingOccupied = false;
  bool _hasShownHint = false;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showSlideHintIfNeeded());
  }

  // ── Min start time ────────────────────────────────────────

  TimeOfDay get _minStartTime {
    final now = DateTime.now();
    final selectedDate = widget.selectedDate ?? now;
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    final openParts = widget.parking.openingHour.split(':');
    final openTime = TimeOfDay(
        hour: int.parse(openParts[0]), minute: int.parse(openParts[1]));

    if (isToday) {
      final openMinutes = openTime.hour * 60 + openTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      return nowMinutes > openMinutes
          ? TimeOfDay(hour: now.hour, minute: now.minute)
          : openTime;
    }
    return openTime;
  }

  // ── Max end time (closing - 30min) ────────────────────────

  TimeOfDay get _maxEndTime {
    final parts = widget.parking.closingHour.split(':');
    final closeMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final maxMinutes = closeMinutes - 30;
    return TimeOfDay(hour: maxMinutes ~/ 60, minute: maxMinutes % 60);
  }

  // ── Format TimeOfDay ──────────────────────────────────────

  String fmtTOD(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Refresh occupied spots ────────────────────────────────

  Future<void> _refreshOccupied() async {
    if (widget.selectedDate == null || widget.selectedSlot == null) return;

    final parts = widget.selectedSlot!.split(':');
    final bookingStart = DateTime(
      widget.selectedDate!.year,
      widget.selectedDate!.month,
      widget.selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final bookingEnd =
        bookingStart.add(Duration(minutes: widget.durationMinutes));

    setState(() => _isLoadingOccupied = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      final occupied = await fs.getOccupiedSpotIds(
        parkingId: widget.parking.id,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
      );
      if (mounted) {
        setState(() {
          _occupiedByBooking = occupied;
          _isLoadingOccupied = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingOccupied = false);
    }
  }

  // ── Open time range picker ────────────────────────────────

  Future<void> _openTimePicker() async {
    TimeOfDay startInit = _minStartTime;
    TimeOfDay endInit = _maxEndTime;

    if (widget.selectedSlot != null) {
      final parts = widget.selectedSlot!.split(':');
      startInit =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      final endMinutes =
          startInit.hour * 60 + startInit.minute + widget.durationMinutes;
      endInit = TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);
    }

    final result = await showTimeRangePicker(
      context: context,
      start: startInit,
      end: endInit,

      // ── Configuration ─────────────────────────────
      interval: const Duration(minutes: 5),
      minDuration: const Duration(minutes: 30),
      maxDuration: Duration(
        minutes: _maxEndTime.hour * 60 +
            _maxEndTime.minute -
            (_minStartTime.hour * 60 + _minStartTime.minute),
      ),

      // ── Disabled range ────────────────────────────
      disabledTime: TimeRange(
        startTime: _maxEndTime,
        endTime: _minStartTime,
      ),

      // Softer disabled color
      disabledColor: Colors.transparent.withValues(alpha: 0.1),

      // ── Dial appearance ───────────────────────────
      selectedColor: AppColors.primary,
      backgroundColor: Colors.white,
      strokeColor: AppColors.primary.withValues(alpha: 0.6),
      strokeWidth: 10,

      handlerRadius: 12,

      // ── Tick marks ────────────────────────────────
      ticks: 48,
      ticksLength: 6,
      ticksWidth: 1.2,
      ticksColor: Colors.grey.shade300,

      use24HourFormat: true,

      // ── Labels ────────────────────────────────────
      labels: [
        '00h',
        '03h',
        '06h',
        '09h',
        '12h',
        '15h',
        '18h',
        '21h',
      ]
          .asMap()
          .entries
          .map(
            (e) => ClockLabel.fromIndex(
              idx: e.key,
              length: 8,
              text: e.value,
            ),
          )
          .toList(),

      labelOffset: 28,
      rotateLabels: false,
      padding: 36,
      labelStyle: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),

      // ── Header ────────────────────────────────────
      fromText: 'Début',
      toText: 'Fin',

      backgroundWidget: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),
    );

    if (result != null && mounted) {
      final startStr = fmtTOD(result.startTime);
      final startMins = result.startTime.hour * 60 + result.startTime.minute;
      final endMins = result.endTime.hour * 60 + result.endTime.minute;
      final duration = endMins - startMins;
      if (duration >= 30) {
        widget.onSlotChanged(startStr);
        widget.onDurationChanged(duration);
        Future.microtask(_refreshOccupied);
      }
    }
  }

  Future<void> _showSlideHintIfNeeded() async {
    if (_hasShownHint) return;
    final prefs = await SharedPreferences.getInstance();
    final shown = prefs.getBool('booking_slide_hint_shown') ?? false;
    if (!shown && mounted) {
      setState(() => _hasShownHint = true);
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe, size: 48, color: AppColors.primary),
              SizedBox(height: 12),
              Text(
                'Faites défiler la grille pour voir toutes les places disponibles.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await prefs.setBool('booking_slide_hint_shown', true);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('NE PLUS AFFICHER',
                  style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(parkingProvider).selectedParkingSpots;
    final userState = ref.watch(userProvider);
    final isPMR = userState.user?.isSpecialAccessUser ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info parking
          _ParkingInfoBanner(parking: widget.parking),
          const SizedBox(height: AppSizes.spaceL),

          // 1. Date
          _SectionHeader(icon: Icons.calendar_month, title: 'Select A Date'),
          const SizedBox(height: AppSizes.spaceM),
          _Calendar(
            selectedDate: widget.selectedDate ?? DateTime.now(),
            displayMonth: _displayMonth,
            onDateSelected: (date) {
              widget.onDateChanged(date);
              Future.microtask(_refreshOccupied);
            },
            onMonthChanged: (m) => setState(() => _displayMonth = m),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // 2. Créneau
          _SectionHeader(icon: Icons.access_time, title: 'Choisir un créneau'),
          const SizedBox(height: AppSizes.spaceM),
          _TimeRangeSelector(
            selectedSlot: widget.selectedSlot,
            durationMinutes: widget.durationMinutes,
            onTap: _openTimePicker,
            fmtTOD: fmtTOD,
          ),
          const SizedBox(height: AppSizes.spaceL),

          // 3. Grille spots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(icon: Icons.local_parking, title: 'Select A Spot'),
              if (_isLoadingOccupied)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: AppSizes.spaceS),
          _SpotLegend(),
          const SizedBox(height: AppSizes.spaceM),
          if (spots == null)
            const Center(child: CircularProgressIndicator())
          else if (widget.selectedSlot == null)
            Container(
              padding: const EdgeInsets.all(AppSizes.spaceL),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              child: const Row(children: [
                Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 18),
                SizedBox(width: AppSizes.spaceS),
                Text('Choisissez un créneau pour voir la disponibilité',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ]),
            )
          else
            _SpotGrid(
              spots: spots,
              selectedSpotId: widget.selectedSpotId,
              occupiedByBooking: _occupiedByBooking,
              isPMR: isPMR,
              onSpotTapped: (id) {
                if (widget.selectedSpotId == id) {
                  widget.onSpotChanged(null);
                } else {
                  widget.onSpotChanged(id);
                }
              },
            ),

          if (widget.selectedSpotId != null) ...[
            const SizedBox(height: AppSizes.spaceM),
            _SelectedSpotBadge(
              spotId: widget.selectedSpotId!,
              onClear: () => widget.onSpotChanged(null),
            ),
          ],

          const SizedBox(height: AppSizes.spaceL),

          // 4. Véhicule
          _SectionHeader(
              icon: Icons.directions_car_outlined, title: 'Select A Vehicle'),
          const SizedBox(height: AppSizes.spaceS),
          _VehicleSelector(
            vehicles: userState.vehicles,
            selectedVehicle: widget.selectedVehicle,
            onVehicleSelected: widget.onVehicleChanged,
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// CALENDRIER COMPACT
// ─────────────────────────────────────────────────────────────

class _Calendar extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime displayMonth;
  final void Function(DateTime) onDateSelected;
  final void Function(DateTime) onMonthChanged;

  const _Calendar({
    required this.selectedDate,
    required this.displayMonth,
    required this.onDateSelected,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final startOffset = (firstDay.weekday - 1) % 7;
    final daysInMonth =
        DateTime(displayMonth.year, displayMonth.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)
        ],
      ),
      child: Column(
        children: [
          // Navigation mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 20),
                onPressed: () => onMonthChanged(
                    DateTime(displayMonth.year, displayMonth.month - 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                DateFormat('MMMM yyyy', 'fr').format(displayMonth),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 20),
                onPressed: () => onMonthChanged(
                    DateTime(displayMonth.year, displayMonth.month + 1)),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXS),

          // Jours semaine
          Row(
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),

          // Grille jours
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.8,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startOffset) return const SizedBox.shrink();
              final day = i - startOffset + 1;
              final date = DateTime(displayMonth.year, displayMonth.month, day);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date.year == selectedDate.year &&
                  date.month == selectedDate.month &&
                  date.day == selectedDate.day;
              final isPast =
                  date.isBefore(DateTime(today.year, today.month, today.day));

              return GestureDetector(
                onTap: isPast ? null : () => onDateSelected(date),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isToday
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected || isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : isPast
                                ? AppColors.border
                                : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TIME RANGE SELECTOR
// ─────────────────────────────────────────────────────────────

class _TimeRangeSelector extends StatelessWidget {
  final String? selectedSlot;
  final int durationMinutes;
  final VoidCallback onTap;
  final String Function(TimeOfDay) fmtTOD;

  const _TimeRangeSelector({
    required this.selectedSlot,
    required this.durationMinutes,
    required this.onTap,
    required this.fmtTOD,
  });

  String get _endTime {
    if (selectedSlot == null) return '--:--';
    final parts = selectedSlot!.split(':');
    final startMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endMins = startMins + durationMinutes;
    final h = (endMins ~/ 60).toString().padLeft(2, '0');
    final m = (endMins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _durationStr {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}min';
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  @override
  Widget build(BuildContext context) {
    final hasSlot = selectedSlot != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.spaceM),
        decoration: BoxDecoration(
          color: hasSlot
              ? AppColors.primary.withValues(alpha: 0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: hasSlot ? AppColors.primary : AppColors.border,
            width: hasSlot ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)
          ],
        ),
        child: Row(
          children: [
            // De
            Expanded(
              child: Column(children: [
                const Text('De',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  selectedSlot ?? '--:--',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        hasSlot ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ]),
            ),
            // Séparateur + durée
            Column(children: [
              const Icon(Icons.arrow_forward,
                  color: AppColors.textSecondary, size: 18),
              if (hasSlot) ...[
                const SizedBox(height: 2),
                Text(_durationStr,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ]),
            // À
            Expanded(
              child: Column(children: [
                const Text('À',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  _endTime,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        hasSlot ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ]),
            ),
            // Edit
            Icon(
              hasSlot ? Icons.edit_outlined : Icons.add_circle_outline,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GRILLE SPOTS - ENTRÉE toujours visible, focus A0/A1
// ─────────────────────────────────────────────────────────────

class _SpotGrid extends StatefulWidget {
  final ParkingSpotsInfo spots;
  final String? selectedSpotId;
  final Set<String> occupiedByBooking;
  final bool isPMR;
  final void Function(String) onSpotTapped;

  const _SpotGrid({
    required this.spots,
    required this.selectedSpotId,
    required this.occupiedByBooking,
    required this.isPMR,
    required this.onSpotTapped,
  });

  @override
  State<_SpotGrid> createState() => _SpotGridState();
}

class _SpotGridState extends State<_SpotGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
    final aisleA = widget.spots.allIds
        .where((id) => id.startsWith('A'))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final aisleB = widget.spots.allIds
        .where((id) => id.startsWith('B'))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final maxLen =
        aisleA.length > aisleB.length ? aisleA.length : aisleB.length;

    const double rowHeight = 60;
    const int visibleRows = 6;
    const double fixedHeight = rowHeight * visibleRows + 60;

    return Container(
      height: maxLen > visibleRows ? fixedHeight : null,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.spaceM,
        horizontal: AppSizes.spaceS,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          // SORTIE en haut (toujours visible)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, color: AppColors.error, size: 18),
                SizedBox(width: 6),
                Text(
                  'SORTIE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Grille scrollable
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Grille des places
                  ...List.generate(maxLen, (i) {
                    final idA = i < aisleA.length ? aisleA[i] : null;
                    final idB = i < aisleB.length ? aisleB[i] : null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          if (idA != null)
                            Expanded(
                              child: _SpotTile(
                                spotId: idA,
                                spots: widget.spots,
                                isSelected: widget.selectedSpotId == idA,
                                occupiedByBooking: widget.occupiedByBooking,
                                isPMR: widget.isPMR,
                                onTap: () => widget.onSpotTapped(idA),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                          SizedBox(
                            width: 70,
                            child: Center(
                              child: Container(
                                width: 50,
                                height: AppSizes.spotCardHeight,
                                decoration: BoxDecoration(
                                  color: Colors.transparent.withAlpha(1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          if (idB != null)
                            Expanded(
                              child: _SpotTile(
                                spotId: idB,
                                spots: widget.spots,
                                isSelected: widget.selectedSpotId == idB,
                                occupiedByBooking: widget.occupiedByBooking,
                                isPMR: widget.isPMR,
                                onTap: () => widget.onSpotTapped(idB),
                              ),
                            )
                          else
                            const Expanded(child: SizedBox()),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ENTRÉE en bas (toujours visible, en dehors du scroll)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 4,
                  color: Colors.black12,
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_upward, color: AppColors.primary, size: 18),
                SizedBox(width: 6),
                Text(
                  'ENTRÉE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotTile extends StatelessWidget {
  final String spotId;
  final ParkingSpotsInfo spots;
  final bool isSelected;
  final Set<String> occupiedByBooking;
  final bool isPMR;
  final VoidCallback onTap;

  const _SpotTile({
    required this.spotId,
    required this.spots,
    required this.isSelected,
    required this.occupiedByBooking,
    required this.isPMR,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSpecial = spots.specialIds.contains(spotId);

    final isPhysOccupied = spots.occupiedFromWalkInIds.contains(spotId) ||
        spots.occupiedFromBookingIds.contains(spotId);

    final isBookedForSlot = occupiedByBooking.contains(spotId);

    final isPMRRestricted = isSpecial && !isPMR;

    final canBook = !isPhysOccupied && !isBookedForSlot && !isPMRRestricted;

    // ── COLORS (for subtle accents only) ─────────────
    final Color accentColor;
    if (isSelected) {
      accentColor = AppColors.primary;
    } else if (isPhysOccupied) {
      accentColor = AppColors.error;
    } else if (isBookedForSlot) {
      accentColor = AppColors.warning;
    } else if (isSpecial) {
      accentColor = AppColors.info;
    } else {
      accentColor = AppColors.success;
    }

    final bool isDisabled = isPhysOccupied || isPMRRestricted;

    return GestureDetector(
      onTap: (canBook || isSelected) ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: AppSizes.spotCardHeight - 25,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: isSelected ? 2.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: isSelected ? 10 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── TOP ROW (UNCHANGED ICONS) ───────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSpecial)
                    const Icon(
                      Icons.accessible,
                      size: 12,
                      color: Colors.grey,
                    ),
                  Icon(
                    isPhysOccupied || isBookedForSlot
                        ? Icons.lock_outlined
                        : Icons.lock_open_outlined,
                    size: 12,
                    color: isDisabled ? Colors.grey.shade400 : accentColor,
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // ── SPOT ID ────────────────────────────────
              Text(
                spotId,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDisabled ? Colors.grey.shade500 : Colors.black87,
                ),
              ),

              const SizedBox(height: 2),

              // ── STATUS TEXT (UNCHANGED LOGIC) ───────────
              if (isPhysOccupied)
                Text(
                  'Occupée',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.error.withValues(alpha: 0.8),
                  ),
                )
              else if (isBookedForSlot)
                Text(
                  'Réservée',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.warning.withValues(alpha: 0.8),
                  ),
                )
              else if (isPMRRestricted)
                Text(
                  'PMR',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.info.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// SPOT LEGEND - Couleurs plus vives
// ─────────────────────────────────────────────────────────────

class _SpotLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.spaceM,
      runSpacing: 4,
      children: const [
        _LegendDot(color: AppColors.success, label: 'Libre'),
        _LegendDot(color: AppColors.info, label: 'PMR'),
        _LegendDot(color: AppColors.warning, label: 'Réservée'),
        _LegendDot(color: AppColors.error, label: 'Occupée'),
        _LegendDot(color: AppColors.primary, label: 'Sélectionnée'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
                color: color, width: 1.5)), // Bordure de la même couleur
      ),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _SelectedSpotBadge extends StatelessWidget {
  final String spotId;
  final VoidCallback onClear;
  const _SelectedSpotBadge({required this.spotId, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceM, vertical: AppSizes.spaceS),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 18),
        const SizedBox(width: AppSizes.spaceS),
        Text('Place $spotId sélectionnée',
            style: const TextStyle(
                color: AppColors.success, fontWeight: FontWeight.bold)),
        const Spacer(),
        GestureDetector(
          onTap: onClear,
          child:
              const Icon(Icons.close, color: AppColors.textSecondary, size: 18),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// VEHICLE SELECTOR - Pleine largeur
// ─────────────────────────────────────────────────────────────

class _VehicleSelector extends StatelessWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;
  final void Function(VehicleModel) onVehicleSelected;

  const _VehicleSelector({
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSizes.spaceL),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(children: [
          Icon(Icons.directions_car_outlined, color: AppColors.textSecondary),
          SizedBox(width: AppSizes.spaceS),
          Expanded(
            child: Text('Aucun véhicule — ajoutez-en depuis votre profil',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
        ]),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: vehicles.length == 1 ? 80 : 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vehicles.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSizes.spaceS),
            itemBuilder: (_, i) {
              final v = vehicles[i];
              final isSel = selectedVehicle?.id == v.id;
              return GestureDetector(
                onTap: () => onVehicleSelected(v),
                child: SizedBox(
                  width: vehicles.length == 1
                      ? MediaQuery.of(context).size.width - 32
                      : MediaQuery.of(context).size.width * 0.72,
                  child: LicensePlateWidget(
                      vehicle: v,
                      isDefault: vehicles[i].isCurrentlySelected,
                      isSelected: isSel,
                      compact: true),
                ),
              );
            },
          ),
        ),
        // ← ICI, juste après le SizedBox de la liste
        if (vehicles.length > 1) ...[
          const SizedBox(height: AppSizes.spaceXS),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe, size: 14, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('Glissez pour changer de véhicule',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ParkingInfoBanner extends StatelessWidget {
  final ParkingModel parking;
  const _ParkingInfoBanner({required this.parking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.location_on_outlined,
            color: AppColors.primary, size: 16),
        const SizedBox(width: AppSizes.spaceXS),
        Expanded(
          child: Text(parking.streetAddress,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text('${parking.feePerSlot} SPM/30min',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
            color: AppColors.primary, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
      const SizedBox(width: AppSizes.spaceS),
      Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    ]);
  }
}
