import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';
import 'package:smart_parking/refacto/screens/dashboard/add_vehicle_screen.dart';
import 'package:smart_parking/refacto/screens/parking/parking_map_screen.dart';
import 'package:smart_parking/refacto/widgets/empty_state_card_widget.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../models/booking_model.dart';
import '../../models/parking_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/booking_viewmodel.dart';
import '../../viewmodels/parking_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/connectivity_wrapper.dart';
import '../../widgets/license_plate_widget.dart';
import '../../router/app_router.dart';

class HomeScreenDrawer extends ConsumerStatefulWidget {
  const HomeScreenDrawer({super.key});

  @override
  ConsumerState<HomeScreenDrawer> createState() => _HomeScreenDrawerState();
}

enum _Section { dashboard, profile, wallet, notifications, settings }

class _HomeScreenDrawerState extends ConsumerState<HomeScreenDrawer> {
  _Section _current = _Section.dashboard;

  String _sectionTitle(AppLocalizations l10n) => switch (_current) {
        _Section.dashboard => l10n.dashboardTitle,
        _Section.profile => l10n.dashboardProfile,
        _Section.wallet => l10n.dashboardWallet,
        _Section.notifications => l10n.dashboardNotifications,
        _Section.settings => l10n.dashboardSettings,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userState = ref.watch(userProvider);
    final unread = ref.watch(unreadNotificationsProvider);

    ref.listen(authProvider, (_, next) {
      if (next is AuthUnauthenticated && mounted) {
        AppRouter.pushAndClearStack(context, AppRoutes.login);
      }
    });

    return ConnectivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_sectionTitle(l10n)),
          flexibleSpace: Container(decoration: AppDecorations.gradientAppBar),
          actions: [
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () =>
                      setState(() => _current = _Section.notifications),
                ),
                if (unread > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                          color: AppColors.error, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text('$unread',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center),
                    ),
                  ),
              ],
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                decoration:
                    const BoxDecoration(gradient: AppColors.primaryGradient),
                accountName: userState.isLoading
                    ? const SizedBox(
                        height: 12,
                        width: 100,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ))
                    : Text(userState.user?.fullName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                accountEmail: Text(userState.user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: userState.isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2)
                      : userState.user?.hasProfileImage == true
                          ? ClipOval(
                              child: Image.network(
                              userState.user!.profileImageUrl,
                              width: AppSizes.avatarM,
                              height: AppSizes.avatarM,
                              fit: BoxFit.cover,
                            ))
                          : Text(userState.user?.initials ?? '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              )),
                ),
              ),
              _DrawerItem(
                icon: Icons.dashboard_outlined,
                label: l10n.dashboardTitle,
                selected: _current == _Section.dashboard,
                onTap: () {
                  setState(() => _current = _Section.dashboard);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.person_outline,
                label: l10n.dashboardProfile,
                selected: _current == _Section.profile,
                onTap: () {
                  setState(() => _current = _Section.profile);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.account_balance_wallet_outlined,
                label: l10n.dashboardWallet,
                selected: _current == _Section.wallet,
                onTap: () {
                  setState(() => _current = _Section.wallet);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.notifications_outlined,
                label: l10n.dashboardNotifications,
                selected: _current == _Section.notifications,
                badge: unread,
                onTap: () {
                  setState(() => _current = _Section.notifications);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              _DrawerItem(
                icon: Icons.settings_outlined,
                label: l10n.dashboardSettings,
                selected: _current == _Section.settings,
                onTap: () {
                  setState(() => _current = _Section.settings);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.logout,
                label: l10n.dashboardLogout,
                selected: false,
                color: AppColors.error,
                onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
          ),
        ),
        body: _current == _Section.dashboard
            ? const _DashboardBody()
            : _PlaceholderBody(label: _sectionTitle(l10n)),
      ),
    );
  }
}

// ── Drawer Item ───────────────────────────────────────────────

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Theme.of(context).primaryColor;
    return ListTile(
      leading: Badge(
        isLabelVisible: badge > 0,
        label: Text('$badge'),
        child:
            Icon(icon, color: selected ? itemColor : AppColors.textSecondary),
      ),
      title: Text(label,
          style: TextStyle(
            color: selected ? itemColor : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          )),
      selected: selected,
      selectedTileColor: itemColor.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DASHBOARD BODY — full scroll, no panel
// ─────────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userState = ref.watch(userProvider);
    final parkingState = ref.watch(parkingProvider);
    final bookingState = ref.watch(bookingProvider);

    if (userState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Top 3 parkings les plus réservés
    final favParkings =
        _getTopParkings(parkingState.parkings, bookingState.bookings);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(parkingProvider.notifier).loadParkings();
        final uid = userState.user?.id;
        if (uid != null) {
          await ref.read(bookingProvider.notifier).loadBookings(uid);
          await ref.read(userProvider.notifier).loadUserData(uid);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSizes.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Bienvenue ─────────────────────────────────
            Text(
              '${l10n.dashboardHello}, ${userState.user?.firstName ?? ''} 👋',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spaceXS),
            Text(l10n.dashboardSubtitle,
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSizes.spaceM),

            // ── Wallet ────────────────────────────────────
            _WalletCard(wallet: userState.wallet),
            const SizedBox(height: AppSizes.spaceL),

            // ── Réservation en cours ──────────────────────
            _SectionHeader(
              title: l10n.dashboardOngoingBooking,
              actionLabel: 'Voir la carte',
              onAction: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ParkingMapScreen()),
              ),
            ),
            const SizedBox(height: AppSizes.spaceS),
            if (bookingState.hasOngoing)
              _CountdownCard(
                  booking: bookingState.ongoingBooking!, isOngoing: true)
            else if (bookingState.upcomingBookings.isNotEmpty)
              _CountdownCard(
                  booking: bookingState.upcomingBookings.first,
                  isOngoing: false)
            else
              EmptyStateCard(
                icon: Icons.add_circle_outline,
                title: 'Aucune réservation',
                subtitle: 'Appuyez pour naviguer vers un parking.',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ParkingMapScreen()),
                ),
                backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              ),

            const SizedBox(height: AppSizes.spaceL),

            // ── Véhicule actuel ───────────────────────────
            _SectionHeader(
              title: 'Véhicule actuel',
              actionLabel: userState.hasVehicles ? 'Voir tous' : null,
              onAction: userState.hasVehicles
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddVehicleScreen()),
                      )
                  : null,
            ),
            const SizedBox(height: AppSizes.spaceS),
            if (!userState.hasVehicles)
              EmptyStateCard(
                icon: Icons.directions_car_outlined,
                title: 'Aucun véhicule ajouté',
                subtitle: 'Ajoutez votre véhicule pour réserver.',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
                  );
                },
              )
            else
              SizedBox(
                width: double.infinity,
                child: LicensePlateWidget(
                  vehicle: userState.defaultVehicle!,
                  isSelected: true,
                  compact: true,
                ),
              ),
            const SizedBox(height: AppSizes.spaceL),

            // ── Parkings favoris ──────────────────────────
            _SectionHeader(
              title: 'Mes parkings favoris',
              actionLabel: null,
              onAction: null,
            ),
            const SizedBox(height: AppSizes.spaceS),
            if (favParkings.isEmpty ||
                bookingState.bookings.isEmpty) // Changement ici
              EmptyStateCard(
                icon: Icons.favorite_border,
                title: 'Aucun favori encore',
                subtitle:
                    'Faites des réservations pour voir vos parkings préférés.',
                showChevron: false, // Pas de flèche
                // Pas de onTap
              )
            else
              SizedBox(
                height: 132,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: favParkings.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: AppSizes.spaceM),
                  itemBuilder: (_, i) => SizedBox(
                    width: MediaQuery.of(context).size.width * 0.75,
                    child: _FavParkingCard(
                      parking: favParkings[i],
                      bookings: bookingState.bookings,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: AppSizes.spaceXXL),
          ],
        ),
      ),
    );
  }

  /// Top 3 parkings les plus réservés par l'utilisateur
  List<ParkingModel> _getTopParkings(
      List<ParkingModel> all, List<BookingModel> bookings) {
    if (all.isEmpty) return [];

    // Compter les réservations par parking
    final counts = <String, int>{};
    for (final b in bookings) {
      counts[b.parkingId] = (counts[b.parkingId] ?? 0) + 1;
    }

    // Trier par fréquence
    final sorted = [...all]
      ..sort((a, b) => (counts[b.id] ?? 0).compareTo(counts[a.id] ?? 0));

    return sorted.take(3).toList();
  }
}

