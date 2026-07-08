import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/booking_model.dart';
import '../../models/parking_model.dart';
import '../../services/location_service.dart';
import '../../services/maps_service.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../booking/booking_screen.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/parking_viewmodel.dart';

class ParkingMapScreen extends ConsumerStatefulWidget {
  const ParkingMapScreen({super.key});

  @override
  ConsumerState<ParkingMapScreen> createState() => _ParkingMapScreenState();
}

class _ParkingMapScreenState extends ConsumerState<ParkingMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();

  Position? _userPosition;
  ParkingModel? _selectedParking;
  ParkingSpotsInfo? _selectedSpots;
  bool _isLoadingLocation = false;
  bool _isLoadingSpots = false;
  bool _showMap = true;
  String _searchQuery = '';
  final Map<String, _SpotAvailability> _spotsCache = {};

  static const LatLng _defaultCenter = LatLng(14.6937, -17.4441);

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadAllSpots();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Preload spots ────────────────────────────────────────

  Future<void> _preloadAllSpots() async {
    final parkings = ref.read(parkingProvider).parkings;
    final bookings = ref.read(bookingProvider).unArchivedBookings;
    final fs = ref.read(firestoreServiceProvider);

    final results = await Future.wait(
      parkings.map((p) => fs.getParkingSpots(p.id)),
    );

    if (!mounted) return;
    final cache = <String, _SpotAvailability>{};
    for (var i = 0; i < parkings.length; i++) {
      if (results[i] != null) {
        cache[parkings[i].id] = _computeAvailability(results[i]!, bookings);
      }
    }
    setState(() => _spotsCache.addAll(cache));
  }

  // ── GPS ───────────────────────────────────────────────────

  Future<void> _getUserLocation() async {
    setState(() => _isLoadingLocation = true);
    final position = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() {
        _userPosition = position;
        _isLoadingLocation = false;
      });
      // Only move map if we're in map view and map is ready
      if (position != null && _showMap) {
        try {
          _mapController.move(
              LatLng(position.latitude, position.longitude), 14);
        } catch (_) {
          // MapController not ready yet — ignore
        }
      }
    }
  }

  // ── Distance ──────────────────────────────────────────────

  double _distanceTo(ParkingModel p) {
    if (_userPosition == null) return double.infinity;
    const R = 6371.0;
    final lat1 = _userPosition!.latitude * pi / 180;
    final lat2 = p.latitude * pi / 180;
    final dLat = (p.latitude - _userPosition!.latitude) * pi / 180;
    final dLng = (p.longitude - _userPosition!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  String _formatDistance(double km) {
    if (km == double.infinity) return '--';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  // ── Filtrage + tri ────────────────────────────────────────

  List<ParkingModel> get _filteredParkings {
    final all = ref.read(parkingProvider).parkings;
    var filtered = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = all
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.streetAddress.toLowerCase().contains(q))
          .toList();
    }
    filtered.sort((a, b) => _distanceTo(a).compareTo(_distanceTo(b)));
    return filtered;
  }

  // ── Disponibilité réelle ──────────────────────────────────

  _SpotAvailability _computeAvailability(
      ParkingSpotsInfo? spots, List<BookingModel> bookings) {
    if (spots == null) {
      return const _SpotAvailability(
          normalAvail: 0, normalTotal: 0, pmrAvail: 0, pmrTotal: 0);
    }
    final now = DateTime.now();
    final activeSpots = bookings
        .where((b) => b.bookingStart.isBefore(now) && b.bookingEnd.isAfter(now))
        .map((b) => b.spotId)
        .toSet();

    final normalTotal = spots.regularIds.length;
    final normalOcc = spots.regularIds
        .where((id) =>
            spots.occupiedFromBookingIds.contains(id) ||
            spots.occupiedFromWalkInIds.contains(id) ||
            activeSpots.contains(id))
        .length;

    final pmrTotal = spots.specialIds.length;
    final pmrOcc = spots.specialIds
        .where((id) =>
            spots.occupiedFromBookingIds.contains(id) ||
            spots.occupiedFromWalkInIds.contains(id) ||
            activeSpots.contains(id))
        .length;

    return _SpotAvailability(
      normalAvail: (normalTotal - normalOcc).clamp(0, normalTotal),
      normalTotal: normalTotal,
      pmrAvail: (pmrTotal - pmrOcc).clamp(0, pmrTotal),
      pmrTotal: pmrTotal,
    );
  }

  // ── Sélection parking ─────────────────────────────────────

  Future<void> _selectParking(ParkingModel parking) async {
    setState(() {
      _selectedParking = parking;
      _selectedSpots = null;
      _isLoadingSpots = true;
    });

    if (_showMap) {
      _mapController.move(LatLng(parking.latitude, parking.longitude), 15);
    }

    await ref.read(parkingProvider.notifier).selectParking(parking);
    if (mounted) {
      setState(() {
        _selectedSpots = ref.read(parkingProvider).selectedParkingSpots;
        _isLoadingSpots = false;
      });
    }

    if (mounted) _showParkingSheet(parking);
  }

  // ── Book ─────────────────────────────────────────────────

  void _onBook(ParkingModel parking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(parking: parking),
      ),
    );
  }

  // ── Bottom Sheet ──────────────────────────────────────────

  void _showParkingSheet(ParkingModel parking) {
    final bookings = ref.read(bookingProvider).unArchivedBookings;
    final avail = _computeAvailability(_selectedSpots, bookings);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ParkingBottomSheet(
        parking: parking,
        availability: avail,
        isLoading: _isLoadingSpots,
        onNavigate: () async {
          Navigator.pop(context);
          await MapsService().navigateToParking(
            latitude: parking.latitude,
            longitude: parking.longitude,
            parkingName: parking.name,
          );
        },
        onBook: () => _onBook(parking),
      ),
    ).then((_) {
      if (mounted) {
        setState(() {
          _selectedParking = null;
          _selectedSpots = null;
        });
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredParkings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parkings'),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient)),
        actions: [
          IconButton(
            icon: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.my_location),
            onPressed: _getUserLocation,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Toggle ──────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(AppSizes.spaceM, AppSizes.spaceS,
                AppSizes.spaceM, AppSizes.spaceS),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) {
                        setState(() => _searchQuery = v);
                        if (v.isNotEmpty) {
                          final results = _filteredParkings;
                          if (results.isNotEmpty && _showMap) {
                            _mapController.move(
                              LatLng(results.first.latitude,
                                  results.first.longitude),
                              15,
                            );
                          }
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Nom ou adresse...',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search,
                            size: 18, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                  FocusScope.of(context).unfocus();
                                },
                                child: const Icon(Icons.close,
                                    size: 16, color: AppColors.textSecondary))
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceS),
                // Toggle
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  child: Row(
                    children: [
                      _ToggleBtn(
                        icon: Icons.map_outlined,
                        isSelected: _showMap,
                        onTap: () => setState(() => _showMap = true),
                      ),
                      _ToggleBtn(
                        icon: Icons.list_alt_outlined,
                        isSelected: !_showMap,
                        onTap: () => setState(() => _showMap = false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          if (_searchQuery.isNotEmpty)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.spaceM, 0, AppSizes.spaceM, AppSizes.spaceS),
              child: Text(
                '${filtered.length} parking${filtered.length > 1 ? 's' : ''} trouvé${filtered.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),

          // ── Vue principale ───────────────────────────────
          Expanded(
            child:
                _showMap ? _buildMapView(filtered) : _buildListView(filtered),
          ),
        ],
      ),
    );
  }

  // ── Map View ──────────────────────────────────────────────

  Widget _buildMapView(List<ParkingModel> parkings) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _userPosition != null
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : _defaultCenter,
            initialZoom: 13,
            minZoom: 10,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              retinaMode: true,
              userAgentPackageName: 'com.example.smart_parking',
            ),
            MarkerLayer(markers: [
              // Position utilisateur
              if (_userPosition != null)
                Marker(
                  point:
                      LatLng(_userPosition!.latitude, _userPosition!.longitude),
                  width: 52,
                  height: 52,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            shape: BoxShape.circle),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.3),
                            shape: BoxShape.circle),
                      ),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2)
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Pins parkings
              ...parkings.map((p) => Marker(
                    point: LatLng(p.latitude, p.longitude),
                    width: 80,
                    height: 56,
                    child: GestureDetector(
                      onTap: () => _selectParking(p),
                      child: _ParkingPin(
                        parking: p,
                        isSelected: _selectedParking?.id == p.id,
                      ),
                    ),
                  )),
            ]),
          ],
        ),

        // Légende
        const Positioned(
          bottom: AppSizes.spaceL,
          left: AppSizes.spaceM,
          child: _Legend(),
        ),
      ],
    );
  }

  // ── List View ─────────────────────────────────────────────

  Widget _buildListView(List<ParkingModel> parkings) {
    if (parkings.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            SizedBox(height: AppSizes.spaceM),
            Text('Aucun parking trouvé',
                style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      itemCount: parkings.length,
      itemBuilder: (_, i) {
        final p = parkings[i];
        final isSelected = _selectedParking?.id == p.id;
        final avail = _spotsCache[p.id];
        return _ParkingListCard(
          parking: p,
          distance: _formatDistance(_distanceTo(p)),
          isSelected: isSelected,
          availability: avail,
          onTap: () {
            _selectParking(p);
            setState(() => _showMap = true);
          },
          onBook: () => _onBook(p),
          onNavigate: () async {
            await MapsService().navigateToParking(
              latitude: p.latitude,
              longitude: p.longitude,
              parkingName: p.name,
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOGGLE BUTTON
// ─────────────────────────────────────────────────────────────

class _ToggleBtn extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSizes.radiusFull),
        ),
        child: Icon(icon,
            size: 20,
            color: isSelected ? Colors.white : AppColors.textSecondary),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// PARKING PIN — rouge avec queue triangulaire (original)
// ─────────────────────────────────────────────────────────────

class _ParkingPin extends StatelessWidget {
  final ParkingModel parking;
  final bool isSelected;
  const _ParkingPin({required this.parking, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final pinColor =
        isSelected ? const Color(0xFFFF6B00) : const Color(0xFFE53935);

    // Max 6 chars pour éviter overflow
    final label =
        parking.name.length > 6 ? parking.name.substring(0, 6) : parking.name;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Bulle
        Container(
          constraints: const BoxConstraints(maxWidth: 76),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: pinColor,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: pinColor.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_parking, color: Colors.white, size: 11),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.clip,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Queue triangulaire
        CustomPaint(
          size: const Size(12, 6),
          painter: _PinTail(color: pinColor),
        ),
      ],
    );
  }
}

class _PinTail extends CustomPainter {
  final Color color;
  const _PinTail({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─────────────────────────────────────────────────────────────
// PARKING LIST CARD
// ─────────────────────────────────────────────────────────────

class _ParkingListCard extends StatelessWidget {
  final ParkingModel parking;
  final String distance;
  final bool isSelected;
  final _SpotAvailability? availability;
  final VoidCallback onTap;
  final VoidCallback onNavigate;
  final VoidCallback onBook;

  const _ParkingListCard({
    required this.parking,
    required this.distance,
    required this.isSelected,
    required this.availability,
    required this.onTap,
    required this.onNavigate,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: AppSizes.spaceM),
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nom + distance
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spaceS),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.local_parking,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSizes.spaceS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parking.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(parking.streetAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spaceXS),
              // Distance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.near_me_outlined,
                        size: 10, color: AppColors.textSecondary),
                    const SizedBox(width: 2),
                    Text(distance,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceS),

          // Prix + horaires
          Wrap(
            spacing: AppSizes.spaceS,
            children: [
              _InfoBadge(
                  icon: Icons.monetization_on_outlined,
                  label: '${parking.feePerSlot} SPM/30min'),
              _InfoBadge(
                  icon: Icons.access_time_outlined, label: parking.hours),
            ],
          ),

          // Disponibilité
          if (availability != null) ...[
            const SizedBox(height: AppSizes.spaceS),
            Row(
              children: [
                Expanded(
                  child: _AvailBadge(
                    icon: Icons.directions_car,
                    avail: availability!.normalAvail,
                    total: availability!.normalTotal,
                    label: 'Normales',
                  ),
                ),
                const SizedBox(width: AppSizes.spaceXS),
                Expanded(
                  child: _AvailBadge(
                    icon: Icons.accessible,
                    avail: availability!.pmrAvail,
                    total: availability!.pmrTotal,
                    label: 'PMR',
                  ),
                ),
                const SizedBox(width: AppSizes.spaceXS),
                Expanded(
                  child: _AvailBadge(
                    icon: Icons.local_parking,
                    avail: availability!.normalAvail + availability!.pmrAvail,
                    total: availability!.normalTotal + availability!.pmrTotal,
                    label: 'Total',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSizes.spaceS),

          // Boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 13),
                  label: const Text('Naviguer', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 13),
                  label: const Text('Réserver', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BOTTOM SHEET — design original avec _SpotCounter
// ─────────────────────────────────────────────────────────────

class _ParkingBottomSheet extends StatelessWidget {
  final ParkingModel parking;
  final _SpotAvailability availability;
  final bool isLoading;
  final VoidCallback onNavigate;
  final VoidCallback onBook;

  const _ParkingBottomSheet({
    required this.parking,
    required this.availability,
    required this.isLoading,
    required this.onNavigate,
    required this.onBook,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSizes.spaceM),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Nom + adresse
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.spaceM),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: const Icon(Icons.local_parking,
                    color: AppColors.primary, size: AppSizes.iconL),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(parking.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(parking.streetAddress,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),
          const Divider(),
          const SizedBox(height: AppSizes.spaceS),

          // Infos
          Wrap(
            spacing: AppSizes.spaceS,
            children: [
              _InfoChip(icon: Icons.access_time, label: parking.hours),
              _InfoChip(
                  icon: Icons.monetization_on,
                  label: '${parking.feePerSlot} SPM/30min'),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Disponibilité — SpotCounter original
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  padding: const EdgeInsets.all(AppSizes.spaceM),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SpotCounter(
                        icon: Icons.directions_car,
                        color: AppColors.success,
                        label: 'Normales',
                        count:
                            '${availability.normalAvail}/${availability.normalTotal}',
                      ),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _SpotCounter(
                        icon: Icons.accessible,
                        color: AppColors.info,
                        label: 'PMR',
                        count:
                            '${availability.pmrAvail}/${availability.pmrTotal}',
                      ),
                      Container(width: 1, height: 30, color: AppColors.border),
                      _SpotCounter(
                        icon: Icons.local_parking,
                        color: AppColors.primary,
                        label: 'Disponibles',
                        count:
                            '${availability.normalAvail + availability.pmrAvail}/${availability.normalTotal + availability.pmrTotal}',
                      ),
                    ],
                  ),
                ),
          const SizedBox(height: AppSizes.spaceL),

          // 2 boutons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onNavigate,
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text('Naviguer', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spaceM)),
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onBook,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                  label: const Text('Réserver', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSizes.spaceM)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceS),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SMALL WIDGETS
// ─────────────────────────────────────────────────────────────

class _SpotCounter extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String count;

  const _SpotCounter({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(count,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AvailBadge extends StatelessWidget {
  final IconData icon;
  final int avail;
  final int total;
  final String label;

  const _AvailBadge({
    required this.icon,
    required this.avail,
    required this.total,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final color = avail > 0 ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 2),
              Text('$avail/$total',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          Text(label,
              style:
                  const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spaceM, vertical: AppSizes.spaceXS),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppSizes.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// LÉGENDE
// ─────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceS),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendItem(color: Color(0xFFE53935), label: 'Parking'),
          SizedBox(height: 4),
          _LegendItem(color: Color(0xFFFF6B00), label: 'Sélectionné'),
          SizedBox(height: 4),
          _LegendItem(color: Colors.blue, label: 'Ma position'),
        ],
      ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SPOT AVAILABILITY MODEL
// ─────────────────────────────────────────────────────────────

class _SpotAvailability {
  final int normalAvail;
  final int normalTotal;
  final int pmrAvail;
  final int pmrTotal;

  const _SpotAvailability({
    required this.normalAvail,
    required this.normalTotal,
    required this.pmrAvail,
    required this.pmrTotal,
  });
}
