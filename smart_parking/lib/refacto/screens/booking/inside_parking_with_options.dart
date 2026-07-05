import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/booking_model.dart';
import '../../models/parking_model.dart';
import '../../models/parking_spot_model.dart';
import '../../models/vehicle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/parking_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/license_plate_widget.dart';
import '../../router/app_router.dart';

// ─────────────────────────────────────────────────────────────
// OPTION A — Nouveau design amélioré
// ─────────────────────────────────────────────────────────────

class BookingScreenA extends ConsumerStatefulWidget {
  final ParkingModel parking;
  const BookingScreenA({super.key, required this.parking});

  @override
  ConsumerState<BookingScreenA> createState() => _BookingScreenAState();
}

class _BookingScreenAState extends ConsumerState<BookingScreenA> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedSpotId;
  DateTime _bookingStart = DateTime.now();
  bool _startNow = true;
  int _durationMinutes = 30;
  bool _isConfirming = false;
  VehicleModel? _selectedVehicle;

  final List<int> _durations = [30, 60, 90, 120, 150, 180];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedVehicle = ref.read(userProvider).defaultVehicle;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _selectedSpotId == null) {
      _showSnack('Veuillez sélectionner une place');
      return;
    }
    if (_currentPage == 0 && _selectedVehicle == null) {
      _showSnack('Veuillez sélectionner un véhicule');
      return;
    }
    if (_currentPage < 2) {
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

  DateTime get _bookingEnd =>
      _bookingStart.add(Duration(minutes: _durationMinutes));

  int get _totalCost => (_durationMinutes ~/ 30) * widget.parking.feePerSlot;

  String _formatDuration(int m) {
    if (m < 60) return '${m}min';
    final h = m ~/ 60;
    final min = m % 60;
    return min == 0 ? '${h}h' : '${h}h${min}min';
  }

  String _fmt(DateTime dt) => DateFormat('HH:mm').format(dt);

  Future<void> _confirm() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final wallet = ref.read(userProvider).wallet;
    if ((wallet?.balance ?? 0) < _totalCost) {
      _showSnack('Solde insuffisant.');
      return;
    }
    setState(() => _isConfirming = true);
    try {
      await ref.read(bookingProvider.notifier).createBooking(
            clientId: authState.user.id,
            parkingId: widget.parking.id,
            spotId: _selectedSpotId!,
            vehicleId: _selectedVehicle!.id,
            bookingStart: _bookingStart,
            bookingEnd: _bookingEnd,
            totalCost: _totalCost,
            parkingName: widget.parking.name,
          );
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const _SuccessDialog(),
        );
        if (mounted) AppRouter.pushAndClearStack(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur : $e');
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    _selectedVehicle ??= userState.defaultVehicle;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
          _StepIndicator(currentStep: _currentPage),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                _PageAStep1(
                  parking: widget.parking,
                  selectedSpotId: _selectedSpotId,
                  selectedVehicle: _selectedVehicle,
                  vehicles: userState.vehicles,
                  onSpotSelected: (id) => setState(() => _selectedSpotId = id),
                  onVehicleSelected: (v) =>
                      setState(() => _selectedVehicle = v),
                ),
                _PageAStep2(
                  startNow: _startNow,
                  bookingStart: _bookingStart,
                  durationMinutes: _durationMinutes,
                  durations: _durations,
                  parking: widget.parking,
                  totalCost: _totalCost,
                  bookingEnd: _bookingEnd,
                  formatDuration: _formatDuration,
                  fmt: _fmt,
                  onStartNowChanged: (v) => setState(() {
                    _startNow = v;
                    if (v) _bookingStart = DateTime.now();
                  }),
                  onStartTimeChanged: (dt) =>
                      setState(() => _bookingStart = dt),
                  onDurationChanged: (d) =>
                      setState(() => _durationMinutes = d),
                ),
                _PageAStep3(
                  parking: widget.parking,
                  spotId: _selectedSpotId ?? '',
                  vehicle: _selectedVehicle,
                  bookingStart: _bookingStart,
                  bookingEnd: _bookingEnd,
                  totalCost: _totalCost,
                  durationMinutes: _durationMinutes,
                  fmt: _fmt,
                  formatDuration: _formatDuration,
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spaceM),
              child: _isConfirming
                  ? Center(
                      child: SpinKitFadingCircle(
                          size: 40, color: Theme.of(context).primaryColor))
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

// ── Step 1A — Places + Véhicule ───────────────────────────────

class _PageAStep1 extends ConsumerWidget {
  final ParkingModel parking;
  final String? selectedSpotId;
  final VehicleModel? selectedVehicle;
  final List<VehicleModel> vehicles;
  final void Function(String) onSpotSelected;
  final void Function(VehicleModel) onVehicleSelected;

  const _PageAStep1({
    required this.parking,
    required this.selectedSpotId,
    required this.selectedVehicle,
    required this.vehicles,
    required this.onSpotSelected,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spots = ref.watch(parkingProvider).selectedParkingSpots;
    final userState = ref.watch(userProvider);
    final isPMR = userState.user?.isSpecialAccessUser ?? false;

    if (spots == null) return const Center(child: CircularProgressIndicator());

    final aisleA = spots.allIds.where((id) => id.startsWith('A')).toList()
      ..sort();
    final aisleB = spots.allIds.where((id) => id.startsWith('B')).toList()
      ..sort();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info parking
          _InfoBanner(parking: parking),
          const SizedBox(height: AppSizes.spaceL),

          // Grille places
          const Text('Sélectionnez une place',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),
          _SpotLegend(),
          const SizedBox(height: AppSizes.spaceM),

          // Grille style parking physique — 2 colonnes + allée
          _ParkingLayout(
            aisleA: aisleA,
            aisleB: aisleB,
            spots: spots,
            selectedSpotId: selectedSpotId,
            isPMR: isPMR,
            onSpotSelected: onSpotSelected,
          ),

          if (selectedSpotId != null) ...[
            const SizedBox(height: AppSizes.spaceM),
            _SelectedBadge(spotId: selectedSpotId!),
          ],

          const SizedBox(height: AppSizes.spaceL),

          // Sélection véhicule
          const Text('Véhicule',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),
          if (vehicles.isEmpty)
            const Text('Aucun véhicule — ajoutez-en un depuis votre profil',
                style: TextStyle(color: AppColors.textSecondary))
          else
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vehicles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSizes.spaceS),
                itemBuilder: (_, i) {
                  final v = vehicles[i];
                  final isSel = selectedVehicle?.id == v.id;
                  return GestureDetector(
                    onTap: () => onVehicleSelected(v),
                    child: SizedBox(
                      width: 240,
                      child: LicensePlateWidget(
                          vehicle: v, isDefault: isSel, compact: true),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

// ── Step 2A — Créneau ─────────────────────────────────────────

class _PageAStep2 extends ConsumerWidget {
  final bool startNow;
  final DateTime bookingStart;
  final int durationMinutes;
  final List<int> durations;
  final ParkingModel parking;
  final int totalCost;
  final DateTime bookingEnd;
  final String Function(int) formatDuration;
  final String Function(DateTime) fmt;
  final void Function(bool) onStartNowChanged;
  final void Function(DateTime) onStartTimeChanged;
  final void Function(int) onDurationChanged;

  const _PageAStep2({
    required this.startNow,
    required this.bookingStart,
    required this.durationMinutes,
    required this.durations,
    required this.parking,
    required this.totalCost,
    required this.bookingEnd,
    required this.formatDuration,
    required this.fmt,
    required this.onStartNowChanged,
    required this.onStartTimeChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(userProvider).wallet?.balance ?? 0;
    final sufficient = balance >= totalCost;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choisissez votre créneau',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceL),

          // Début
          const Text('Heure de début',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),
          Row(children: [
            Expanded(
                child: _ToggleTimeBtn(
              label: 'Maintenant',
              isSelected: startNow,
              onTap: () => onStartNowChanged(true),
            )),
            const SizedBox(width: AppSizes.spaceM),
            Expanded(
                child: _ToggleTimeBtn(
              label: !startNow ? fmt(bookingStart) : 'Choisir',
              isSelected: !startNow,
              onTap: () async {
                final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(bookingStart));
                if (picked != null) {
                  final now = DateTime.now();
                  onStartTimeChanged(DateTime(now.year, now.month, now.day,
                      picked.hour, picked.minute));
                  onStartNowChanged(false);
                }
              },
            )),
          ]),
          const SizedBox(height: AppSizes.spaceL),

          // Durée — grille 3×N
          const Text('Durée', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSizes.spaceS,
            crossAxisSpacing: AppSizes.spaceS,
            childAspectRatio: 2.5,
            children: durations.map((d) {
              final isSel = durationMinutes == d;
              return GestureDetector(
                onTap: () => onDurationChanged(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.border),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Center(
                    child: Text(formatDuration(d),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSel
                                ? Colors.white
                                : AppColors.textSecondary)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Résumé
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)
              ],
            ),
            child: Column(children: [
              _SummaryRow(
                  icon: Icons.play_arrow_outlined,
                  label: 'Début',
                  value: fmt(bookingStart)),
              const Divider(height: AppSizes.spaceL),
              _SummaryRow(
                  icon: Icons.stop_outlined,
                  label: 'Fin',
                  value: fmt(bookingEnd)),
              const Divider(height: AppSizes.spaceL),
              _SummaryRow(
                  icon: Icons.monetization_on_outlined,
                  label: 'Coût total',
                  value: '$totalCost SPM',
                  valueColor: AppColors.primary,
                  valueBold: true),
              const Divider(height: AppSizes.spaceL),
              _SummaryRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Votre solde',
                  value: '$balance SPM',
                  valueColor: sufficient ? AppColors.success : AppColors.error,
                  valueBold: true),
              if (!sufficient) ...[
                const SizedBox(height: AppSizes.spaceXS),
                const Row(children: [
                  Icon(Icons.warning_amber_outlined,
                      color: AppColors.error, size: 14),
                  SizedBox(width: 4),
                  Text('Solde insuffisant',
                      style: TextStyle(color: AppColors.error, fontSize: 12)),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

// ── Step 3A — Récapitulatif ───────────────────────────────────

class _PageAStep3 extends ConsumerWidget {
  final ParkingModel parking;
  final String spotId;
  final VehicleModel? vehicle;
  final DateTime bookingStart;
  final DateTime bookingEnd;
  final int totalCost;
  final int durationMinutes;
  final String Function(DateTime) fmt;
  final String Function(int) formatDuration;

  const _PageAStep3({
    required this.parking,
    required this.spotId,
    required this.vehicle,
    required this.bookingStart,
    required this.bookingEnd,
    required this.totalCost,
    required this.durationMinutes,
    required this.fmt,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(userProvider).wallet?.balance ?? 0;
    final balanceAfter = balance - totalCost;
    final isPMR = spotId == 'B4' || spotId == 'B5';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Récapitulatif',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceL),
          if (vehicle != null) ...[
            const Text('Véhicule',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    fontSize: 12)),
            const SizedBox(height: AppSizes.spaceS),
            LicensePlateWidget(
                vehicle: vehicle!, isDefault: true, compact: true),
            const SizedBox(height: AppSizes.spaceL),
          ],
          _SummaryCard(children: [
            _SummaryRow(
                icon: Icons.local_parking,
                label: 'Parking',
                value: parking.name),
            _SummaryRow(
                icon: isPMR ? Icons.accessible : Icons.directions_car,
                label: 'Place',
                value: spotId + (isPMR ? ' ♿' : '')),
            _SummaryRow(
                icon: Icons.location_on_outlined,
                label: 'Adresse',
                value: parking.streetAddress),
          ]),
          const SizedBox(height: AppSizes.spaceM),
          _SummaryCard(children: [
            _SummaryRow(
                icon: Icons.play_arrow_outlined,
                label: 'Début',
                value: fmt(bookingStart)),
            _SummaryRow(
                icon: Icons.stop_outlined,
                label: 'Fin',
                value: fmt(bookingEnd)),
            _SummaryRow(
                icon: Icons.timer_outlined,
                label: 'Durée',
                value: formatDuration(durationMinutes)),
          ]),
          const SizedBox(height: AppSizes.spaceM),
          _SummaryCard(children: [
            _SummaryRow(
                icon: Icons.monetization_on_outlined,
                label: 'Coût',
                value: '$totalCost SPM',
                valueColor: AppColors.primary,
                valueBold: true),
            _SummaryRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Solde actuel',
                value: '$balance SPM'),
            _SummaryRow(
                icon: Icons.arrow_forward_outlined,
                label: 'Solde après',
                value: '$balanceAfter SPM',
                valueColor:
                    balanceAfter < 0 ? AppColors.error : AppColors.success,
                valueBold: true),
          ]),
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
              child: const Row(children: [
                Icon(Icons.warning_amber_outlined,
                    color: AppColors.error, size: 20),
                SizedBox(width: AppSizes.spaceS),
                Expanded(
                    child: Text(
                        'Solde insuffisant. Rechargez votre wallet YSP.',
                        style:
                            TextStyle(color: AppColors.error, fontSize: 13))),
              ]),
            ),
          ],
          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// OPTION B — Fidèle à l'ancien
// ─────────────────────────────────────────────────────────────

class BookingScreenB extends ConsumerStatefulWidget {
  final ParkingModel parking;
  const BookingScreenB({super.key, required this.parking});

  @override
  ConsumerState<BookingScreenB> createState() => _BookingScreenBState();
}

class _BookingScreenBState extends ConsumerState<BookingScreenB> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String? _selectedSpotId;
  String? _selectedTimeSlot; // "HH:mm - HH:mm"
  VehicleModel? _selectedVehicle;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedVehicle = ref.read(userProvider).defaultVehicle;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0 && _selectedVehicle == null) {
      _showSnack('Sélectionnez un véhicule');
      return;
    }
    if (_currentPage == 1 && _selectedSpotId == null) {
      _showSnack('Sélectionnez une place');
      return;
    }
    if (_currentPage == 1 && _selectedTimeSlot == null) {
      _showSnack('Sélectionnez un créneau');
      return;
    }
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  // Parse le time slot "08:05 - 08:35"
  DateTime _parseStart(String slot) {
    final parts = slot.split(' - ');
    final t = parts[0].split(':');
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, int.parse(t[0]), int.parse(t[1]));
  }

  DateTime _parseEnd(String slot) {
    final parts = slot.split(' - ');
    final t = parts[1].split(':');
    final now = DateTime.now();
    return DateTime(
        now.year, now.month, now.day, int.parse(t[0]), int.parse(t[1]));
  }

  int get _durationMinutes {
    if (_selectedTimeSlot == null) return 0;
    final start = _parseStart(_selectedTimeSlot!);
    final end = _parseEnd(_selectedTimeSlot!);
    return end.difference(start).inMinutes;
  }

  int get _totalCost => (_durationMinutes ~/ 30) * widget.parking.feePerSlot;

  List<String> _generateSlots() {
    final slots = <String>[];
    final parts = widget.parking.openingHour.split(':');
    var current =
        DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    final closeParts = widget.parking.closingHour.split(':');
    final close = DateTime(
        2000, 1, 1, int.parse(closeParts[0]), int.parse(closeParts[1]));

    while (current.isBefore(close)) {
      final end = current.add(const Duration(minutes: 35));
      if (end.isAfter(close)) break;
      slots.add(
          '${DateFormat('HH:mm').format(current)} - ${DateFormat('HH:mm').format(end)}');
      current = current.add(const Duration(minutes: 35));
    }
    return slots;
  }

  Future<void> _confirm() async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final wallet = ref.read(userProvider).wallet;
    if ((wallet?.balance ?? 0) < _totalCost) {
      _showSnack('Solde insuffisant.');
      return;
    }
    setState(() => _isConfirming = true);
    try {
      await ref.read(bookingProvider.notifier).createBooking(
            clientId: authState.user.id,
            parkingId: widget.parking.id,
            spotId: _selectedSpotId!,
            vehicleId: _selectedVehicle!.id,
            bookingStart: _parseStart(_selectedTimeSlot!),
            bookingEnd: _parseEnd(_selectedTimeSlot!),
            totalCost: _totalCost,
            parkingName: widget.parking.name,
          );
      if (mounted) {
        await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const _SuccessDialog());
        if (mounted) AppRouter.pushAndClearStack(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur : $e');
        setState(() => _isConfirming = false);
      }
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    _selectedVehicle ??= userState.defaultVehicle;
    final slots = _generateSlots();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _OldStyleStepper(currentStep: _currentPage),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentPage = i),
              children: [
                // Page 1 — Parking details + Date + Vehicle (comme ancien)
                _PageBStep1(
                  parking: widget.parking,
                  vehicles: userState.vehicles,
                  selectedVehicle: _selectedVehicle,
                  onVehicleSelected: (v) =>
                      setState(() => _selectedVehicle = v),
                ),
                // Page 2 — Grille places + Time slots (comme ancien)
                _PageBStep2(
                  parking: widget.parking,
                  selectedSpotId: _selectedSpotId,
                  selectedTimeSlot: _selectedTimeSlot,
                  slots: slots,
                  isPMR: userState.user?.isSpecialAccessUser ?? false,
                  onSpotSelected: (id) => setState(() => _selectedSpotId = id),
                  onSlotSelected: (s) => setState(() => _selectedTimeSlot = s),
                ),
                // Page 3 — Booking overview (comme ancien)
                _PageBStep3(
                  parking: widget.parking,
                  spotId: _selectedSpotId ?? '',
                  vehicle: _selectedVehicle,
                  timeSlot: _selectedTimeSlot ?? '',
                  totalCost: _totalCost,
                  durationMinutes: _durationMinutes,
                ),
              ],
            ),
          ),
          // Bottom bar style ancien
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceM, vertical: AppSizes.spaceS),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                      Text('$_totalCost SPM',
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 22)),
                    ],
                  ),
                ),
                Expanded(
                  child: _isConfirming
                      ? Center(
                          child: SpinKitFadingCircle(
                              size: 32, color: Theme.of(context).primaryColor))
                      : ElevatedButton(
                          onPressed: _currentPage == 2 ? _confirm : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8A000),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusM)),
                          ),
                          child: Text(
                            _currentPage == 2 ? 'BOOK NOW' : 'NEXT',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white),
                          ),
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

// ── Old Style Stepper ─────────────────────────────────────────

class _OldStyleStepper extends StatelessWidget {
  final int currentStep;
  const _OldStyleStepper({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceL, vertical: AppSizes.spaceS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _OldBtn(label: 'Prev.', onTap: null),
          const SizedBox(width: AppSizes.spaceM),
          ...List.generate(
              3,
              (i) => Row(
                    children: [
                      _OldStepCircle(step: i, currentStep: currentStep),
                      if (i < 2)
                        Container(
                            width: 20,
                            height: 2,
                            color: i < currentStep
                                ? Colors.white
                                : Colors.white30),
                    ],
                  )),
          const SizedBox(width: AppSizes.spaceM),
          _OldBtn(label: 'Next', onTap: null),
        ],
      ),
    );
  }
}

