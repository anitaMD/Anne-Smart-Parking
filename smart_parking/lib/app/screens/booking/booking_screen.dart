import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking/app/models/booking_model.dart';
import 'package:smart_parking/app/models/vehicle_model.dart';
import 'package:smart_parking/app/screens/booking/booking_stepper.dart';
import 'package:smart_parking/app/screens/settings/settings_screen.dart';
import 'package:smart_parking/app/viewmodels/parking_viewmodel.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/parking_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/license_plate_widget.dart';
import '../../router/app_router.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final ParkingModel parking;
  final BookingModel? existingBooking;

  const BookingScreen({super.key, required this.parking, this.existingBooking});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Étape 1 — Place sélectionnée
  String? _selectedSpotId;

  // Étape 2 — Créneau
  DateTime get _bookingStart {
    if (_selectedDate == null || _selectedSlot == null) {
      return DateTime.now();
    }

    final parts = _selectedSlot!.split(':');

    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  int _durationMinutes = 30;

  // État
  bool _isConfirming = false;

  // Durées disponibles
  DateTime? _selectedDate = DateTime.now();
  String? _selectedSlot;
  VehicleModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    if (widget.existingBooking != null) {
      final b = widget.existingBooking!;
      _selectedDate = b.bookingStart;
      _selectedSlot = DateFormat('HH:mm').format(b.bookingStart);
      _durationMinutes = b.durationMinutes;
      _selectedSpotId = b.spotId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedVehicle = ref.read(userProvider).defaultVehicle;
    });
    // Dans BookingScreen.initState() — ajouter
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(parkingProvider.notifier).selectParking(widget.parking);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────

  void _nextPage(AppLocalizations l10n) {
    if (_currentPage == 0) {
      if (_selectedSpotId == null) {
        _showSnack(l10n.bookingSelectSpotError);
        return;
      }
      if (_selectedSlot == null) {
        _showSnack(l10n.bookingSelectDateError);
        return;
      }
      if (_selectedVehicle == null) {
        _showSnack(l10n.bookingSelectVehicleError);
        return;
      }
    }
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ── Calculs ───────────────────────────────────────────────

  DateTime get _bookingEnd =>
      _bookingStart.add(Duration(minutes: _durationMinutes));

  int get _totalCost {
    final slots = _durationMinutes ~/ 30;
    return slots * widget.parking.feePerSlot;
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h${m}min';
  }

  String _formatTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  // ── Confirmation ──────────────────────────────────────────

  Future<void> _confirm(AppLocalizations l10n) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final userState = ref.read(userProvider);
    final wallet = userState.wallet;

    if ((wallet?.balance ?? 0) < _totalCost) {
      _showSnack(l10n.bookingInsufficientBalance);
      return;
    }

    if (userState.defaultVehicle == null) {
      _showSnack(l10n.bookingSelectVehicleError);
      return;
    }

    setState(() => _isConfirming = true);

    try {
      if (widget.existingBooking != null) {
        // ← MODE ÉDITION
        await ref.read(bookingProvider.notifier).editBooking(
              booking: widget.existingBooking!,
              newStart: _bookingStart,
              newEnd: _bookingEnd,
              newSpotId: _selectedSpotId!,
              parkingName: widget.parking.name,
              feePerSlot: widget.parking.feePerSlot,
            );
      } else {
        // ← MODE CRÉATION
        await ref.read(bookingProvider.notifier).createBooking(
              clientId: authState.user.id,
              parkingId: widget.parking.id,
              spotId: _selectedSpotId!,
              vehicleId: userState.defaultVehicle!.id,
              bookingStart: _bookingStart,
              bookingEnd: _bookingEnd,
              totalCost: _totalCost,
              parkingName: widget.parking.name,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingBooking != null
                ? l10n.bookingSuccessEdit
                : l10n.bookingSuccessNew),
            behavior: SnackBarBehavior.floating,
          ),
        );
        AppRouter.pushAndClearStack(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        _showSnack(l10n.bookingErrorGeneric(e.toString()));
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.parking.name),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              _currentPage == 0 ? () => Navigator.pop(context) : _prevPage,
        ),
      ),
      body: Column(
        children: [
          // ── Stepper indicator ────────────────────────────
          _StepIndicator(currentStep: _currentPage),

          // ── PageView ─────────────────────────────────────
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // Page 1 — Grille places
                BookingStep1(
                    parking: widget.parking,
                    selectedDate: _selectedDate, // variable du state
                    selectedSlot: _selectedSlot, // variable du state
                    durationMinutes: _durationMinutes, // variable du state
                    selectedSpotId: _selectedSpotId, // variable du state
                    selectedVehicle: _selectedVehicle, // variable du state
                    onDateChanged: (date) => setState(() {
                          _selectedDate = date;
                          _selectedSlot = null; // ← reset
                          _durationMinutes = 30; // ← reset
                          _selectedSpotId = null; // ← reset
                        }),
                    onSlotChanged: (slot) =>
                        setState(() => _selectedSlot = slot),
                    onDurationChanged: (d) =>
                        setState(() => _durationMinutes = d),
                    onSpotChanged: (id) => setState(() => _selectedSpotId = id),
                    onVehicleChanged: (v) =>
                        setState(() => _selectedVehicle = v),
                    l10n: l10n),

                _selectedVehicle == null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.spaceXL),
                          child: Text(l10n.bookingNoVehicleStep,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : _SummaryPage(
                        parking: widget.parking,
                        existingBooking: widget.existingBooking,
                        spotId: _selectedSpotId ?? '',
                        bookingStart: _bookingStart,
                        bookingEnd: _bookingEnd,
                        selectedDate: _selectedDate!,
                        totalCost: _totalCost,
                        formatTime: _formatTime,
                        formatDuration: _formatDuration,
                        durationMinutes: _durationMinutes,
                        selectedVehicle: _selectedVehicle!,
                      ),
              ],
            ),
          ),

          // ── Bouton suivant / confirmer ────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceM),
              child: _isConfirming
                  ? Center(
                      child: SpinKitFadingCircle(
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_currentPage == 1) {
                            _confirm(l10n);
                          } else {
                            _nextPage(l10n);
                          }
                        },
                        child: Text(
                          _currentPage == 1
                              ? widget.existingBooking != null
                                  ? l10n.bookingConfirmEdit
                                  : l10n.bookingConfirmNew
                              : l10n.commonNext,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP INDICATOR
// ─────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = [l10n.bookingStepParking, l10n.bookingStepSummary];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceM, horizontal: AppSizes.spaceL),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connecteur
            return Expanded(
              child: Container(
                height: 2,
                color:
                    i ~/ 2 < currentStep ? AppColors.primary : AppColors.border,
              ),
            );
          }
          final step = i ~/ 2;
          final isActive = step == currentStep;
          final isDone = step < currentStep;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDone || isActive ? AppColors.primary : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDone || isActive
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[step],
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  )),
            ],
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 1 — GRILLE DES PLACES
// ─────────────────────────────────────────────────────────────

