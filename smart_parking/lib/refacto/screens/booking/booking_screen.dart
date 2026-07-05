import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:smart_parking/refacto/models/vehicle_model.dart';
import 'package:smart_parking/refacto/screens/booking/booking_screen_merge.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/parking_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/parking_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/license_plate_widget.dart';
import '../../router/app_router.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final ParkingModel parking;

  const BookingScreen({super.key, required this.parking});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Étape 1 — Place sélectionnée
  String? _selectedSpotId;

  // Étape 2 — Créneau
  DateTime _bookingStart = DateTime.now();
  bool _startNow = true;
  int _durationMinutes = 30;

  // État
  bool _isConfirming = false;

  // Durées disponibles
  final List<int> _durations = [30, 60, 90, 120, 150, 180];
  DateTime? _selectedDate = DateTime.now();
  String? _selectedSlot;
  VehicleModel? _selectedVehicle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _selectedVehicle = ref.read(userProvider).defaultVehicle;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Navigation ────────────────────────────────────────────

  void _nextPage() {
    if (_currentPage == 0) {
      if (_selectedSpotId == null) {
        _showSnack('Veuillez sélectionner une place');
        return;
      }
      if (_selectedSlot == null) {
        _showSnack('Veuillez choisir un créneau');
        return;
      }
      if (_selectedVehicle == null) {
        _showSnack('Veuillez sélectionner un véhicule');
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

  Future<void> _confirm() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final userState = ref.read(userProvider);
    final wallet = userState.wallet;

    // Vérifier solde suffisant
    if ((wallet?.balance ?? 0) < _totalCost) {
      _showSnack('Solde insuffisant. Rechargez votre wallet YSP.');
      return;
    }

    // Vérifier véhicule par défaut
    if (userState.defaultVehicle == null) {
      _showSnack('Aucun véhicule sélectionné.');
      return;
    }

    setState(() => _isConfirming = true);

    try {
      await ref.read(bookingProvider.notifier).createBooking(
            clientId: authState.user.id,
            parkingId: widget.parking.id,
            spotId: _selectedSpotId!,
            vehicleId: userState.defaultVehicle!.id,
            bookingStart: _bookingStart,
            bookingEnd: _bookingEnd,
            totalCost: _totalCost,
            parkingName: widget.parking.name, // ← ajouter
          );

      if (mounted) {
        // Succès → retour au dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation confirmée ! 🎉'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        AppRouter.pushAndClearStack(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur : ${e.toString()}');
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
                  onDateChanged: (date) => setState(() => _selectedDate = date),
                  onSlotChanged: (slot) => setState(() => _selectedSlot = slot),
                  onDurationChanged: (d) =>
                      setState(() => _durationMinutes = d),
                  onSpotChanged: (id) => setState(() => _selectedSpotId = id),
                  onVehicleChanged: (v) => setState(() => _selectedVehicle = v),
                ),

                _selectedVehicle == null
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.spaceXL),
                          child: Text(
                              'Sélectionnez un véhicule à l\'étape précédente',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary)),
                        ),
                      )
                    : _SummaryPage(
                        parking: widget.parking,
                        spotId: _selectedSpotId ?? '',
                        bookingStart: _bookingStart,
                        bookingEnd: _bookingEnd,
                        totalCost: _totalCost,
                        formatTime: _formatTime,
                        formatDuration: _formatDuration,
                        durationMinutes: _durationMinutes,
                      ),
                /*// Page 2 — Créneau
                _SlotPage(
                  startNow: _startNow,
                  bookingStart: _bookingStart,
                  durationMinutes: _durationMinutes,
                  durations: _durations,
                  parking: widget.parking,
                  totalCost: _totalCost,
                  formatDuration: _formatDuration,
                  formatTime: _formatTime,
                  bookingEnd: _bookingEnd,
                  onStartNowChanged: (v) => setState(() {
                    _startNow = v;
                    if (v) _bookingStart = DateTime.now();
                  }),
                  onStartTimeChanged: (dt) =>
                      setState(() => _bookingStart = dt),
                  onDurationChanged: (d) =>
                      setState(() => _durationMinutes = d),
                ),

                // Page 3 — Récapitulatif
                _SummaryPage(
                  parking: widget.parking,
                  spotId: _selectedSpotId ?? '',
                  bookingStart: _bookingStart,
                  bookingEnd: _bookingEnd,
                  totalCost: _totalCost,
                  formatTime: _formatTime,
                  formatDuration: _formatDuration,
                  durationMinutes: _durationMinutes,
                ),*/
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
                        onPressed: _currentPage == 2 ? _confirm : _nextPage,
                        child: Text(
                          _currentPage == 2
                              ? 'Confirmer la réservation'
                              : 'Suivant',
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
    final steps = ['Parking', 'Récapitulatif'];
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

class _SpotGridPage extends ConsumerWidget {
  final ParkingModel parking;
  final String? selectedSpotId;
  final void Function(String) onSpotSelected;

  const _SpotGridPage({
    required this.parking,
    required this.selectedSpotId,
    required this.onSpotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parkingState = ref.watch(parkingProvider);
    final spots = parkingState.selectedParkingSpots;

    if (spots == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Construire la grille : A0-A5, B0-B5
    // B4 et B5 sont PMR (specialIds)
    final allSpots = spots.allIds;
    final aisleA = allSpots.where((id) => id.startsWith('A')).toList()..sort();
    final aisleB = allSpots.where((id) => id.startsWith('B')).toList()..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info parking
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceM),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: AppSizes.spaceXS),
                Expanded(
                  child: Text(
                    parking.streetAddress,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                Text('${parking.feePerSlot} SPM/30min',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),

          const Text('Choisissez une place',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),

          // Légende
          const _SpotLegend(),
          const SizedBox(height: AppSizes.spaceL),

          // Allée A
          _AisleGrid(
            label: 'Allée A',
            spotIds: aisleA,
            spots: spots,
            selectedSpotId: selectedSpotId,
            onSpotSelected: onSpotSelected,
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Allée B
          _AisleGrid(
            label: 'Allée B',
            spotIds: aisleB,
            spots: spots,
            selectedSpotId: selectedSpotId,
            onSpotSelected: onSpotSelected,
          ),

          if (selectedSpotId != null) ...[
            const SizedBox(height: AppSizes.spaceL),
            Container(
              padding: const EdgeInsets.all(AppSizes.spaceM),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.success, size: 20),
                  const SizedBox(width: AppSizes.spaceS),
                  Text(
                    'Place $selectedSpotId sélectionnée',
                    style: const TextStyle(
                        color: AppColors.success, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AisleGrid extends StatelessWidget {
  final String label;
  final List<String> spotIds;
  final ParkingSpotsInfo spots;
  final String? selectedSpotId;
  final void Function(String) onSpotSelected;

  const _AisleGrid({
    required this.label,
    required this.spotIds,
    required this.spots,
    required this.selectedSpotId,
    required this.onSpotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label allée
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceM, vertical: AppSizes.spaceXS),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusFull),
          ),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary)),
        ),
        const SizedBox(height: AppSizes.spaceS),

        // Grille
        Row(
          children: spotIds.map((id) {
            final isPMR = spots.specialIds.contains(id);
            final isOccupied = spots.occupiedFromBookingIds.contains(id) ||
                spots.occupiedFromWalkInIds.contains(id);
            final isBooked = spots.bookedIds.contains(id);
            final isAvailable = spots.availableIds.contains(id);
            final isSelected = selectedSpotId == id;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: _SpotCard(
                  spotId: id,
                  isPMR: isPMR,
                  isOccupied: isOccupied,
                  isBooked: isBooked,
                  isAvailable: isAvailable,
                  isSelected: isSelected,
                  onTap: (isOccupied || isBooked)
                      ? null
                      : () => onSpotSelected(id),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SpotCard extends StatelessWidget {
  final String spotId;
  final bool isPMR;
  final bool isOccupied;
  final bool isBooked;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback? onTap;

  const _SpotCard({
    required this.spotId,
    required this.isPMR,
    required this.isOccupied,
    required this.isBooked,
    required this.isAvailable,
    required this.isSelected,
    required this.onTap,
  });

  Color get _bgColor {
    if (isSelected) return AppColors.primary;
    if (isOccupied) return AppColors.error.withValues(alpha: 0.15);
    if (isBooked) return AppColors.warning.withValues(alpha: 0.15);
    if (isPMR) return AppColors.info.withValues(alpha: 0.15);
    return AppColors.success.withValues(alpha: 0.15);
  }

  Color get _borderColor {
    if (isSelected) return AppColors.primary;
    if (isOccupied) return AppColors.error;
    if (isBooked) return AppColors.warning;
    if (isPMR) return AppColors.info;
    return AppColors.success;
  }

  Color get _textColor {
    if (isSelected) return Colors.white;
    if (isOccupied) return AppColors.error;
    if (isBooked) return AppColors.warning;
    if (isPMR) return AppColors.info;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppSizes.spotCardHeight,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPMR)
              Icon(Icons.accessible,
                  color: _textColor, size: AppSizes.spotLedSize)
            else
              Icon(Icons.directions_car,
                  color: _textColor, size: AppSizes.spotLedSize),
            const SizedBox(height: 4),
            Text(spotId,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _textColor)),
            if (isOccupied)
              Text('Occupée', style: TextStyle(fontSize: 8, color: _textColor))
            else if (isBooked)
              Text('Réservée',
                  style: TextStyle(fontSize: 8, color: _textColor)),
          ],
        ),
      ),
    );
  }
}

class _SpotLegend extends StatelessWidget {
  const _SpotLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.spaceM,
      runSpacing: AppSizes.spaceXS,
      children: const [
        _LegendItem(color: AppColors.success, label: 'Libre'),
        _LegendItem(color: AppColors.info, label: 'PMR'),
        _LegendItem(color: AppColors.warning, label: 'Réservée'),
        _LegendItem(color: AppColors.error, label: 'Occupée'),
        _LegendItem(color: AppColors.primary, label: 'Sélectionnée'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: color))),
        const SizedBox(width: 4),
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 2 — CRÉNEAU
// ─────────────────────────────────────────────────────────────

class _SlotPage extends StatelessWidget {
  final bool startNow;
  final DateTime bookingStart;
  final int durationMinutes;
  final List<int> durations;
  final ParkingModel parking;
  final int totalCost;
  final DateTime bookingEnd;
  final String Function(int) formatDuration;
  final String Function(DateTime) formatTime;
  final void Function(bool) onStartNowChanged;
  final void Function(DateTime) onStartTimeChanged;
  final void Function(int) onDurationChanged;

  const _SlotPage({
    required this.startNow,
    required this.bookingStart,
    required this.durationMinutes,
    required this.durations,
    required this.parking,
    required this.totalCost,
    required this.bookingEnd,
    required this.formatDuration,
    required this.formatTime,
    required this.onStartNowChanged,
    required this.onStartTimeChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choisissez votre créneau',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceL),

          // ── Heure de début ───────────────────────────────
          const Text('Heure de début',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),

          // Toggle Maintenant / Choisir
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onStartNowChanged(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.spaceM),
                    decoration: BoxDecoration(
                      color: startNow ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(
                        color: startNow ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text('Maintenant',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: startNow
                                  ? Colors.white
                                  : AppColors.textSecondary)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(bookingStart),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      onStartTimeChanged(DateTime(now.year, now.month, now.day,
                          picked.hour, picked.minute));
                      onStartNowChanged(false);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSizes.spaceM),
                    decoration: BoxDecoration(
                      color: !startNow ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(
                        color: !startNow ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        !startNow ? formatTime(bookingStart) : 'Choisir',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: !startNow
                                ? Colors.white
                                : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceL),

          // ── Durée ────────────────────────────────────────
          const Text('Durée', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),

          Wrap(
            spacing: AppSizes.spaceS,
            runSpacing: AppSizes.spaceS,
            children: durations.map((d) {
              final isSelected = durationMinutes == d;
              return GestureDetector(
                onTap: () => onDurationChanged(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spaceL, vertical: AppSizes.spaceM),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(formatDuration(d),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // ── Résumé du créneau ────────────────────────────
          // APRÈS
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceL),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Début',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text(formatTime(bookingStart),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: AppSizes.spaceS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Fin',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text(formatTime(bookingEnd),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const Divider(height: AppSizes.spaceL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Coût total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('$totalCost SPM',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.primary)),
                  ],
                ),
                // ── AJOUT : solde en temps réel ──────────────────
                const Divider(height: AppSizes.spaceL),
                Consumer(
                  builder: (_, ref, __) {
                    final balance =
                        ref.watch(userProvider).wallet?.balance ?? 0;
                    final sufficient = balance >= totalCost;
                    return Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Votre solde',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                            Text('$balance SPM',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: sufficient
                                        ? AppColors.success
                                        : AppColors.error)),
                          ],
                        ),
                        if (!sufficient) ...[
                          const SizedBox(height: AppSizes.spaceXS),
                          const Row(
                            children: [
                              Icon(Icons.warning_amber_outlined,
                                  color: AppColors.error, size: 14),
                              SizedBox(width: 4),
                              Text('Solde insuffisant',
                                  style: TextStyle(
                                      color: AppColors.error, fontSize: 12)),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PAGE 3 — RÉCAPITULATIF
// ─────────────────────────────────────────────────────────────

class _SummaryPage extends ConsumerWidget {
  final ParkingModel parking;
  final String spotId;
  final DateTime bookingStart;
  final DateTime bookingEnd;
  final int totalCost;
  final int durationMinutes;
  final String Function(DateTime) formatTime;
  final String Function(int) formatDuration;

  const _SummaryPage({
    required this.parking,
    required this.spotId,
    required this.bookingStart,
    required this.bookingEnd,
    required this.totalCost,
    required this.durationMinutes,
    required this.formatTime,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final vehicle = userState.defaultVehicle;
    final balance = userState.wallet?.balance ?? 0;
    final balanceAfter = balance - totalCost;
    final isPMR = spotId.startsWith('B') && (spotId == 'B4' || spotId == 'B5');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Véhicule
          if (vehicle != null) ...[
            const Text('Véhicule',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: 12)),
            const SizedBox(height: AppSizes.spaceS),
            LicensePlateWidget(
                vehicle: vehicle, isDefault: true, compact: true),
            const SizedBox(height: AppSizes.spaceL),
          ],

          // Parking + place
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.local_parking,
                label: 'Parking',
                value: parking.name,
              ),
              _SummaryRow(
                icon: isPMR ? Icons.accessible : Icons.directions_car,
                label: 'Place',
                value: spotId + (isPMR ? ' ♿' : ''),
                valueColor: isPMR ? AppColors.info : null,
              ),
              _SummaryRow(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: parking.streetAddress,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Créneau
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.play_arrow_outlined,
                label: 'Début',
                value: formatTime(bookingStart),
              ),
              _SummaryRow(
                icon: Icons.stop_outlined,
                label: 'Fin',
                value: formatTime(bookingEnd),
              ),
              _SummaryRow(
                icon: Icons.timer_outlined,
                label: 'Durée',
                value: formatDuration(durationMinutes),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Coût + solde
          _SummaryCard(
            children: [
              _SummaryRow(
                icon: Icons.monetization_on_outlined,
                label: 'Coût',
                value: '$totalCost SPM',
                valueColor: AppColors.primary,
                valueBold: true,
              ),
              _SummaryRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Solde actuel',
                value: '$balance SPM',
              ),
              _SummaryRow(
                icon: Icons.arrow_forward_outlined,
                label: 'Solde après',
                value: '$balanceAfter SPM',
                valueColor:
                    balanceAfter < 0 ? AppColors.error : AppColors.success,
                valueBold: true,
              ),
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
                  const Expanded(
                    child: Text(
                      'Solde insuffisant. Rechargez votre wallet YSP.',
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