class _OldStepCircle extends StatelessWidget {
  final int step, currentStep;
  const _OldStepCircle({required this.step, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final isActive = step == currentStep;
    final isDone = step < currentStep;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white54, width: 1.5),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, color: Colors.green, size: 16)
            : Text('${step + 1}',
                style: TextStyle(
                    color: isActive ? AppColors.primary : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
      ),
    );
  }
}

class _OldBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _OldBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Text(label,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }
}

// ── Page B Step 1 — Parking Details + Date + Vehicle ──────────

class _PageBStep1 extends StatelessWidget {
  final ParkingModel parking;
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;
  final void Function(VehicleModel) onVehicleSelected;

  const _PageBStep1({
    required this.parking,
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parking Details — cards scrollables horizontalement
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child:
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSizes.spaceS),
            const Text('Parking Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: AppSizes.spaceM),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _DetailCard(
                    title: 'Fee/30mns', value: '${parking.feePerSlot} SPM'),
                _DetailCard(title: 'Opening Hour', value: parking.openingHour),
                _DetailCard(title: 'Closing Hour', value: parking.closingHour),
                _DetailCard(title: 'Address', value: parking.streetAddress),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Select A Date — calendrier simple (semaine)
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.calendar_month,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSizes.spaceS),
            const Text('Select A Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: AppSizes.spaceM),
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.chevron_left),
                  Text(DateFormat('MMMM yyyy', 'fr').format(now),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: const Text('Month', style: TextStyle(fontSize: 12)),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppSizes.spaceM),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                    .map((d) => Text(d,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)))
                    .toList(),
              ),
              const SizedBox(height: AppSizes.spaceS),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(7, (i) {
                  final day = now.subtract(Duration(days: now.weekday - 1 - i));
                  final isToday = day.day == now.day;
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isToday ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${day.day}',
                          style: TextStyle(
                              color: isToday ? Colors.white : null,
                              fontWeight: isToday ? FontWeight.bold : null)),
                    ),
                  );
                }),
              ),
            ]),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Select A Vehicle
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color:
                      vehicles.isEmpty ? AppColors.border : AppColors.primary,
                  shape: BoxShape.circle),
              child: Icon(vehicles.isEmpty ? Icons.check : Icons.check,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: AppSizes.spaceS),
            const Text('Select A Vehicule',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: AppSizes.spaceM),
          if (vehicles.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppSizes.spaceXL),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 48, color: AppColors.textSecondary),
                  SizedBox(height: AppSizes.spaceS),
                  Icon(Icons.add_circle_outline,
                      size: 32, color: AppColors.primary),
                ],
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: vehicles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppSizes.spaceS),
                itemBuilder: (_, i) {
                  final v = vehicles[i];
                  final isSel = selectedVehicle?.id == v.id;
                  return GestureDetector(
                    onTap: () => onVehicleSelected(v),
                    child: Container(
                      width: 260,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusM),
                        border: Border.all(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          width: isSel ? 2 : 0,
                        ),
                      ),
                      child: LicensePlateWidget(
                          vehicle: v, isDefault: isSel, compact: true),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final String title, value;
  const _DetailCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: AppSizes.spaceS),
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