class _SummaryPage extends ConsumerWidget {
  final ParkingModel parking;
  final String spotId;
  final DateTime bookingStart;
  final DateTime bookingEnd;
  final DateTime selectedDate;
  final int totalCost;
  final int durationMinutes;
  final String Function(DateTime) formatTime;
  final String Function(int) formatDuration;
  final VehicleModel selectedVehicle;
  final BookingModel? existingBooking;

  const _SummaryPage({
    required this.parking,
    required this.spotId,
    required this.bookingStart,
    required this.bookingEnd,
    required this.selectedDate,
    required this.totalCost,
    required this.durationMinutes,
    required this.formatTime,
    required this.formatDuration,
    required this.selectedVehicle,
    this.existingBooking,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final vehicle = selectedVehicle;
    final balance = userState.wallet?.balance ?? 0;
    final balanceAfter = balance - totalCost;
    final isPMR = spotId.startsWith('B') && (spotId == 'B4' || spotId == 'B5');
    final l10n = AppLocalizations.of(context)!;
    final localeName = ref.watch(localeProvider).languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Véhicule

          Text(l10n.bookingVehicle,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  fontSize: 12)),
          const SizedBox(height: AppSizes.spaceS),
          LicensePlateWidget(vehicle: vehicle, isDefault: true, compact: true),
          const SizedBox(height: AppSizes.spaceL),

          // Parking + place
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.local_parking,
                label: l10n.bookingParking,
                value: parking.name,
              ),
              _SummaryRow(
                icon: isPMR ? Icons.accessible : Icons.directions_car,
                label: l10n.bookingSpot,
                value: spotId + (isPMR ? ' ♿' : ''),
                valueColor: isPMR ? AppColors.info : null,
              ),
              _SummaryRow(
                icon: Icons.location_on_outlined,
                label: l10n.bookingAddress,
                value: parking.streetAddress,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Créneau
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.calendar_today_outlined,
                label: l10n.bookingDate,
                value: DateFormat(
                  'EEEE d MMMM yyyy',
                  localeName,
                ).format(selectedDate),
              ),
              _SummaryRow(
                icon: Icons.play_arrow_outlined,
                label: l10n.bookingStart,
                value: formatTime(bookingStart),
              ),
              _SummaryRow(
                icon: Icons.stop_outlined,
                label: l10n.bookingEnd,
                value: formatTime(bookingEnd),
              ),
              _SummaryRow(
                icon: Icons.timer_outlined,
                label: l10n.bookingDuration,
                value: formatDuration(durationMinutes),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Coût + solde
          _SummaryCard(
            children: [
              if (existingBooking != null) ...[
                // Mode édition — afficher la différence
                Builder(builder: (_) {
                  final oldCost = existingBooking!.totalCost;
                  final diff = totalCost - oldCost;
                  if (diff > 0) {
                    // Durée augmentée → supplément à payer
                    return Column(children: [
                      _SummaryRow(
                        icon: Icons.monetization_on_outlined,
                        label: l10n.bookingOriginalCost,
                        value: '$oldCost SPM',
                      ),
                      _SummaryRow(
                        icon: Icons.add_circle_outlined,
                        label: l10n.bookingSupplement,
                        value: '+$diff SPM',
                        valueColor: AppColors.error,
                        valueBold: true,
                      ),
                      _SummaryRow(
                        icon: Icons.account_balance_wallet_outlined,
                        label: l10n.bookingCurrentBalance,
                        value: '$balance SPM',
                      ),
                      _SummaryRow(
                        icon: Icons.arrow_forward_outlined,
                        label: l10n.bookingBalanceAfter,
                        value: '${balance - diff} SPM',
                        valueColor: (balance - diff) < 0
                            ? AppColors.error
                            : AppColors.success,
                        valueBold: true,
                      ),
                    ]);
                  } else if (diff < 0) {
                    // Durée réduite → pas de remboursement
                    return Column(children: [
                      _SummaryRow(
                        icon: Icons.monetization_on_outlined,
                        label: l10n.bookingCost,
                        value: '$oldCost SPM',
                        valueColor: AppColors.primary,
                        valueBold: true,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: AppSizes.spaceS),
                        padding: const EdgeInsets.all(AppSizes.spaceS),
                        decoration: BoxDecoration(
                          color: AppColors.info.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        ),
                        child: Row(children: [
                          Icon(Icons.info_outline,
                              color: AppColors.info, size: 14),
                          SizedBox(width: 6),
                          Expanded(
                              child: Text(
                            l10n.bookingReducedDuration,
                            style:
                                TextStyle(color: AppColors.info, fontSize: 11),
                          )),
                        ]),
                      ),
                    ]);
                  } else {
                    // Inchangé
                    return _SummaryRow(
                      icon: Icons.monetization_on_outlined,
                      label: l10n.bookingCost,
                      value: '${l10n.bookingPriceUnchanged}($totalCost SPM)',
                      valueColor: AppColors.textSecondary,
                    );
                  }
                }),
              ] else ...[
                // Mode création — comportement normal
                _SummaryRow(
                  icon: Icons.monetization_on_outlined,
                  label: l10n.bookingCost,
                  value: '$totalCost SPM',
                  valueColor: AppColors.primary,
                  valueBold: true,
                ),
                _SummaryRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: l10n.bookingCurrentBalance,
                  value: '$balance SPM',
                ),
                _SummaryRow(
                  icon: Icons.arrow_forward_outlined,
                  label: l10n.bookingBalanceAfter,
                  value: '$balanceAfter SPM',
                  valueColor:
                      balanceAfter < 0 ? AppColors.error : AppColors.success,
                  valueBold: true,
                ),
              ],
            ],
          ),

          // Avertissement solde insuffisant
          if (balanceAfter < 0) ...[
            const SizedBox(height: AppSizes.spaceM),
            Container(
              padding: const EdgeInsets.all(AppSizes.spaceM),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border:
                    Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      color: AppColors.error, size: 20),
                  const SizedBox(width: AppSizes.spaceS),
                  Expanded(
                    child: Text(
                      l10n.bookingInsufficientBalance,
                      style: TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<Widget> children;
  const _SummaryCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children
            .expand((w) => [
                  w,
                  if (w != children.last) const Divider(height: AppSizes.spaceL)
                ])
            .toList(),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: AppSizes.spaceS),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
            )),
      ],
    );
  }
}