// ─────────────────────────────────────────────────────────────
// SECTION HEADER avec action optionnelle
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (actionLabel != null && onAction != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// FAV PARKING CARD — avec vérification disponibilité
// ─────────────────────────────────────────────────────────────

class _FavParkingCard extends ConsumerStatefulWidget {
  final ParkingModel parking;
  final List<BookingModel> bookings;

  const _FavParkingCard({
    required this.parking,
    required this.bookings,
  });

  @override
  ConsumerState<_FavParkingCard> createState() => _FavParkingCardState();
}

class _FavParkingCardState extends ConsumerState<_FavParkingCard> {
  bool _isChecking = false;
  int? _available;
  int? _total;

  Future<void> _checkAvailability() async {
    setState(() => _isChecking = true);
    try {
      await ref.read(parkingProvider.notifier).selectParking(widget.parking);
      final spots = ref.read(parkingProvider).selectedParkingSpots;
      if (mounted) {
        setState(() {
          _available = spots?.availableIds.length ?? 0;
          _total =
              (spots?.regularIds.length ?? 0) + (spots?.specialIds.length ?? 0);
          _isChecking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final count =
        widget.bookings.where((b) => b.parkingId == widget.parking.id).length;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nom + badge
          Row(
            children: [
              Expanded(
                child: Text(widget.parking.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: Text('$count résa',
                    style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(widget.parking.streetAddress,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),

          // Prix + horaires + disponibilité sur la même ligne
          Row(
            children: [
              Text(
                '${widget.parking.feePerSlot} SPM/30min · ${widget.parking.hours}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11),
              ),
              const SizedBox(width: AppSizes.spaceS),
              // Disponibilité sur la même ligne
              if (_available != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _available! > 0
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      color:
                          _available! > 0 ? AppColors.success : AppColors.error,
                      size: 11,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _available! > 0
                          ? '$_available/$_total libres'
                          : 'Complet',
                      style: TextStyle(
                        color: _available! > 0
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceXS),

          // Boutons - taille confortable
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isChecking ? null : _checkAvailability,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.radar_outlined, size: 13),
                  label: Text(
                    _isChecking ? 'Vérification...' : 'Disponibilité',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: AppSizes.spaceXS,
                    ),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 10),
                    side: BorderSide(
                      color:
                          Theme.of(context).primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spaceXS),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ParkingMapScreen()),
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_outlined, size: 13),
                  label: const Text(
                    'Réserver',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: AppSizes.spaceXS,
                    ),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(fontSize: 10),
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
// COUNTDOWN CARD
// ─────────────────────────────────────────────────────────────

class _CountdownCard extends StatefulWidget {
  final BookingModel booking;
  final bool isOngoing;
  const _CountdownCard({required this.booking, required this.isOngoing});

  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard> {
  final CountDownController _controller = CountDownController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seconds = widget.isOngoing
        ? widget.booking.secondsUntilEnd
        : widget.booking.secondsUntilStart;
    final color = widget.isOngoing ? AppColors.success : AppColors.warning;
    final label =
        widget.isOngoing ? l10n.dashboardOngoingBooking : 'Réservation à venir';

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircularCountDownTimer(
            duration: seconds > 0 ? seconds : 1,
            initialDuration: 0,
            controller: _controller,
            width: 80,
            height: 80,
            ringColor: Colors.white.withValues(alpha: 0.3),
            fillColor: Colors.white,
            backgroundColor: Colors.transparent,
            strokeWidth: 6,
            strokeCap: StrokeCap.round,
            textStyle: const TextStyle(
                fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
            textFormat: CountdownTextFormat.HH_MM_SS,
            isReverse: true,
            isReverseAnimation: true,
            autoStart: true,
          ),
          const SizedBox(width: AppSizes.spaceL),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: AppSizes.spaceXS),
                Row(children: [
                  const Icon(Icons.local_parking,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text('${l10n.dashboardSpot}: ${widget.booking.spotId}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.monetization_on,
                      color: Colors.white70, size: 14),
                  const SizedBox(width: 4),
                  Text('${widget.booking.totalCost} SPM',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WALLET CARD
// ─────────────────────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final dynamic wallet;
  const _WalletCard({this.wallet});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.walletYspCoin,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: AppSizes.spaceXS),
          Text('${wallet?.balance ?? 0} SPM',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceXS),
          Row(children: [
            const Icon(Icons.account_balance_wallet,
                color: Colors.white70, size: 16),
            const SizedBox(width: AppSizes.spaceXS),
            Text(l10n.walletPortfolio,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────

class _PlaceholderBody extends StatelessWidget {
  final String label;
  const _PlaceholderBody({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceXL),
        child: Text('$label — à venir',
            style: const TextStyle(color: AppColors.textSecondary)),
      ),
    );
  }
}