// ── Page B Step 2 — Grille + Time Slots ──────────────────────

class _PageBStep2 extends ConsumerWidget {
  final ParkingModel parking;
  final String? selectedSpotId;
  final String? selectedTimeSlot;
  final List<String> slots;
  final bool isPMR;
  final void Function(String) onSpotSelected;
  final void Function(String) onSlotSelected;

  const _PageBStep2({
    required this.parking,
    required this.selectedSpotId,
    required this.selectedTimeSlot,
    required this.slots,
    required this.isPMR,
    required this.onSpotSelected,
    required this.onSlotSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spots = ref.watch(parkingProvider).selectedParkingSpots;
    if (spots == null) return const Center(child: CircularProgressIndicator());

    final aisleA = spots.allIds.where((id) => id.startsWith('A')).toList()
      ..sort();
    final aisleB = spots.allIds.where((id) => id.startsWith('B')).toList()
      ..sort();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select A Spot header
          Padding(
            padding: const EdgeInsets.all(AppSizes.spaceM),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Center(
                    child: Text('P',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceS),
                const Text('Select A Spot',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                // Légende compacte
                _CompactLegend(),
              ],
            ),
          ),

          // Grille parking style physique
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF0F5),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                // Allée A (gauche)
                Expanded(
                  child: Column(
                    children: aisleA.map((id) {
                      return _OldSpotTile(
                        spotId: id,
                        spots: spots,
                        isSelected: selectedSpotId == id,
                        isPMR: isPMR,
                        onTap: () => onSpotSelected(id),
                      );
                    }).toList(),
                  ),
                ),
                // Allée centrale
                Container(
                  width: 50,
                  color: Colors.white.withValues(alpha: 0.6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.arrow_circle_down_outlined,
                          color: AppColors.textSecondary),
                      const SizedBox(height: 8),
                      const Icon(Icons.arrow_circle_down_outlined,
                          color: AppColors.textSecondary),
                    ],
                  ),
                ),
                // Allée B (droite)
                Expanded(
                  child: Column(
                    children: aisleB.map((id) {
                      return _OldSpotTile(
                        spotId: id,
                        spots: spots,
                        isSelected: selectedSpotId == id,
                        isPMR: isPMR,
                        onTap: () => onSpotSelected(id),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.spaceL),

          // Select A Time Slot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade600, shape: BoxShape.circle),
                  child: const Icon(Icons.access_time,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: AppSizes.spaceS),
                const Text('Select A Time Slot',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                _TimeSlotLegend(),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Grille time slots 3×N
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSizes.spaceS,
              crossAxisSpacing: AppSizes.spaceS,
              childAspectRatio: 2.0,
              children: slots.map((slot) {
                final isSel = selectedTimeSlot == slot;
                return GestureDetector(
                  onTap: () => onSlotSelected(slot),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
                    ),
                    child: Center(
                      child: Text(slot,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight:
                                  isSel ? FontWeight.bold : FontWeight.normal)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

class _OldSpotTile extends StatelessWidget {
  final String spotId;
  final ParkingSpotsInfo spots;
  final bool isSelected, isPMR;
  final VoidCallback onTap;

  const _OldSpotTile({
    required this.spotId,
    required this.spots,
    required this.isSelected,
    required this.isPMR,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSpecial = spots.specialIds.contains(spotId);
    final isOccupied = spots.occupiedFromBookingIds.contains(spotId) ||
        spots.occupiedFromWalkInIds.contains(spotId);
    final isBooked = spots.bookedIds.contains(spotId);
    final canBook = !isOccupied && !isBooked && (!isSpecial || isPMR);

    Color iconColor = AppColors.success;
    if (isOccupied)
      iconColor = AppColors.error;
    else if (isBooked)
      iconColor = AppColors.warning;
    else if (isSpecial) iconColor = AppColors.info;

    return GestureDetector(
      onTap: canBook ? onTap : null,
      child: Container(
        height: 70,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : const Color(0xFFB0BEC5).withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppSizes.radiusS),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSpecial)
                  Icon(Icons.accessible, color: iconColor, size: 14),
                Icon(Icons.lock_open_outlined, color: iconColor, size: 14),
              ],
            ),
            const SizedBox(height: 4),
            Text(spotId,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.black87)),
          ],
        ),
      ),
    );
  }
}

class _CompactLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusS),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegRow(
              icon: Icons.lock_open_outlined,
              color: AppColors.success,
              label: 'Available'),
          _LegRow(
              icon: Icons.lock_outlined,
              color: AppColors.warning,
              label: 'Booked'),
          _LegRow(
              icon: Icons.directions_car,
              color: AppColors.error,
              label: 'Occupied'),
          _LegRow(
              icon: Icons.accessible, color: AppColors.info, label: 'Special'),
        ],
      ),
    );
  }
}

