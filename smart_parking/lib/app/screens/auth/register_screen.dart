import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/ml_kit_service.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ysp_button.dart';
import '../../widgets/ysp_text_field.dart';
import '../../router/app_router.dart';
import '../../widgets/equality_card_widget.dart';

/// Écran d'inscription YSP Smart Parking — 2 étapes
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final _step1FormKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  File? _profileImage;

  bool? _hasEqualityCard;
  File? _cardRecto;
  File? _cardVerso;
  bool _isCardRectoValid = false;
  bool _isCardVersoValid = false;
  bool _isValidatingCard = false;
  bool _isCheckingAvailability = false;

  late final AppLocalizations l10n;

  final _picker = ImagePicker();
  final _mlKitService = MLKitService();

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ── Navigation entre étapes ───────────────────────────────

  Future<void> _nextPage() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_step1FormKey.currentState!.validate()) return;

    final phoneText = _phoneController.text.trim();
    final fullPhone = phoneText.startsWith('+') ? phoneText : '+221$phoneText';
    try {
      final phone = PhoneNumber.parse(fullPhone, callerCountry: IsoCode.SN);
      if (!phone.isValid()) {
        _showError(l10n.phoneInvalidNumber);
        return;
      }
    } catch (_) {
      _showError(l10n.phoneInvalidFormat);
      return;
    }

    // Vérifier que l'email et le numéro ne sont pas déjà utilisés
    // AVANT de passer à l'étape 2 — évite de remplir la carte PMR
    // pour rien si le compte ne peut pas être créé
    setState(() => _isCheckingAvailability = true);
    final emailTaken = await ref
        .read(authProvider.notifier)
        .checkEmailExists(_emailController.text.trim());
    final phoneTaken =
        await ref.read(authProvider.notifier).checkPhoneExists(fullPhone);
    if (!mounted) return;
    setState(() => _isCheckingAvailability = false);

    if (emailTaken) {
      _showError(l10n.registerEmailAlreadyUsed);
      return;
    }
    if (phoneTaken) {
      _showError(l10n.registerPhoneAlreadyUsed);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = 1);
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage = 0);
  }

  // ── Actions ───────────────────────────────────────────────

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) setState(() => _profileImage = File(picked.path));
  }

  Future<void> _pickCard(bool isRecto) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final file = File(picked.path);

    setState(() => _isValidatingCard = true);
    final result = await _mlKitService.analyzeCard(file);
    if (!mounted) return;
    setState(() => _isValidatingCard = false);

    if (!result.isValid) {
      _showError(isRecto
          ? 'Recto invalide — ${result.error}'
          : 'Verso invalide — ${result.error}');
      return;
    }

    setState(() {
      if (isRecto) {
        _cardRecto = file;
        _isCardRectoValid = true;
      } else {
        _cardVerso = file;
        _isCardVersoValid = true;
      }
    });
  }

  Future<void> _register() async {
    if (_hasEqualityCard == true) {
      if (_cardRecto == null || _cardVerso == null) {
        _showError(l10n.registerCardRequired);
        return;
      }
    }

    final phoneText = _phoneController.text.trim();
    final fullPhone = phoneText.startsWith('+') ? phoneText : '+221$phoneText';

    await ref.read(authProvider.notifier).registerWithEmailAndPhone(
          fullName: _fullNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: fullPhone,
          profileImage: _profileImage,
          hasEqualityCard: _hasEqualityCard ?? false,
          cardRecto: _cardRecto,
          cardVerso: _cardVerso,
        );
  }

  // ── UI Helpers ────────────────────────────────────────────

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading || _isCheckingAvailability;

    ref.listen(authProvider, (previous, next) {
      if (next is AuthOTPSent && mounted) {
        AppRouter.push(
          context,
          AppRoutes.otp,
          arguments: OTPArguments(
            verificationId: next.verificationId,
            phoneNumber: next.phoneNumber,
            isRegistration: true,
          ),
        );
      } else if (next is AuthError && mounted) {
        _showError(next.message);
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ── Fix couleur sombre pour titre + bouton retour ────
        foregroundColor: AppColors.textPrimary,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _currentPage == 0
              ? () => Navigator.of(context).pop()
              : _previousPage,
        ),
        title: Text(
          _currentPage == 0 ? l10n.registerTitle : l10n.registerCardStepTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Column(
        children: [
          _StepIndicator(currentStep: _currentPage, l10n: l10n),
          const SizedBox(height: AppSizes.spaceM),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1(
                  formKey: _step1FormKey,
                  fullNameController: _fullNameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  phoneController: _phoneController,
                  obscurePassword: _obscurePassword,
                  obscureConfirm: _obscureConfirm,
                  profileImage: _profileImage,
                  isLoading: isLoading,
                  onPickImage: _pickProfileImage,
                  onTogglePassword: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  onToggleConfirm: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  onNext: _nextPage,
                  l10n: l10n,
                ),
                _Step2(
                  hasEqualityCard: _hasEqualityCard,
                  cardRecto: _cardRecto,
                  cardVerso: _cardVerso,
                  isLoading: isLoading,
                  isValidatingCard: _isValidatingCard,
                  isCardRectoValid: _isCardRectoValid,
                  isCardVersoValid: _isCardVersoValid,
                  onCardChoice: (value) =>
                      setState(() => _hasEqualityCard = value),
                  onPickRecto: () => _pickCard(true),
                  onPickVerso: () => _pickCard(false),
                  onRegister: _register,
                  l10n: l10n,
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
// STEP INDICATOR
// ─────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final AppLocalizations l10n;
  const _StepIndicator({required this.currentStep, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceL),
      child: Row(
        children: [
          _StepDot(step: 0, current: currentStep, label: l10n.registerStepInfo),
          Expanded(
            child: Container(
              height: 2,
              color: currentStep >= 1
                  ? AppColors.primary
                  : AppColors.surfaceVariant,
            ),
          ),
          _StepDot(step: 1, current: currentStep, label: l10n.registerStepCard),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int step;
  final int current;
  final String label;
  const _StepDot(
      {required this.step, required this.current, required this.label});

  @override
  Widget build(BuildContext context) {
    final isActive = current >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 1 — INFOS PERSONNELLES
// ─────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController phoneController;
  final bool obscurePassword;
  final bool obscureConfirm;
  final File? profileImage;
  final bool isLoading;
  final VoidCallback onPickImage;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onNext;
  final AppLocalizations l10n;

  const _Step1({
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.phoneController,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.profileImage,
    required this.isLoading,
    required this.onPickImage,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onNext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            GestureDetector(
              onTap: onPickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    backgroundImage:
                        profileImage != null ? FileImage(profileImage!) : null,
                    child: profileImage == null
                        ? const Icon(Icons.person_outline,
                            size: 50, color: AppColors.primary)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceXS),
            Text(
              l10n.registerProfilePictureOptional,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSizes.spaceL),

            YspTextField(
              controller: fullNameController,
              label: l10n.regFullNameLabel,
              hint: l10n.regFullNamePlaceholder,
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.registerNameRequired;
                }
                if (value.trim().split(' ').length < 2) {
                  return l10n.registerNameFull;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceM),

            YspTextField(
              controller: emailController,
              label: l10n.regEmailLabel,
              hint: l10n.regEmailPlaceholder,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.loginEmailRequired;
                }
                if (!value.contains('@')) return l10n.loginEmailInvalid;
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceM),

            // ── Téléphone — même hauteur que les autres champs ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: AppSizes.inputHeight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spaceM,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🇸🇳', style: TextStyle(fontSize: 20)),
                      SizedBox(width: AppSizes.spaceXS),
                      Text('+221',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.spaceS),
                Expanded(
                  child: YspTextField(
                    controller: phoneController,
                    label: l10n.regNumberLabel,
                    hint: '77 000 00 01',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.registerPhoneRequired;
                      }
                      if (value.length < 9) {
                        return l10n.registerPhoneTooShort;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spaceM),

            YspTextField(
              controller: passwordController,
              label: l10n.regPasswordLabel,
              hint: l10n.regPasswordPlaceholder,
              icon: Icons.lock_outline,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onTogglePassword,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.loginPasswordRequired;
                }
                if (value.length < 8) return l10n.loginPasswordMinLength;
                if (!value.contains(RegExp(r'[A-Z]'))) {
                  return l10n.registerPasswordUppercase;
                }
                if (!value.contains(RegExp(r'[0-9]'))) {
                  return l10n.registerPasswordDigit;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceM),

            YspTextField(
              controller: confirmPasswordController,
              label: l10n.regConfirmPassLabel,
              hint: l10n.regConfirmPassPlaceholder,
              icon: Icons.lock_outline,
              obscureText: obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(obscureConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                onPressed: onToggleConfirm,
              ),
              validator: (value) {
                if (value != passwordController.text) {
                  return l10n.regPasswordsNoMatch;
                }
                return null;
              },
            ),
            const SizedBox(height: AppSizes.spaceXL),

            isLoading
                ? SpinKitFadingCircle(
                    size: 40,
                    color: Theme.of(context).primaryColor,
                  )
                : YspButton(
                    label: l10n.regNextButton,
                    onPressed: onNext,
                  ),
            const SizedBox(height: AppSizes.spaceM),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STEP 2 — CARTE PMR
// ─────────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final bool? hasEqualityCard;
  final File? cardRecto;
  final File? cardVerso;
  final bool isLoading;
  final bool isValidatingCard;
  final bool isCardRectoValid;
  final bool isCardVersoValid;
  final void Function(bool) onCardChoice;
  final VoidCallback onPickRecto;
  final VoidCallback onPickVerso;
  final VoidCallback onRegister;
  final AppLocalizations l10n;

  const _Step2({
    required this.hasEqualityCard,
    required this.cardRecto,
    required this.cardVerso,
    required this.isLoading,
    required this.isValidatingCard,
    required this.isCardRectoValid,
    required this.isCardVersoValid,
    required this.onCardChoice,
    required this.onPickRecto,
    required this.onPickVerso,
    required this.onRegister,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spaceM),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusM),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const SizedBox(width: AppSizes.spaceS),
                Expanded(
                  child: Text(
                    l10n.regEgaliteChancesDescription,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.spaceL),
          Text(
            l10n.regEgaliteDesChances,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: AppSizes.spaceM),
          Row(
            children: [
              Expanded(
                child: _ChoiceCard(
                  label: l10n.regRadioYes,
                  icon: Icons.check_circle_outline,
                  isSelected: hasEqualityCard == true,
                  onTap: () => onCardChoice(true),
                ),
              ),
              const SizedBox(width: AppSizes.spaceM),
              Expanded(
                child: _ChoiceCard(
                  label: l10n.regRadioNo,
                  icon: Icons.cancel_outlined,
                  isSelected: hasEqualityCard == false,
                  onTap: () => onCardChoice(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceL),
          if (hasEqualityCard == true) ...[
            Text(
              l10n.registerUploadCardTitle,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSizes.spaceXS),
            Text(
              l10n.registerCardLooksLike,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSizes.spaceS),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  EqualityCardWidget.recto(),
                  const SizedBox(width: AppSizes.spaceM),
                  EqualityCardWidget.verso(),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.spaceM),
            if (isValidatingCard)
              const Center(child: CircularProgressIndicator()),
            if (!isValidatingCard)
              Row(
                children: [
                  Expanded(
                    child: _CardUploadButton(
                      label: l10n.registerCardRecto,
                      file: cardRecto,
                      isValid: isCardRectoValid,
                      onTap: onPickRecto,
                    ),
                  ),
                  const SizedBox(width: AppSizes.spaceM),
                  Expanded(
                    child: _CardUploadButton(
                      label: l10n.registerCardVerso,
                      file: cardVerso,
                      isValid: isCardVersoValid,
                      onTap: onPickVerso,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: AppSizes.spaceL),
          ],
          if (hasEqualityCard != null)
            isLoading
                ? Center(
                    child: SpinKitFadingCircle(
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : YspButton(
                    label: l10n.registerSubmit,
                    onPressed: onRegister,
                  ),
        ],
      ),
    );
  }
}

// ── Choice Card ───────────────────────────────────────────────

class _ChoiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.label,
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
        padding: const EdgeInsets.all(AppSizes.spaceM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSizes.spaceXS),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Card Upload Button ────────────────────────────────────────

class _CardUploadButton extends StatelessWidget {
  final String label;
  final File? file;
  final bool isValid;
  final VoidCallback onTap;

  const _CardUploadButton({
    required this.label,
    required this.file,
    required this.isValid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: isValid
              ? AppColors.success.withValues(alpha: 0.1)
              : file != null
                  ? AppColors.error.withValues(alpha: 0.1)
                  : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isValid
                ? AppColors.success
                : file != null
                    ? AppColors.error
                    : AppColors.border,
            width: file != null ? 2 : 1,
          ),
          image: file != null
              ? DecorationImage(
                  image: FileImage(file!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: file == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload_outlined,
                      color: AppColors.textSecondary),
                  const SizedBox(height: AppSizes.spaceXS),
                  Text(
                    label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isValid ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isValid ? Icons.check : Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
