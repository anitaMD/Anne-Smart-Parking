import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

// Thème
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString('theme_mode') ?? 'system';
    state = switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
  }
}

// Langue
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('fr', 'FR')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('language') ?? 'fr';
    state = lang == 'en' ? const Locale('en', 'US') : const Locale('fr', 'FR');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', locale.languageCode);
  }
}

// Notifications settings
final notifSettingsProvider =
    StateNotifierProvider<NotifSettingsNotifier, NotifSettings>((ref) {
  return NotifSettingsNotifier();
});

class NotifSettings {
  final bool allEnabled;
  final bool remind30min;
  final bool remind10min;
  final bool remindStart;
  final bool remindEnd15min;

  const NotifSettings({
    this.allEnabled = true,
    this.remind30min = true,
    this.remind10min = true,
    this.remindStart = true,
    this.remindEnd15min = true,
  });

  NotifSettings copyWith({
    bool? allEnabled,
    bool? remind30min,
    bool? remind10min,
    bool? remindStart,
    bool? remindEnd15min,
  }) =>
      NotifSettings(
        allEnabled: allEnabled ?? this.allEnabled,
        remind30min: remind30min ?? this.remind30min,
        remind10min: remind10min ?? this.remind10min,
        remindStart: remindStart ?? this.remindStart,
        remindEnd15min: remindEnd15min ?? this.remindEnd15min,
      );
}

class NotifSettingsNotifier extends StateNotifier<NotifSettings> {
  NotifSettingsNotifier() : super(const NotifSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotifSettings(
      allEnabled: prefs.getBool('notif_all') ?? true,
      remind30min: prefs.getBool('notif_30min') ?? true,
      remind10min: prefs.getBool('notif_10min') ?? true,
      remindStart: prefs.getBool('notif_start') ?? true,
      remindEnd15min: prefs.getBool('notif_end15') ?? true,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_all', state.allEnabled);
    await prefs.setBool('notif_30min', state.remind30min);
    await prefs.setBool('notif_10min', state.remind10min);
    await prefs.setBool('notif_start', state.remindStart);
    await prefs.setBool('notif_end15', state.remindEnd15min);
  }

  Future<void> setAll(bool value) async {
    state = state.copyWith(
      allEnabled: value,
      remind30min: value,
      remind10min: value,
      remindStart: value,
      remindEnd15min: value,
    );
    await _save();
  }

  Future<void> toggle({
    bool? remind30min,
    bool? remind10min,
    bool? remindStart,
    bool? remindEnd15min,
  }) async {
    state = state.copyWith(
      remind30min: remind30min,
      remind10min: remind10min,
      remindStart: remindStart,
      remindEnd15min: remindEnd15min,
    );
    // allEnabled = true si au moins un activé
    state = state.copyWith(
      allEnabled: state.remind30min ||
          state.remind10min ||
          state.remindStart ||
          state.remindEnd15min,
    );
    await _save();
  }
}

// ─────────────────────────────────────────────────────────────
// SETTINGS SCREEN
// ─────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final notifs = ref.watch(notifSettingsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Langue ────────────────────────────────────────
          _SettingsSection(
            title: 'Langue',
            icon: Icons.language_outlined,
            children: [
              _SettingsOption(
                label: '🇫🇷  Français',
                selected: locale.languageCode == 'fr',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('fr', 'FR')),
              ),
              _SettingsOption(
                label: '🇬🇧  English',
                selected: locale.languageCode == 'en',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en', 'US')),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceM),

          // ── Notifications ─────────────────────────────────
          _SettingsSection(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            children: [
              // Master toggle
              _SettingsToggle(
                label: 'Toutes les notifications',
                subtitle: 'Activer ou désactiver tous les rappels',
                value: notifs.allEnabled,
                onChanged: (v) =>
                    ref.read(notifSettingsProvider.notifier).setAll(v),
                bold: true,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),

              // Rappels individuels
              _SettingsToggle(
                label: '⏰  30min avant la réservation',
                subtitle: 'Rappel anticipé',
                value: notifs.remind30min && notifs.allEnabled,
                enabled: notifs.allEnabled,
                onChanged: (v) => ref
                    .read(notifSettingsProvider.notifier)
                    .toggle(remind30min: v),
              ),
              _SettingsToggle(
                label: '🚗  10min avant le début de la réservation',
                subtitle: 'Rappel urgent',
                value: notifs.remind10min && notifs.allEnabled,
                enabled: notifs.allEnabled,
                onChanged: (v) => ref
                    .read(notifSettingsProvider.notifier)
                    .toggle(remind10min: v),
              ),
              _SettingsToggle(
                label: '✅  Début de réservation',
                subtitle: 'Quand votre créneau commence',
                value: notifs.remindStart && notifs.allEnabled,
                enabled: notifs.allEnabled,
                onChanged: (v) => ref
                    .read(notifSettingsProvider.notifier)
                    .toggle(remindStart: v),
              ),
              _SettingsToggle(
                label: '⚠️  15min avant la fin',
                subtitle: 'Rappel de fin imminente',
                value: notifs.remindEnd15min && notifs.allEnabled,
                enabled: notifs.allEnabled,
                onChanged: (v) => ref
                    .read(notifSettingsProvider.notifier)
                    .toggle(remindEnd15min: v),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceXXL),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Row(children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSizes.spaceXS),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5)),
        ]),
        const SizedBox(height: AppSizes.spaceS),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSizes.radiusL),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? AppColors.primary : AppColors.textPrimary)),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
          : const Icon(Icons.circle_outlined,
              color: AppColors.border, size: 20),
      onTap: onTap,
      dense: true,
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final bool enabled;
  final bool bold;
  final void Function(bool) onChanged;

  const _SettingsToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color:
                  enabled ? AppColors.textPrimary : AppColors.textSecondary)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: AppColors.primary,
      dense: true,
    );
  }
}