class _TimeSlotLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegDot(color: AppColors.success, label: 'Available'),
        const SizedBox(width: AppSizes.spaceS),
        _LegDot(color: AppColors.warning, label: 'Booked'),
        const SizedBox(width: AppSizes.spaceS),
        _LegDot(color: AppColors.error, label: 'Occupied'),
      ],
    );
  }
}

class _LegDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 2),
      Text(label,
          style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
    ]);
  }
}

class _LegRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _LegRow({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 9)),
      ]),
    );
  }
}

// ── Page B Step 3 — Booking Overview ─────────────────────────

class _PageBStep3 extends ConsumerWidget {
  final ParkingModel parking;
  final String spotId, timeSlot;
  final VehicleModel? vehicle;
  final int totalCost, durationMinutes;

  const _PageBStep3({
    required this.parking,
    required this.spotId,
    required this.vehicle,
    required this.timeSlot,
    required this.totalCost,
    required this.durationMinutes,
  });

  String _durationStr(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return h == 0 ? '${m}mn' : (min == 0 ? '${h}h' : '${h}h ${min}mn');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(userProvider).wallet?.balance ?? 0;
    final balanceAfter = balance - totalCost;
    final parts = timeSlot.isNotEmpty ? timeSlot.split(' - ') : ['--', '--'];
    final now = DateFormat('EEEE,\nd/M/y').format(DateTime.now());

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header avec image voiture
          Container(
            height: 280,
            width: double.infinity,
            color: const Color(0xFF546E7A),
            padding: const EdgeInsets.all(AppSizes.spaceL),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BOOKING OVERVIEW',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 22)),
                if (vehicle != null) ...[
                  Text(vehicle!.brand,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                  Text(vehicle!.modelDetail,
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 14)),
                ],
                // Image voiture
                Expanded(
                  child: Center(
                    child: vehicle != null
                        ? Image.asset(
                            'assets/images/carRep/${vehicle!.brand.toLowerCase()}.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.directions_car,
                                size: 80,
                                color: Colors.white54),
                          )
                        : const Icon(Icons.directions_car,
                            size: 80, color: Colors.white54),
                  ),
                ),
                Row(children: [
                  const Icon(Icons.location_pin, color: Colors.white),
                  Text(parking.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)),
                ]),
                const Text('Booking Details',
                    style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),

