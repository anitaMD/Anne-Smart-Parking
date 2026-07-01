import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../viewmodels/connectivity_viewmodel.dart';

/// Widget qui enveloppe n'importe quel écran et affiche
/// automatiquement un bandeau si la connexion est perdue.
// Usage : ConnectivityWrapper(child: MonEcran())
class ConnectivityWrapper extends ConsumerWidget {
  final Widget child;
  const ConnectivityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch() rebuild automatiquement quand isConnected change
    final connectivity = ref.watch(connectivityProvider);

    // Pas encore initialisé → afficher le contenu directement
    if (!connectivity.isInitialized) return child;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height:
              connectivity.isConnected ? 0 : AppSizes.connectivityBannerHeight,
          child: connectivity.isConnected
              ? const SizedBox.shrink()
              : const _ConnectivityBanner(),
        ),
        Expanded(child: child),
      ],
    );
  }
}

class _ConnectivityBanner extends StatelessWidget {
  const _ConnectivityBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.offline,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spaceM,
        vertical: AppSizes.spaceXS,
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded,
              color: Colors.white, size: AppSizes.iconS),
          SizedBox(width: AppSizes.spaceS),
          Text(
            'Pas de connexion Internet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
