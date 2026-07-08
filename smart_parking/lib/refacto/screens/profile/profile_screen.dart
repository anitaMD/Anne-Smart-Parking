import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../services/storage_service.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _initialName = '';
  String _initialEmail = '';
  String _initialPhone = '';

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  bool _isUploadingCard = false;

  final _storageService = StorageService();
  final _picker = ImagePicker();

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _emailController.text.trim() != _initialEmail ||
      _phoneController.text.trim() != _initialPhone;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phoneNumber;
      _initialName = user.fullName;
      _initialEmail = user.email;
      _initialPhone = user.phoneNumber;
      _nameController.addListener(() => setState(() {}));
      _emailController.addListener(() => setState(() {}));
      _phoneController.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final url = await _storageService.uploadProfilePicture(
        file: File(picked.path),
        uid: authState.user.id,
      );
      if (url != null && mounted) {
        await ref.read(firestoreServiceProvider).updateUser(
          authState.user.id,
          {'profileImageUrl': url},
        );
        await ref.read(userProvider.notifier).loadUserData(authState.user.id);
        _showSnack('Photo mise à jour ✅');
      }
    } catch (e) {
      _showSnack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _pickEqualityCard(String side) async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isUploadingCard = true);
    try {
      final url = await _storageService.uploadEqualityCard(
        file: File(picked.path),
        uid: authState.user.id,
        side: side,
      );
      if (url != null && mounted) {
        final user = ref.read(userProvider).user!;
        final paths = List<String>.from(user.equalityCardPaths);
        final idx = side == 'recto' ? 0 : 1;
        if (paths.length > idx) {
          paths[idx] = url;
        } else {
          paths.add(url);
        }
        await ref.read(firestoreServiceProvider).updateUser(
          authState.user.id,
          {
            'equalityCardPaths': paths,
            'isSpecialAccessUser': paths.length >= 2,
          },
        );
        await ref.read(userProvider.notifier).loadUserData(authState.user.id);
        _showSnack('Carte $side uploadée ✅');
      }
    } catch (e) {
      _showSnack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isUploadingCard = false);
    }
  }

  // ── Changer l'email ───────────────────────────────────────

  Future<void> _changeEmail() async {
    final newEmailController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier l\'email'),
        content: TextField(
          controller: newEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Nouvel email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, newEmailController.text.trim()),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.verifyBeforeUpdateEmail(result);

// ← informer + déconnecter
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('Vérifiez votre email'),
            content: Text(
              'Un lien de vérification a été envoyé à $result.\n\n'
              'Cliquez sur le lien pour confirmer votre nouvel email, '
              'puis reconnectez-vous.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK, me déconnecter'),
              ),
            ],
          ),
        );
        // Déconnecter après fermeture du dialog
        await ref.read(authProvider.notifier).signOut();
      }
    } on FirebaseAuthException catch (e) {
      _showSnack('Erreur: ${e.message}');
    }
  }