          // Grid de cards style ancien
          Padding(
            padding: const EdgeInsets.all(AppSizes.spaceM),
            child: Column(children: [
              Row(children: [
                Expanded(
                    child: _OldDetailCard(title: 'Booked Day', value: now)),
                const SizedBox(width: AppSizes.spaceS),
                Expanded(
                    child: _OldDetailCard(title: 'Booked Spot', value: spotId)),
                const SizedBox(width: AppSizes.spaceS),
                Expanded(
                    child: _OldDetailCard(
                        title: 'Fee / 30mns',
                        value: '${parking.feePerSlot} SPM')),
              ]),
              const SizedBox(height: AppSizes.spaceS),
              Row(children: [
                Expanded(
                    child: _OldDetailCard(
                        title: 'Booking Start', value: parts[0])),
                const SizedBox(width: AppSizes.spaceS),
                Expanded(
                    child:
                        _OldDetailCard(title: 'Booking End', value: parts[1])),
                const SizedBox(width: AppSizes.spaceS),
                Expanded(
                    child: _OldDetailCard(
                        title: 'Duration',
                        value: _durationStr(durationMinutes))),
              ]),
              if (balanceAfter < 0) ...[
                const SizedBox(height: AppSizes.spaceM),
                Container(
                  padding: const EdgeInsets.all(AppSizes.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: const Row(children: [
                    Icon(Icons.warning_amber_outlined,
                        color: AppColors.error, size: 16),
                    SizedBox(width: AppSizes.spaceS),
                    Expanded(
                        child: Text(
                            'Solde insuffisant. Rechargez votre wallet.',
                            style: TextStyle(
                                color: AppColors.error, fontSize: 12))),
                  ]),
                ),
              ],
            ]),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _OldDetailCard extends StatelessWidget {
  final String title, value;
  const _OldDetailCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: const Color(0xFF78909C),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceS),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Place', 'Créneau', 'Récapitulatif'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
          vertical: AppSizes.spaceM, horizontal: AppSizes.spaceL),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                  height: 2,
                  color: i ~/ 2 < currentStep
                      ? AppColors.primary
                      : AppColors.border),
            );
          }
          final step = i ~/ 2;
          final isActive = step == currentStep;
          final isDone = step < currentStep;
          return Column(children: [
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
                    width: 2),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : Text('${step + 1}',
                        style: TextStyle(
                            color: isActive
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[step],
                style: TextStyle(
                    fontSize: 10,
                    color:
                        isActive ? AppColors.primary : AppColors.textSecondary,
                    fontWeight:
                        isActive ? FontWeight.bold : FontWeight.normal)),
          ]);
        }),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final ParkingModel parking;
  const _InfoBanner({required this.parking});

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
                    fontSize: 13, color: AppColors.textSecondary))),
        Text('${parking.feePerSlot} SPM/30min',
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _ParkingLayout extends StatelessWidget {
  final List<String> aisleA, aisleB;
  final ParkingSpotsInfo spots;
  final String? selectedSpotId;
  final bool isPMR;
  final void Function(String) onSpotSelected;

  const _ParkingLayout({
    required this.aisleA,
    required this.aisleB,
    required this.spots,
    required this.selectedSpotId,
    required this.isPMR,
    required this.onSpotSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Allée A
        Expanded(
          child: Column(children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text('A',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
            ),
            ...aisleA.map((id) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spaceXS),
                  child: _SpotCard(
                    spotId: id,
                    spots: spots,
                    isPMR: isPMR,
                    isSelected: selectedSpotId == id,
                    onTap: () => onSpotSelected(id),
                  ),
                )),
          ]),
        ),
        // Allée centrale
        Container(
          width: 40,
          margin: const EdgeInsets.symmetric(horizontal: AppSizes.spaceXS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.arrow_circle_down_outlined,
                  color: AppColors.textSecondary, size: 20),
              Container(height: 80, width: 2, color: AppColors.border),
              const Icon(Icons.arrow_circle_down_outlined,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
        // Allée B
        Expanded(
          child: Column(children: [
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: const Text('B',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
            ),
            ...aisleB.map((id) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.spaceXS),
                  child: _SpotCard(
                    spotId: id,
                    spots: spots,
                    isPMR: isPMR,
                    isSelected: selectedSpotId == id,
                    onTap: () => onSpotSelected(id),
                  ),
                )),
          ]),
        ),
      ],
    );
  }
}

