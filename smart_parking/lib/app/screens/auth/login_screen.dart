import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:smart_parking/l10n/generated/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ysp_button.dart';
import '../../widgets/ysp_text_field.dart';
import '../../router/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _emailFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  Future<void> _resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (_emailController.text.isEmpty) {
      _showError(l10n.loginResetEmailRequired);
      return;
    }
    final error = await ref
        .read(authProvider.notifier)
        .sendPasswordReset(_emailController.text);
    if (!mounted) return;
    if (error != null) {
      _showError(error);
    } else {
      _showSuccess(l10n.loginResetEmailSent);
    }
  }

  Future<void> _sendOTP() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    final phoneText = _phoneController.text.trim();
    final fullPhone = phoneText.startsWith('+') ? phoneText : '+221$phoneText';
    try {
      final phone = PhoneNumber.parse(fullPhone, callerCountry: IsoCode.SN);
      if (!phone.isValid()) {
        _showError('Numéro de téléphone invalide.');
        return;
      }
    } catch (_) {
      _showError('Format de numéro invalide.');
      return;
    }
    await ref.read(authProvider.notifier).sendOTP(phoneNumber: fullPhone);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen(authProvider, (previous, next) {
      if (next is AuthAuthenticated && mounted) {
        AppRouter.pushAndClearStack(context, AppRoutes.home);
      } else if (next is AuthOTPSent && mounted) {
        AppRouter.push(context, AppRoutes.otp,
            arguments: OTPArguments(
              verificationId: next.verificationId,
              phoneNumber: next.phoneNumber,
            ));
      } else if (next is AuthError && mounted) {
        _showError(next.message);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.spaceL),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spaceXL),

              // Logo
              Image.asset('assets/images/logo.png', height: 150),
              const SizedBox(height: AppSizes.spaceM),
              // Text('YSP Smart Parking', ...) — commenté intentionnellement
              const SizedBox(height: AppSizes.spaceXS),
              Text(
                l10n.loginWelcomeSubtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSizes.spaceXL),

              // ── TabBar — fix pilule complète ─────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusFull),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
                  tabs: const [
                    Tab(
                      height: 40,
                      child: Text('Email',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Tab(
                      height: 40,
                      child: Text('Téléphone',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.spaceL),

              // TabBarView
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _EmailTab(
                      formKey: _emailFormKey,
                      emailController: _emailController,
                      passwordController: _passwordController,
                      obscurePassword: _obscurePassword,
                      isLoading: isLoading,
                      onTogglePassword: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onSignIn: _signInWithEmail,
                      onResetPassword: _resetPassword,
                      l10n: l10n,
                    ),
                    _PhoneTab(
                      formKey: _phoneFormKey,
                      phoneController: _phoneController,
                      isLoading: isLoading,
                      onSendOTP: _sendOTP,
                    ),
                  ],
                ),
              ),

              // Lien inscription
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.noAccount,
                      style: const TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => AppRouter.push(context, AppRoutes.register),
                    child: Text(
                      l10n.loginSignUp,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Email Tab ─────────────────────────────────────────────────

class _EmailTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isLoading;
  final VoidCallback onTogglePassword;
  final VoidCallback onSignIn;
  final VoidCallback onResetPassword;
  final AppLocalizations l10n;

  const _EmailTab({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isLoading,
    required this.onTogglePassword,
    required this.onSignIn,
    required this.onResetPassword,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          YspTextField(
            controller: emailController,
            label: l10n.loginEmailLabel,
            hint: l10n.loginEmailPlaceholder,
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
          YspTextField(
            controller: passwordController,
            label: l10n.loginPasswordLabel,
            hint: l10n.loginPasswordPlaceholder,
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
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onResetPassword,
              child: Text(l10n.forgotPassword),
            ),
          ),
          const SizedBox(height: AppSizes.spaceS),
          isLoading
              ? SpinKitFadingCircle(
                  size: 40, color: Theme.of(context).primaryColor)
              : YspButton(label: l10n.signin, onPressed: onSignIn),
        ],
      ),
    );
  }
}

// ── Phone Tab ─────────────────────────────────────────────────

class _PhoneTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final bool isLoading;
  final VoidCallback onSendOTP;

  const _PhoneTab({
    required this.formKey,
    required this.phoneController,
    required this.isLoading,
    required this.onSendOTP,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spaceM,
                  vertical: AppSizes.spaceM + 2,
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
                  children: [
                    Text('🇸🇳', style: TextStyle(fontSize: 20)),
                    SizedBox(width: AppSizes.spaceXS),
                    Text('+221', style: TextStyle(fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.spaceS),
              Expanded(
                child: YspTextField(
                  controller: phoneController,
                  label: 'Numéro',
                  hint: '77 000 00 01',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Numéro requis';
                    }
                    if (value.length < 9) return 'Numéro trop court';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceL),
          const Text(
            'Un code de vérification sera envoyé par SMS',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceL),
          isLoading
              ? SpinKitFadingCircle(
                  size: 40, color: Theme.of(context).primaryColor)
              : YspButton(
                  label: 'Recevoir le code',
                  onPressed: onSendOTP,
                ),
        ],
      ),
    );
  }
}
