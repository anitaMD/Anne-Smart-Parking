import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';
import 'package:smart_parking/refacto/models/vehicle_model.dart';
import 'package:smart_parking/refacto/models/wallet_model.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/connectivity_wrapper.dart';
import '../../router/app_router.dart';

/// Version 1 — Dashboard avec Drawer (menu latéral)
class HomeScreenDrawer extends ConsumerStatefulWidget {
  const HomeScreenDrawer({super.key});

  @override
  ConsumerState<HomeScreenDrawer> createState() => _HomeScreenDrawerState();
}

enum _Section { dashboard, profile, wallet, notifications, settings }

class _HomeScreenDrawerState extends ConsumerState<HomeScreenDrawer> {
  _Section _current = _Section.dashboard;

  String _sectionTitle(AppLocalizations l10n) {
    return switch (_current) {
      _Section.dashboard => 'Dashboard',
      _Section.profile => 'Profil',
      _Section.wallet => 'Wallet YSP',
      _Section.notifications => 'Notifications',
      _Section.settings => 'Paramètres',
    };
  }

  Widget _sectionBody() {
    return switch (_current) {
      _Section.dashboard => const _DashboardBody(),
      _Section.profile => const _PlaceholderBody(label: 'Profil'),
      _Section.wallet => const _PlaceholderBody(label: 'Wallet'),
      _Section.notifications => const _PlaceholderBody(label: 'Notifications'),
      _Section.settings => const _PlaceholderBody(label: 'Paramètres'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userState = ref.watch(userProvider);
    final unread = ref.watch(unreadNotificationsProvider);

    // Naviguer vers login si déconnecté
    ref.listen(authProvider, (_, next) {
      if (next is AuthUnauthenticated && mounted) {
        AppRouter.pushAndClearStack(context, AppRoutes.login);
      }
    });

    return ConnectivityWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_sectionTitle(l10n)),
          flexibleSpace: Container(
            decoration: AppDecorations.gradientAppBar,
          ),
          actions: [
            // Badge notifications
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
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),

        // ── Drawer ──────────────────────────────────────────
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header avec infos user
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                accountName: userState.isLoading
                    ? const SizedBox(
                        height: 12,
                        width: 100,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        userState.user?.fullName ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                accountEmail: Text(userState.user?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: userState.isLoading
                      ? const CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        )
                      : userState.user?.hasProfileImage == true
                          ? ClipOval(
                              child: Image.network(
                                userState.user!.profileImageUrl,
                                width: AppSizes.avatarM,
                                height: AppSizes.avatarM,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Text(
                              userState.user?.initials ?? '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                ),
              ),

              // Items
              _DrawerItem(
                icon: Icons.dashboard_outlined,
                label: 'Dashboard',
                selected: _current == _Section.dashboard,
                onTap: () {
                  setState(() => _current = _Section.dashboard);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.person_outline,
                label: 'Profil',
                selected: _current == _Section.profile,
                onTap: () {
                  setState(() => _current = _Section.profile);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Wallet YSP',
                selected: _current == _Section.wallet,
                onTap: () {
                  setState(() => _current = _Section.wallet);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
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
                label: 'Paramètres',
                selected: _current == _Section.settings,
                onTap: () {
                  setState(() => _current = _Section.settings);
                  Navigator.pop(context);
                },
              ),
              _DrawerItem(
                icon: Icons.logout,
                label: 'Déconnexion',
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

        body: _sectionBody(),
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
        child: Icon(
          icon,
          color: selected ? itemColor : AppColors.textSecondary,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: selected ? itemColor : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      selectedTileColor: itemColor.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}

// ── Dashboard Body ────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    if (userState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenue
          Text(
            'Bonjour, ${userState.user?.firstName ?? ''} 👋',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSizes.spaceXS),
          const Text(
            'Trouvez et réservez votre place de parking',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Carte wallet
          _WalletCard(wallet: userState.wallet),
          const SizedBox(height: AppSizes.spaceL),

          // Véhicule par défaut
          _DefaultVehicleCard(vehicle: userState.defaultVehicle),
          const SizedBox(height: AppSizes.spaceL),

          // Réservations — placeholder
          const _SectionHeader(title: 'Mes réservations'),
          const _PlaceholderBody(label: 'Réservations — à venir'),
        ],
      ),
    );
  }
}

// ── Wallet Card ───────────────────────────────────────────────

class _WalletCard extends StatelessWidget {
  final WalletModel? wallet;
  const _WalletCard({this.wallet});

  @override
  Widget build(BuildContext context) {
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
          const Text(
            'YSP Coin',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: AppSizes.spaceXS),
          Text(
            '${wallet?.balance ?? 0} SPM',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSizes.spaceM),
          const Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: Colors.white70, size: 16),
              SizedBox(width: AppSizes.spaceXS),
              Text('Portefeuille YSP',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Default Vehicle Card ──────────────────────────────────────

class _DefaultVehicleCard extends StatelessWidget {
  final VehicleModel? vehicle;
  const _DefaultVehicleCard({this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceM),
        child: Row(
          children: [
            const Icon(Icons.directions_car_outlined, size: AppSizes.iconXL),
            const SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: vehicle != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle!.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          vehicle!.licensePlate,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    )
                  : const Text(
                      'Aucun véhicule — ajoutez-en un',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceS),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _PlaceholderBody extends StatelessWidget {
  final String label;
  const _PlaceholderBody({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spaceXL),
        child: Text(
          '$label — à venir',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