class _SpotCard extends StatelessWidget {
  final String spotId;
  final ParkingSpotsInfo spots;
  final bool isPMR, isSelected;
  final VoidCallback onTap;

  const _SpotCard({
    required this.spotId,
    required this.spots,
    required this.isPMR,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSpecial = spots.specialIds.contains(spotId);
    final isOccupied = spots.occupiedFromBookingIds.contains(spotId) ||
        spots.occupiedFromWalkInIds.contains(spotId);
    final isBooked = spots.bookedIds.contains(spotId);
    final canBook = !isOccupied && !isBooked && (!isSpecial || isPMR);

    Color bg, border, textColor;
    if (isSelected) {
      bg = AppColors.primary;
      border = AppColors.primary;
      textColor = Colors.white;
    } else if (isOccupied) {
      bg = AppColors.error.withValues(alpha: 0.15);
      border = AppColors.error;
      textColor = AppColors.error;
    } else if (isBooked) {
      bg = AppColors.warning.withValues(alpha: 0.15);
      border = AppColors.warning;
      textColor = AppColors.warning;
    } else if (isSpecial) {
      bg = AppColors.info.withValues(alpha: 0.15);
      border = AppColors.info;
      textColor = AppColors.info;
    } else {
      bg = AppColors.success.withValues(alpha: 0.15);
      border = AppColors.success;
      textColor = AppColors.success;
    }

    return GestureDetector(
      onTap: canBook ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppSizes.spotCardHeight,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(color: border, width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (isSpecial)
            Icon(Icons.accessible, color: textColor, size: AppSizes.spotLedSize)
          else
            Icon(Icons.directions_car,
                color: textColor, size: AppSizes.spotLedSize),
          const SizedBox(height: 4),
          Text(spotId,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: textColor)),
          if (isOccupied)
            Text('Occupée', style: TextStyle(fontSize: 8, color: textColor))
          else if (isBooked)
            Text('Réservée', style: TextStyle(fontSize: 8, color: textColor)),
        ]),
      ),
    );
  }
}

class _SpotLegend extends StatelessWidget {
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
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: color))),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _SelectedBadge extends StatelessWidget {
  final String spotId;
  const _SelectedBadge({required this.spotId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.success, size: 20),
        const SizedBox(width: AppSizes.spaceS),
        Text('Place $spotId sélectionnée',
            style: const TextStyle(
                color: AppColors.success, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}

class _ToggleTimeBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleTimeBtn(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceM),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border),
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textSecondary)),
        ),
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
              offset: const Offset(0, 2))
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
  final String label, value;
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
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: AppSizes.spaceS),
      Text(label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13)),
    ]);
  }
}

// ── Success Dialog ────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceXL),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 60),
          const SizedBox(height: AppSizes.spaceM),
          const Text('Réservation confirmée !',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.spaceS),
          const Text('Redirection vers votre dashboard...',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center),
          const SizedBox(height: AppSizes.spaceL),
          const CircularProgressIndicator(),
        ]),
      ),
    );
  }
}
