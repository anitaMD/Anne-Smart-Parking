import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_parking/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/wallet_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

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
      body: walletAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(l10n.profileErrorPrefix(e.toString()))),
        data: (wallet) => RefreshIndicator(
          onRefresh: () async => ref.refresh(walletStreamProvider),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _WalletHeader(
                  balance: wallet?.balance ?? 0,
                  uid: uid,
                  // onShowQr: () => _showQrCode(context, uid),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.spaceM,
                      AppSizes.spaceL, AppSizes.spaceM, AppSizes.spaceS),
                  child: Text(l10n.walletHistory,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              transactionsAsync.when(
                loading: () => const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) =>
                    SliverToBoxAdapter(child: Center(child: Text('$e'))),
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const SliverToBoxAdapter(
                        child: _EmptyTransactions());
                  }
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _TransactionTile(transaction: transactions[i]),
                      childCount: transactions.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(
                  child: SizedBox(height: AppSizes.spaceXXL)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletHeader extends ConsumerWidget {
  final int balance;
  final String uid;

  const _WalletHeader({required this.balance, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(AppSizes.spaceM),
      padding: const EdgeInsets.all(AppSizes.spaceXL),
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
          // Solde à gauche
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.walletBalance,
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: AppSizes.spaceXS),
                Text('$balance SPM',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: AppSizes.spaceS),
                Text(l10n.walletPortfolioLabel,
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),

          // QR Code à droite
          // QR Code à droite
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
                  children: [
                    QrImageView(
                      data: uid,
                      version: QrVersions.auto,
                      size: 90,
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
                        style: TextStyle(
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

class _TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    String fmt(DateTime dt) => DateFormat(
            'dd MMM yyyy · HH:mm', Localizations.localeOf(context).languageCode)
        .format(dt);
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

    return Container(
      margin:
          const EdgeInsets.symmetric(horizontal: AppSizes.spaceM, vertical: 4),
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
          Text(
            isDebit
                ? '-${transaction.amount} SPM'
                : '+${transaction.amount} SPM',
            style: TextStyle(
                color: color, fontWeight: FontWeight.w900, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: AppSizes.spaceXS),
          Text(
            l10n.walletNoTransactionsSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