// ── Changer le téléphone ──────────────────────────────────

  Future<void> _changePhone() async {
    final phoneController = TextEditingController();

    // Étape 1 — entrer le nouveau numéro
    final newPhone = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Modifier le téléphone'),
        content: TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Nouveau numéro',
            hintText: '+221XXXXXXXXX',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, phoneController.text.trim()),
            child: const Text('Envoyer SMS'),
          ),
        ],
      ),
    );

    if (newPhone == null || newPhone.isEmpty) return;

    // Étape 2 — envoyer OTP
    _showSnack('Envoi du SMS...');
    final authService = ref.read(authServiceProvider);
    final verificationId = await authService.sendOTP(phoneNumber: newPhone);

    if (verificationId == null || verificationId.startsWith('ERROR:')) {
      _showSnack(
          'Erreur: ${verificationId?.replaceFirst('ERROR:', '') ?? 'SMS non envoyé'}');
      return;
    }
    if (verificationId == 'AUTO_VERIFIED') {
      _showSnack('Téléphone vérifié automatiquement.');
      return;
    }

    // Étape 3 — entrer le code OTP
    final otpController = TextEditingController();
    if (!mounted) return;
    final otp = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Code SMS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Code envoyé au $newPhone'),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code à 6 chiffres',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, otpController.text.trim()),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );

    if (otp == null || otp.isEmpty) return;

    // Étape 4 — mettre à jour Firebase Auth
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await FirebaseAuth.instance.currentUser?.updatePhoneNumber(credential);

      // Mettre à jour Firestore
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        await ref
            .read(firestoreServiceProvider)
            .updateUser(authState.user.id, {'phoneNumber': newPhone});
        await ref.read(userProvider.notifier).loadUserData(authState.user.id);
      }
      _phoneController.text = newPhone;
      _showSnack('Téléphone mis à jour.');
    } on FirebaseAuthException catch (e) {
      _showSnack('Code invalide: ${e.message}');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(firestoreServiceProvider).updateUser(
        authState.user.id,
        {
          'fullName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
        },
      );
      await ref.read(userProvider.notifier).loadUserData(authState.user.id);
      if (mounted) _showSnack('Profil mis à jour ✅');
    } catch (e) {
      _showSnack('Erreur: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
      );

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;

    return Column(
      children: [
        // ── Titre ───────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSizes.spaceM, AppSizes.spaceL,
              AppSizes.spaceM, AppSizes.spaceS),
          child: const Align(
            alignment: Alignment.centerLeft,
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spaceM),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar ──────────────────────────────
                  Center(
                    child: Stack(
                      children: [
                        // Cercle extérieur glow
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.3),
                                AppColors.primary.withValues(alpha: 0.1),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: AppColors.surfaceVariant,
                            backgroundImage:
                                user?.profileImageUrl.isNotEmpty == true
                                    ? NetworkImage(user!.profileImageUrl)
                                    : null,
                            child: user?.profileImageUrl.isEmpty != false
                                ? Text(
                                    user?.initials ?? '?',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : _pickProfilePhoto,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: _isUploadingPhoto
                                  ? const Padding(
                                      padding: EdgeInsets.all(6),
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.camera_alt,
                                      color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Nom + téléphone sous avatar
                  const SizedBox(height: AppSizes.spaceS),
                  Center(
                    child: Column(children: [
                      Text(user?.fullName ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(user?.phoneNumber ?? '',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: AppSizes.spaceXL),

                  // ── Infos ────────────────────────────────
                  const Text('Informations personnelles',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSizes.spaceM),

                  _ProfileField(
                    controller: _nameController,
                    label: 'Nom complet',
                    icon: Icons.person_outline,
                    validator: (v) => v?.isEmpty == true ? 'Requis' : null,
                  ),
                  const SizedBox(height: AppSizes.spaceM),
                  _ProfileField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    readOnly: true, // ← lecture seule, édition via dialog
                    onEditTap: _changeEmail, // ← bouton crayon
                  ),
                  const SizedBox(height: AppSizes.spaceM),
                  _ProfileField(
                    controller: _phoneController,
                    label: 'Téléphone',
                    icon: Icons.phone_outlined,
                    readOnly: true,
                    onEditTap: _changePhone,
                  ),
                  const SizedBox(height: AppSizes.spaceXL),

                  // ── Carte PMR ────────────────────────────
                  const Text('Carte PMR (Mobilité Réduite)',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSizes.spaceXS),
                  const Text(
                    'Uploadez votre carte d\'invalidité pour accéder aux places PMR.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: AppSizes.spaceM),

                  // Badge PMR
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.spaceM, vertical: AppSizes.spaceS),
                    decoration: BoxDecoration(
                      color: (user?.isSpecialAccessUser == true
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusM),
                      border: Border.all(
                        color: (user?.isSpecialAccessUser == true
                                ? AppColors.success
                                : AppColors.warning)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(children: [
                      Icon(
                        user?.isSpecialAccessUser == true
                            ? Icons.verified
                            : Icons.pending_outlined,
                        color: user?.isSpecialAccessUser == true
                            ? AppColors.success
                            : AppColors.warning,
                        size: 18,
                      ),
                      const SizedBox(width: AppSizes.spaceS),
                      Expanded(
                        child: Text(
                          user?.isSpecialAccessUser == true
                              ? 'Accès PMR activé ✅'
                              : 'Accès PMR non activé — uploadez votre carte',
                          style: TextStyle(
                              color: user?.isSpecialAccessUser == true
                                  ? AppColors.success
                                  : AppColors.warning,
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: AppSizes.spaceM),

                  // Recto / Verso
                  Row(children: [
                    Expanded(
                      child: _CardUploadTile(
                        label: 'Recto',
                        imageUrl: user?.equalityCardPaths.isNotEmpty == true
                            ? user!.equalityCardPaths[0]
                            : null,
                        isLoading: _isUploadingCard,
                        onTap: () => _pickEqualityCard('recto'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spaceM),
                    Expanded(
                      child: _CardUploadTile(
                        label: 'Verso',
                        imageUrl: user?.equalityCardPaths.length == 2
                            ? user!.equalityCardPaths[1]
                            : null,
                        isLoading: _isUploadingCard,
                        onTap: () => _pickEqualityCard('verso'),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSizes.spaceXXL),
                ],
              ),
            ),
          ),
        ),

        // ── Bouton Sauvegarder en bas ─────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spaceM),
            child: SizedBox(
              width: double.infinity,
              height: AppSizes.buttonHeight,
              child: ElevatedButton(
                onPressed: (_isSaving || !_hasChanges) ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Sauvegarder',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final String? Function(String?)? validator;
  final VoidCallback? onEditTap; // ← ajouter

  const _ProfileField(
      {required this.controller,
      required this.label,
      required this.icon,
      this.keyboardType,
      this.readOnly = false,
      this.validator,
      this.onEditTap});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: readOnly ? AppColors.surfaceVariant : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        suffixIcon: onEditTap != null
            ? IconButton(
                icon: const Icon(Icons.edit_outlined, size: 16),
                onPressed: onEditTap,
                color: AppColors.primary,
              )
            : readOnly
                ? const Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textSecondary)
                : null,
      ),
    );
  }
}

class _CardUploadTile extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final bool isLoading;
  final VoidCallback onTap;

  const _CardUploadTile({
    required this.label,
    required this.imageUrl,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
          border: Border.all(
            color: imageUrl != null ? AppColors.success : AppColors.border,
            width: imageUrl != null ? 2 : 1,
          ),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl!), fit: BoxFit.cover)
              : null,
        ),
        child: imageUrl != null
            ? Stack(children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 28),
                      const SizedBox(height: 4),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      const Text('Tap pour changer',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ])
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  isLoading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.upload_outlined,
                          color: AppColors.textSecondary, size: 28),
                  const SizedBox(height: 6),
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const Text('Tap pour uploader',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
                ],
              ),
      ),
    );
  }
}
