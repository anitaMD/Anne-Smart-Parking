import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_parking/app/core/utils/number_formatter.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/wallet_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

final walletStreamProvider = StreamProvider<WalletModel?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value(null);
  return ref.read(firestoreServiceProvider).watchWallet(authState.user.id);
});

final transactionsProvider = StreamProvider<List<TransactionModel>>((ref) {
  final authState = ref.watch(authProvider);
  if (authState is! AuthAuthenticated) return Stream.value([]);
  final wallet = ref.watch(userProvider).wallet;
  if (wallet == null) return Stream.value([]);
  return ref
      .read(firestoreServiceProvider)
      .watchTransactions(authState.user.id, wallet.id);
});

// ─────────────────────────────────────────────────────────────
// WALLET SCREEN
// ─────────────────────────────────────────────────────────────

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletStreamProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final authState = ref.watch(authProvider);
    final uid = authState is AuthAuthenticated ? authState.user.id : '';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletStreamProvider);
          ref.invalidate(transactionsProvider);
        },
        child: ListView(
          children: [
            // ── Wallet Card ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.spaceM, AppSizes.spaceM, AppSizes.spaceM, 0),
              child: walletAsync.when(
                loading: () => _WalletHeader(
                    balance: ref.watch(userProvider).wallet?.balance ?? 0,
                    uid: uid),
                error: (_, __) => _WalletHeader(balance: 0, uid: uid),
                data: (wallet) =>
                    _WalletHeader(balance: wallet?.balance ?? 0, uid: uid),
              ),
            ),

            // ── Titre historique ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.spaceM,
                  AppSizes.spaceL, AppSizes.spaceM, AppSizes.spaceS),
              child: Text(l10n.walletHistory,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),

            // ── Transactions ──────────────────────────────
            transactionsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.spaceXL),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) =>
                  Center(child: Text(l10n.profileErrorPrefix(e.toString()))),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const _EmptyTransactions();
                }
                return Column(
                  children: transactions
                      .map((t) => _TransactionTile(transaction: t))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: AppSizes.spaceXXL),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WALLET HEADER
// ─────────────────────────────────────────────────────────────

class _WalletHeader extends ConsumerWidget {
  final int balance;
  final String uid;

  const _WalletHeader({required this.balance, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Solde
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.walletBalance,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text('${formatSPM(balance)} SPM',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(l10n.walletPortfolioLabel,
                    style:
                        const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ),

          // QR glassmorphism
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusM),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    QrImageView(
                      data: uid,
                      version: QrVersions.auto,
                      size: 80,
                      backgroundColor: Colors.transparent,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.white,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.walletQrScanToRecharge,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 9, color: Colors.white70, height: 1.2)),
                  ],
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
// TRANSACTION TILE
// ─────────────────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;

    String fmt(DateTime dt) =>
        DateFormat('dd MMM yyyy · HH:mm', locale).format(dt);

    String sourceLabel(TopUpSource? source) {
      switch (source) {
        case TopUpSource.agent:
          return l10n.walletTopUpAgent;
        case TopUpSource.qrCode:
          return l10n.walletTopUpQr;
        case TopUpSource.online:
          return l10n.walletTopUpOnline;
        default:
          return '';
      }
    }

    final isDebit = transaction.isDebit;
    final color = isDebit ? AppColors.error : AppColors.success;
    final label = isDebit
        ? transaction.parkingName ?? l10n.walletTransactionBooking
        : l10n.walletTransactionTopUp + sourceLabel(transaction.topUpSource);

    void showDetails() {
      if (isDebit) return;
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => _TopUpDetailSheet(
          transaction: transaction,
          sourceLabel: sourceLabel(transaction.topUpSource),
          fmt: fmt,
          l10n: l10n,
        ),
      );
    }

    return GestureDetector(
      onTap: isDebit ? null : showDetails,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppSizes.spaceM, vertical: 4),
        padding: const EdgeInsets.all(AppSizes.spaceM),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(
                  isDebit
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: color,
                  size: 20),
            ),
            const SizedBox(width: AppSizes.spaceM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(fmt(transaction.timestamp),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(l10n.walletBalanceLabel(transaction.newBalance),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isDebit
                      ? '-${transaction.amount} SPM'
                      : '+${transaction.amount} SPM',
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w900, fontSize: 15),
                ),
                if (!isDebit) ...[
                  const SizedBox(height: 2),
                  const Icon(Icons.info_outline,
                      size: 12, color: AppColors.textSecondary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

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
// EMPTY STATE
// ─────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.spaceXXL),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 60, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: AppSizes.spaceM),
          Text(l10n.walletNoTransactions,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSizes.spaceXS),
          Text(
            l10n.walletNoTransactionsSubtitle,
            textAlign: TextAlign.center,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TopUpDetailSheet extends ConsumerWidget {
  final TransactionModel transaction;
  final String sourceLabel;
  final String Function(DateTime) fmt;
  final AppLocalizations l10n;

  const _TopUpDetailSheet({
    required this.transaction,
    required this.sourceLabel,
    required this.fmt,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: FutureBuilder<String?>(
        future: transaction.agentId != null
            ? ref
                .read(firestoreServiceProvider)
                .getUser(transaction.agentId!)
                .then((u) => u?.fullName)
            : Future.value(null),
        builder: (context, snapshot) {
          final agentName = snapshot.data;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: AppSizes.spaceL),
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_downward_rounded,
                      color: AppColors.success, size: 32)),
              const SizedBox(height: AppSizes.spaceM),
              Text('+${transaction.amount} SPM',
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: AppColors.success)),
              const SizedBox(height: 4),
              Text(l10n.walletTransactionTopUp + sourceLabel,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: AppSizes.spaceL),
              const Divider(),
              const SizedBox(height: AppSizes.spaceS),
              _DetailRow(
                  label: l10n.bookingDate, value: fmt(transaction.timestamp)),
              const SizedBox(height: AppSizes.spaceS),
              _DetailRow(
                  label: l10n.bookingBalanceAfter,
                  value: '${transaction.newBalance} SPM'),
              if (agentName != null) ...[
                const SizedBox(height: AppSizes.spaceS),
                _DetailRow(label: l10n.agentClient, value: agentName),
              ],
              const SizedBox(height: AppSizes.spaceL),
            ],
          );
        },
      ),
    );
  }
}
