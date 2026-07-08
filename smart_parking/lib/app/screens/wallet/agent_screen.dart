import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_parking/app/viewmodels/auth_viewmodel.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/wallet_model.dart';

class AgentScreen extends ConsumerStatefulWidget {
  const AgentScreen({super.key});

  @override
  ConsumerState<AgentScreen> createState() => _AgentScreenState();
}

class _AgentScreenState extends ConsumerState<AgentScreen> {
  final MobileScannerController _scanController = MobileScannerController();
  final TextEditingController _amountController = TextEditingController();

  String? _scannedUid;
  WalletModel? _wallet;
  bool _isLoading = false;
  bool _isConfirming = false;
  bool _isScanning = true;

  @override
  void dispose() {
    _scanController.dispose();
    _amountController.dispose();
    super.dispose();
  }

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
      final wallet = await fs.getWallet(uid);
      if (mounted) {
        setState(() {
          _wallet = wallet;
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

  Future<void> _confirmTopUp() async {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('Entrez un montant valide');
      return;
    }
    if (_wallet == null || _scannedUid == null) return;

    setState(() => _isConfirming = true);
    try {
      final fs = ref.read(firestoreServiceProvider);
      final newBalance = _wallet!.balance + amount;
      await fs.updateWalletBalance(_scannedUid!, _wallet!.id, newBalance);
      await fs.addTopUp(
        uid: _scannedUid!,
        walletId: _wallet!.id,
        amount: amount,
        newBalance: newBalance,
        source: 'qrCode',
      );

      if (mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 56),
                const SizedBox(height: AppSizes.spaceM),
                const Text('Rechargement effectué !',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: AppSizes.spaceS),
                Text('+$amount SPM',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: AppSizes.spaceXS),
                Text('Nouveau solde : $newBalance SPM',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );

        // Reset pour nouveau scan
        _amountController.clear();
        setState(() {
          _scannedUid = null;
          _wallet = null;
          _isConfirming = false;
          _isScanning = true;
        });
        await _scanController.start();
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erreur: $e');
        setState(() => _isConfirming = false);
      }
    }
  }

  void _reset() async {
    _amountController.clear();
    setState(() {
      _scannedUid = null;
      _wallet = null;
      _isScanning = true;
    });
    await _scanController.start();
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent YSP — Rechargement'),
        flexibleSpace: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient)),
        actions: [
          if (_scannedUid != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _reset,
              tooltip: 'Nouveau scan',
            ),
        ],
      ),
      body: _isScanning
          ? _buildScanner()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _buildTopUpForm(),
    );
  }

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
        // Overlay
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.transparent,
            ),
          ),
          child: CustomPaint(
            painter: _ScannerOverlay(),
            child: const SizedBox.expand(),
          ),
        ),
        // Instruction
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

  Widget _buildTopUpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        children: [
          // Infos client
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
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 32),
                const SizedBox(height: AppSizes.spaceS),
                const Text('Client identifié',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.success)),
                const SizedBox(height: AppSizes.spaceXS),
                Text(_scannedUid ?? '',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace')),
                const SizedBox(height: AppSizes.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 6),
                    Text('Solde actuel : ${_wallet?.balance ?? 0} SPM',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
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
                style: TextStyle(fontWeight: FontWeight.bold)),
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
                onTap: () => _amountController.text = '$amt',
                child: Chip(
                  label: Text('$amt SPM'),
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
                    onPressed: _confirmTopUp,
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

// Overlay scanner
class _ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const scanSize = 250.0;
    final scanRect =
        Rect.fromCenter(center: center, width: scanSize, height: scanSize);

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Bordure du scan
    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
        borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
