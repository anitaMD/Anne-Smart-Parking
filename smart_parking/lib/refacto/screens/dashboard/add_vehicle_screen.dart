import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:smart_parking/refacto/core/utils/license_plate_formatter.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/constants/countries_data.dart';
import '../../models/car_brand_model.dart';
import '../../models/vehicle_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../widgets/license_plate_widget.dart';
import '../../widgets/ysp_button.dart';
import '../../widgets/ysp_text_field.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  final VehicleModel? vehicle; // null = ajout, non-null = édition

  const AddVehicleScreen({super.key, this.vehicle});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  CarBrandModel? _selectedBrand;
  final _modelController = TextEditingController();
  final _plateController = TextEditingController();
  final _yearController = TextEditingController();
  String _vehicleType = 'Car';
  bool _isLoading = false;

  // Pays + ville
  CountryData? _selectedCountry;
  String? _selectedCity;

  // Couleur prédéfinie
  String _selectedColor = 'Blanc';

  final List<_TypeOption> _types = const [
    _TypeOption(type: 'Car', icon: Icons.directions_car, label: 'Voiture'),
    _TypeOption(type: 'SUV', icon: Icons.directions_car_filled, label: 'SUV'),
    _TypeOption(type: 'Truck', icon: Icons.local_shipping, label: 'Camion'),
    _TypeOption(type: 'Moto', icon: Icons.two_wheeler, label: 'Moto'),
  ];

  static const List<_ColorOption> _colors = [
    _ColorOption(name: 'Blanc', color: Colors.white),
    _ColorOption(name: 'Noir', color: Colors.black),
    _ColorOption(name: 'Gris', color: Colors.grey),
    _ColorOption(name: 'Argent', color: Color(0xFFC0C0C0)),
    _ColorOption(name: 'Rouge', color: Colors.red),
    _ColorOption(name: 'Bleu', color: Colors.blue),
    _ColorOption(name: 'Vert', color: Colors.green),
    _ColorOption(name: 'Jaune', color: Colors.yellow),
    _ColorOption(name: 'Beige', color: Color(0xFFF5F5DC)),
    _ColorOption(name: 'Marron', color: Color(0xFF795548)),
    _ColorOption(name: 'Orange', color: Colors.orange),
    _ColorOption(name: 'Violet', color: Colors.purple),
  ];

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.vehicle != null) {
      final v = widget.vehicle!;
      _selectedBrand = kCarBrands.firstWhereOrNull(
          (b) => b.name.toLowerCase() == v.brand.toLowerCase());
      _modelController.text = v.modelDetail;
      _selectedColor = v.color;
      _plateController.text = v.licensePlate;
      _yearController.text = v.registrationYear;
      _selectedCountry = findCountryByIso(v.countryIso);
      _selectedCity = v.registrationCity;
      _vehicleType = v.type;
    }
  }

  String get extractedCityIso {
    String cleanPlate = _plateController.text.toUpperCase().trim();
    if (!cleanPlate.contains('-')) {
      // Format: "DKI54444" -> "DKI"
      return cleanPlate.length >= 3 ? cleanPlate.substring(0, 3) : '';
    } else {
      // Format: "DAK-1234-2024" -> "DAK"
      return cleanPlate.split('-').first;
    }
  }
  // ── Prévisualisation de la plaque ─────────────────────────

  VehicleModel get _previewVehicle => VehicleModel(
        id: '',
        brand: _selectedBrand?.name ?? 'Marque',
        modelDetail:
            _modelController.text.isEmpty ? 'Modèle' : _modelController.text,
        color: _selectedColor,
        licensePlate: _plateController.text.isEmpty
            ? 'XX-0000-XX'
            : _plateController.text.toUpperCase(),
        registrationYear: _yearController.text,
        registrationCountry: _selectedCountry?.nameFr ?? '',
        registrationCity: _selectedCity ?? '',
        countryIso: _selectedCountry?.iso ?? 'SN',
        cityIso: extractedCityIso,
        isCurrentlySelected: false,
        type: _vehicleType,
      );

  // ── Sauvegarde ────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBrand == null) {
      _showError('Veuillez sélectionner une marque.');
      return;
    }
    if (_selectedCountry == null) {
      _showError('Veuillez sélectionner un pays.');
      return;
    }

    setState(() => _isLoading = true);

    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    final vehicle = VehicleModel(
      id: '',
      brand: _selectedBrand!.name,
      modelDetail: _modelController.text.trim(),
      color: _selectedColor,
      licensePlate: _plateController.text.trim().toUpperCase(),
      registrationYear: _yearController.text.trim(),
      registrationCountry: _selectedCountry!.nameFr,
      registrationCity: _selectedCity ?? '',
      countryIso: _selectedCountry!.iso,
      cityIso: extractedCityIso,
      isCurrentlySelected: ref.read(userProvider).vehicles.isEmpty,
      type: _vehicleType,
    );

    try {
      if (widget.vehicle != null) {
        await ref.read(firestoreServiceProvider).updateVehicle(
          authState.user.id,
          widget.vehicle!.id,
          {
            'brand': _selectedBrand!.name,
            'modelDetail': _modelController.text.trim(),
            'color': _selectedColor,
            'licensePlate': _plateController.text.trim().toUpperCase(),
            'registrationYear': _yearController.text.trim(),
            'registrationCountry': _selectedCountry!.nameFr,
            'registrationCity': _selectedCity ?? '',
            'countryIso': _selectedCountry!.iso,
            'type': _vehicleType,
          },
        );
        await ref.read(userProvider.notifier).loadUserData(authState.user.id);
// Recharger
        await ref.read(userProvider.notifier).loadUserData(authState.user.id);
      } else {
        // Ajout d'un nouveau véhicule
        await ref
            .read(userProvider.notifier)
            .addVehicle(authState.user.id, vehicle);
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.vehicle != null
                ? 'Véhicule modifié avec succès !'
                : 'Véhicule ajouté avec succès !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Erreur : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.vehicle != null
              ? 'Modifier le véhicule'
              : 'Ajouter un véhicule',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.spaceL),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Aperçu plaque en temps réel ──────────────
              const _SectionHeader(title: 'Aperçu de la plaque'),
              const SizedBox(height: AppSizes.spaceS),
              AnimatedBuilder(
                animation: Listenable.merge([
                  _modelController,
                  _plateController,
                ]),
                builder: (_, __) => LicensePlateWidget(
                  vehicle: _previewVehicle,
                  compact: false,
                ),
              ),
              const SizedBox(height: AppSizes.spaceL),

              // ── Type ──────────────────────────────────────
              const _SectionHeader(title: 'Type de véhicule'),
              const SizedBox(height: AppSizes.spaceS),
              Row(
                children: _types
                    .map((t) => Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(right: AppSizes.spaceXS),
                            child: _TypeCard(
                              option: t,
                              isSelected: _vehicleType == t.type,
                              onTap: () =>
                                  setState(() => _vehicleType = t.type),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSizes.spaceL),

              // ── Marque ────────────────────────────────────
              const _SectionHeader(title: 'Marque'),
              const SizedBox(height: AppSizes.spaceS),
              _BrandPicker(
                selected: _selectedBrand,
                onSelected: (b) => setState(() => _selectedBrand = b),
              ),
              const SizedBox(height: AppSizes.spaceL),

              // ── Modèle ────────────────────────────────────
              const _SectionHeader(title: 'Informations'),
              const SizedBox(height: AppSizes.spaceS),
              YspTextField(
                controller: _modelController,
                label: 'Modèle',
                hint: 'Ex: Classe C, Corolla, Clio...',
                icon: Icons.directions_car_outlined,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Modèle requis' : null,
              ),
              const SizedBox(height: AppSizes.spaceM),

              // ── Couleur — chips ───────────────────────────
              const _SectionHeader(title: 'Couleur'),
              const SizedBox(height: AppSizes.spaceS),
              _ColorPicker(
                selected: _selectedColor,
                colors: _colors,
                onSelected: (c) => setState(() => _selectedColor = c),
              ),
              const SizedBox(height: AppSizes.spaceM),

              // ── Plaque ────────────────────────────────────
              YspTextField(
                controller: _plateController,
                label: "Plaque d'immatriculation",
                hint: 'Ex: DAK-1234-2024',
                icon: Icons.credit_card_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  LicensePlateFormatter(), // Auto-formatage
                  LengthLimitingTextInputFormatter(11), // Max: XXX-XXXX-XXXX
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Plaque requise';
                  if (!LicensePlateUtils.validatePlate(v)) {
                    return 'Format invalide. Ex: DAK-1234-2024';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Mettre à jour la prévisualisation
                  setState(() {});
                },
              ),

              const SizedBox(height: AppSizes.spaceM),

              // ── Année ─────────────────────────────────────
              YspTextField(
                controller: _yearController,
                label: 'Année',
                hint: 'Ex: 2020',
                icon: Icons.calendar_today_outlined,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Année requise';
                  final y = int.tryParse(v);
                  if (y == null || y < 1900 || y > 2030) {
                    return 'Année invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.spaceL),

              // ── Pays — dropdown ───────────────────────────
              const _SectionHeader(title: "Pays d'immatriculation"),
              const SizedBox(height: AppSizes.spaceS),
              _CountryDropdown(
                selected: _selectedCountry,
                onSelected: (c) => setState(() {
                  _selectedCountry = c;
                  _selectedCity = null; // reset ville
                }),
              ),
              const SizedBox(height: AppSizes.spaceM),

              // ── Ville — dropdown (filtrée par pays) ───────
              if (_selectedCountry != null) ...[
                const _SectionHeader(title: 'Ville'),
                const SizedBox(height: AppSizes.spaceS),
                _CityDropdown(
                  country: _selectedCountry!,
                  selected: _selectedCity,
                  onSelected: (city) => setState(() => _selectedCity = city),
                ),
                const SizedBox(height: AppSizes.spaceL),
              ],

              const SizedBox(height: AppSizes.spaceM),

              // ── Bouton ────────────────────────────────────
              _isLoading
                  ? Center(
                      child: SpinKitFadingCircle(
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : YspButton(
                      label: 'Enregistrer le véhicule',
                      onPressed: _save,
                    ),
              const SizedBox(height: AppSizes.spaceL),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Country Dropdown ──────────────────────────────────────────

class _CountryDropdown extends StatelessWidget {
  final CountryData? selected;
  final void Function(CountryData) onSelected;

  const _CountryDropdown({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: DropdownButtonFormField<CountryData>(
        initialValue: selected,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spaceM, vertical: AppSizes.spaceM),
        ),
        hint: const Text('Sélectionner un pays'),
        items: kCountries
            .map((c) => DropdownMenuItem(
                  value: c,
                  child: Row(
                    children: [
                      Text(c.flag, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: AppSizes.spaceS),
                      Text(c.nameFr),
                    ],
                  ),
                ))
            .toList(),
        onChanged: (c) {
          if (c != null) onSelected(c);
        },
        validator: (v) => v == null ? 'Pays requis' : null,
      ),
    );
  }
}

// ── City Dropdown ─────────────────────────────────────────────

class _CityDropdown extends StatelessWidget {
  final CountryData country;
  final String? selected;
  final void Function(String) onSelected;

  const _CityDropdown({
    required this.country,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: DropdownButtonFormField<String>(
        initialValue: selected,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.location_city_outlined),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
              horizontal: AppSizes.spaceM, vertical: AppSizes.spaceM),
        ),
        hint: const Text('Sélectionner une ville'),
        items: country.cities
            .map((city) => DropdownMenuItem(value: city, child: Text(city)))
            .toList(),
        onChanged: (city) {
          if (city != null) onSelected(city);
        },
      ),
    );
  }
}

// ── Color Picker ──────────────────────────────────────────────

class _ColorPicker extends StatelessWidget {
  final String selected;
  final List<_ColorOption> colors;
  final void Function(String) onSelected;

  const _ColorPicker({
    required this.selected,
    required this.colors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.spaceS,
      runSpacing: AppSizes.spaceS,
      children: colors.map((c) {
        final isSelected = selected == c.name;
        return GestureDetector(
          onTap: () => onSelected(c.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spaceM, vertical: AppSizes.spaceXS),
            decoration: BoxDecoration(
              color:
                  isSelected ? c.color.withValues(alpha: 0.15) : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.radiusFull),
              border: Border.all(
                color: isSelected ? c.color : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: c.color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: AppSizes.spaceXS),
                Text(c.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Brand Picker ──────────────────────────────────────────────

class _BrandPicker extends StatelessWidget {
  final CarBrandModel? selected;
  final void Function(CarBrandModel) onSelected;

  const _BrandPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: kCarBrands.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.spaceS),
        itemBuilder: (_, i) {
          final brand = kCarBrands[i];
          final isSelected = selected?.name == brand.name;
          return GestureDetector(
            onTap: () => onSelected(brand),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSizes.radiusM),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    brand.logoPath,
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.directions_car,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceXS),
                  Text(
                    brand.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Type Card ─────────────────────────────────────────────────

class _TypeCard extends StatelessWidget {
  final _TypeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spaceS),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(option.icon,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24),
            const SizedBox(height: 4),
            Text(option.label,
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────

class _TypeOption {
  final String type;
  final IconData icon;
  final String label;
  const _TypeOption(
      {required this.type, required this.icon, required this.label});
}

class _ColorOption {
  final String name;
  final Color color;
  const _ColorOption({required this.name, required this.color});
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.bold));
  }
}
