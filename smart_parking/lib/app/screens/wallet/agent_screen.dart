import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_parking/app/models/user_model.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../router/app_router.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/wallet_model.dart';
import '../../viewmodels/user_viewmodel.dart';

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  MobileScannerController _scanController = MobileScannerController();
  final TextEditingController _amountController = TextEditingController();

  String? _scannedUid;
  WalletModel? _wallet;
  bool _isLoading = false;
  bool _isConfirming = false;
  bool _isScanning = true;
  bool _showScanner = false; // ← Start with dashboard
  String? _clientName;

  @override
  void dispose() {
    _scanController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ── QR Detected ──────────────────────────────────────────

  Future<void> _onQrDetected(String uid) async {
    if (!_isScanning) return;
    setState(() {
      _isScanning = false;
      _isLoading = true;
      _scannedUid = uid;
    });

    try {
      await _scanController.stop();
      final fs = ref.read(firestoreServiceProvider);
      // Fetch wallet AND client name
      final results = await Future.wait([
        fs.getWallet(uid),
        fs.getUser(uid),
      ]);
      if (mounted) {
        setState(() {
          _wallet = results[0] as WalletModel?;
          final user = results[1];
          _clientName = (user as dynamic)?.fullName as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _scannedUid = null;
          _isScanning = true;
        });
        _showSnack('Utilisateur non trouvé');
        await _scanController.start();
      }
    }
  }

  // ── Confirm Top Up ────────────────────────────────────────

  Future<void> _confirmTopUp(AppLocalizations l10n) async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('Entrez un montant valide');
      return;
    }
    if (_wallet == null || _scannedUid == null) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    // Check agent has enough SPM balance
    final agentWallet = ref.read(userProvider).wallet;
    if (agentWallet == null || agentWallet.balance < amount) {
      _showSnack(l10n.agentInsufficientBalance);
      return;
    }

    setState(() => _isConfirming = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      // Debit agent wallet
      await fs.updateWalletBalance(
          authState.user.id, agentWallet.id, agentWallet.balance - amount);
      // Credit client wallet
      final newBalance = _wallet!.balance + amount;
      await fs.updateWalletBalance(_scannedUid!, _wallet!.id, newBalance);
      await fs.addTopUp(
        uid: _scannedUid!,
        walletId: _wallet!.id,
        amount: amount,
        newBalance: newBalance,
        source: 'qrCode',
        agentUid: authState.user.id,
      );

      // Notification locale + Firestore pour le client
      await fs.saveNotification(
        uid: _scannedUid!,
        title: '💰 Rechargement effectué !',
        body: 'Vous avez reçu $amount SPM. Nouveau solde : $newBalance SPM.',
      );

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle,
                      color: AppColors.success, size: 48),
                ),
                const SizedBox(height: AppSizes.spaceM),
                const Text('Rechargement effectué !',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: AppSizes.spaceS),
                Text('+$amount SPM',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 28,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: AppSizes.spaceXS),
                Text('Nouveau solde : $newBalance SPM',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        );

        _amountController.clear();
        setState(() {
          _scannedUid = null;
          _wallet = null;
          _isConfirming = false;
          _isScanning = true;
          _showScanner = false; // ← Return to dashboard
        });
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur: $e');
        setState(() => _isConfirming = false);
      }
    }
  }

  // ── Reset ─────────────────────────────────────────────────

  Future<void> _reset() async {
    _amountController.clear();
    _scanController.dispose();
    _scanController = MobileScannerController();
    if (mounted) {
      setState(() {
        _scannedUid = null;
        _wallet = null;
        _clientName = null;
        _isScanning = true;
      });
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Listen for logout
    ref.listen(authProvider, (_, next) {
      if (next is AuthUnauthenticated && mounted) {
        AppRouter.pushAndClearStack(context, AppRoutes.login);
      }
    });

    final userState = ref.watch(userProvider);
    final agent = userState.user;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(_showScanner
            ? (_isScanning ? 'Scanner client' : 'Rechargement')
            : 'Agent YSP'),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient)),
        automaticallyImplyLeading: false,
        leading: _showScanner
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () async {
                  await _scanController.stop();
                  setState(() {
                    _showScanner = false;
                    _isScanning = true;
                    _scannedUid = null;
                    _clientName = null;
                    _wallet = null;
                    _amountController.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_showScanner && _scannedUid != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Nouveau scan',
            ),
          if (!_showScanner)
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () => ref.read(authProvider.notifier).signOut(),
              tooltip: 'Déconnexion',
            ),
        ],
      ),
      body: _showScanner
          ? (_isScanning
              ? _buildScanner()
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildTopUpForm())
          : _buildDashboard(agent),
    );
  }

  // ── Dashboard ─────────────────────────────────────────────

  Widget _buildDashboard(dynamic agent) {
    final authState = ref.read(authProvider);
    final uid = authState is AuthAuthenticated ? authState.user.id : '';
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bonjour outside card - like dashboard
          Text(
            '${l10n.dashboardHello}, ${agent?.fullName ?? l10n.agentTitle} 👋',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Card with badge + location + balance
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.spaceL),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(l10n.agentBadge,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (agent?.location != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(agent!.location!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ]),
                ],
                const SizedBox(height: AppSizes.spaceM),
                Consumer(builder: (_, ref, __) {
                  final wallet = ref.watch(userProvider).wallet;
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Mon solde : ${wallet?.balance ?? 0} SPM',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Stats
          _AgentStats(uid: uid),
          const SizedBox(height: AppSizes.spaceL),

          // Bouton scanner
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                _scanController.dispose();
                _scanController = MobileScannerController();
                setState(() {
                  _showScanner = true;
                  _isScanning = true;
                });
              },
              icon: const Icon(Icons.qr_code_scanner, size: 22),
              label: const Text('Scanner un client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),

          // Historique
          const Text('Rechargements récents',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSizes.spaceM),
          _AgentTopUpHistory(uid: uid),
        ],
      ),
    );
  }

  // ── Scanner ───────────────────────────────────────────────

  Widget _buildScanner() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scanController,
          onDetect: (capture) {
            final barcode = capture.barcodes.firstOrNull;
            if (barcode?.rawValue != null) {
              _onQrDetected(barcode!.rawValue!);
            }
          },
        ),
        CustomPaint(
          painter: _ScannerOverlay(),
          child: const SizedBox.expand(),
        ),
        const Positioned(
          bottom: 60,
          left: 0,
          right: 0,
          child: Text(
            'Scannez le QR Code du client',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
          ),
        ),
      ],
    );
  }

  // ── Top Up Form ───────────────────────────────────────────

  Widget _buildTopUpForm() {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        children: [
          // Client identifié
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceL),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border:
                  Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 32),
                ),
                const SizedBox(height: AppSizes.spaceS),
                const Text('Client identifié',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                        fontSize: 16)),
                const SizedBox(height: AppSizes.spaceXS),
                Text(
                  _clientName ?? 'Client identifié',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                const SizedBox(height: AppSizes.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Solde actuel : ${_wallet?.balance ?? 0} SPM',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceXL),

          // Montant
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Montant à créditer (SPM)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: AppSizes.spaceS),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: '0',
              suffix: const Text('SPM',
                  style: TextStyle(color: AppColors.textSecondary)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spaceM),

          // Montants rapides
          Wrap(
            spacing: AppSizes.spaceS,
            children: [500, 1000, 2000, 5000, 10000].map((amt) {
              return GestureDetector(
                onTap: () => setState(() => _amountController.text = '$amt'),
                child: Chip(
                  label: Text('$amt'),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.primary),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSizes.spaceXL),

          // Bouton confirmer
          SizedBox(
            width: double.infinity,
            height: AppSizes.buttonHeight,
            child: _isConfirming
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: () => _confirmTopUp(l10n),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('Confirmer le rechargement',
                        style: TextStyle(fontSize: 16)),
                  ),
          ),
          const SizedBox(height: AppSizes.spaceM),
          TextButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scanner un autre client'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AGENT STATS
// ─────────────────────────────────────────────────────────────

class _AgentStats extends ConsumerWidget {
  final String uid;
  const _AgentStats({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(firestoreServiceProvider).watchAgentTopUps(uid),
      builder: (context, snapshot) {
        // Use previous data to avoid flickering 0→1
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Row(children: [
            Expanded(child: _StatCardSkeleton()),
            SizedBox(width: 16),
            Expanded(child: _StatCardSkeleton()),
          ]);
        }
        final topUps = snapshot.data ?? [];
        final today = DateTime.now();
        final todayTopUps = topUps.where((t) {
          final ts = t['timestamp'];
          if (ts == null) return false;
          final date = ts.toDate() as DateTime;
          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).toList();
        final todayTotal = todayTopUps.fold<int>(
            0, (sum, t) => sum + (t['amount'] as int? ?? 0));
        final allTotal =
            topUps.fold<int>(0, (sum, t) => sum + (t['amount'] as int? ?? 0));

        return Row(children: [
          Expanded(
            child: _StatCard(
              icon: Icons.today_outlined,
              label: "Aujourd'hui",
              value: '${todayTopUps.length}',
              subtitle: '+$todayTotal SPM',
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSizes.spaceM),
          Expanded(
            child: _StatCard(
              icon: Icons.bar_chart_outlined,
              label: 'Total',
              value: '${topUps.length}',
              subtitle: '+$allTotal SPM',
              color: AppColors.success,
            ),
          ),
        ]);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ]),
          const SizedBox(height: AppSizes.spaceS),
          Text(value,
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w900, color: color)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// AGENT TOP UP HISTORY
// ─────────────────────────────────────────────────────────────

class _AgentTopUpHistory extends ConsumerWidget {
  final String uid;
  const _AgentTopUpHistory({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(firestoreServiceProvider).watchAgentTopUps(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final topUps = snapshot.data ?? [];
        if (topUps.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSizes.spaceXL),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.history_outlined,
                      size: 40, color: AppColors.textSecondary),
                  SizedBox(height: AppSizes.spaceS),
                  Text('Aucun rechargement effectué',
                      style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }
        return Column(
          children: topUps.take(10).map((t) {
            final ts = t['timestamp'];
            final date = ts?.toDate() as DateTime?;
            final amount = t['amount'] as int? ?? 0;
            final clientId = t['clientId'] as String? ?? '';

            return _TopUpHistoryTile(
              topUp: t,
              date: date,
              amount: amount,
              clientId: clientId,
              ref: ref,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STAT CARD SKELETON
// ─────────────────────────────────────────────────────────────

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          Container(
            width: 40,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// TOP UP HISTORY TILE
// ─────────────────────────────────────────────────────────────

class _TopUpHistoryTile extends ConsumerWidget {
  final Map<String, dynamic> topUp;
  final DateTime? date;
  final int amount;
  final String clientId;
  final WidgetRef ref;

  const _TopUpHistoryTile({
    required this.topUp,
    required this.date,
    required this.amount,
    required this.clientId,
    required this.ref,
  });

  /// Solde précédent = solde après - montant crédité
  int get _previousBalance {
    final newBal = topUp['newBalance'] as int? ?? 0;
    return newBal - amount;
  }

  void _showDetails(
      BuildContext context, String? clientName, String? clientPhone) {
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
            const SizedBox(height: AppSizes.spaceL),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward_rounded,
                  color: AppColors.success, size: 32),
            ),
            const SizedBox(height: AppSizes.spaceM),
            Text('+$amount SPM',
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: AppColors.success)),
            const SizedBox(height: AppSizes.spaceL),
            const Divider(),
            const SizedBox(height: AppSizes.spaceS),
            _AgentDetailRow(label: 'Client', value: clientName ?? clientId),
            if (clientPhone != null && clientPhone.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spaceS),
              _AgentDetailRow(label: 'Téléphone', value: clientPhone),
            ],
            if (date != null) ...[
              const SizedBox(height: AppSizes.spaceS),
              _AgentDetailRow(
                label: 'Date',
                value: DateFormat('dd MMM yyyy · HH:mm', 'fr').format(date!),
              ),
            ],
            const SizedBox(height: AppSizes.spaceS),
            _AgentDetailRow(
              label: 'Solde précédent',
              value: '$_previousBalance SPM',
            ),
            const SizedBox(height: AppSizes.spaceS),
            _AgentDetailRow(
              label: 'Nouveau solde',
              value: '${topUp['newBalance'] ?? 0} SPM',
            ),
            const SizedBox(height: AppSizes.spaceL),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<UserModel?>(
      future: clientId.isEmpty
          ? Future.value(null)
          : ref
              .read(firestoreServiceProvider)
              .getUser(clientId)
              .catchError((e) {
              debugPrint('[Agent] getUser error for $clientId: $e');
              return null;
            }),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final clientName = user?.fullName;
        final clientPhone = user?.phoneNumber;
        debugPrint('[Agent] $clientId: $clientName, $clientPhone');

        return GestureDetector(
          onTap: () => _showDetails(context, clientName, clientPhone),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppSizes.spaceS),
            padding: const EdgeInsets.all(AppSizes.spaceM),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_downward_rounded,
                    color: AppColors.success, size: 20),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName ?? clientId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (clientPhone != null && clientPhone.isNotEmpty)
                      Text(clientPhone,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 11)),
                    if (date != null)
                      Text(
                        DateFormat('dd MMM yyyy · HH:mm', 'fr').format(date!),
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('+$amount SPM',
                      style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w900,
                          fontSize: 15)),
                  const Icon(Icons.info_outline,
                      size: 12, color: AppColors.textSecondary),
                ],
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _AgentDetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _AgentDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCANNER OVERLAY
// ─────────────────────────────────────────────────────────────

class _ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const scanSize = 260.0;
    final scanRect =
        Rect.fromCenter(center: center, width: scanSize, height: scanSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);

    // Coins colorés
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLen = 24.0;
    final l = scanRect.left;
    final t = scanRect.top;
    final r = scanRect.right;
    final b = scanRect.bottom;

    // Top left
    canvas.drawLine(Offset(l, t + cornerLen), Offset(l, t), cornerPaint);
    canvas.drawLine(Offset(l, t), Offset(l + cornerLen, t), cornerPaint);
    // Top right
    canvas.drawLine(Offset(r - cornerLen, t), Offset(r, t), cornerPaint);
    canvas.drawLine(Offset(r, t), Offset(r, t + cornerLen), cornerPaint);
    // Bottom left
    canvas.drawLine(Offset(l, b - cornerLen), Offset(l, b), cornerPaint);
    canvas.drawLine(Offset(l, b), Offset(l + cornerLen, b), cornerPaint);
    // Bottom right
    canvas.drawLine(Offset(r - cornerLen, b), Offset(r, b), cornerPaint);
    canvas.drawLine(Offset(r, b), Offset(r, b - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
