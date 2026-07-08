/// Données pays pour YSP Smart Parking
class CountryData {
  final String name;
  final String nameFr;
  final String iso;
  final String flag;
  final List<String> cities;

  const CountryData({
    required this.name,
    required this.nameFr,
    required this.iso,
    required this.flag,
    required this.cities,
  });
}

const List<CountryData> kCountries = [
  CountryData(
    name: 'Senegal', nameFr: 'Sénégal', iso: 'SN', flag: '🇸🇳',
    cities: [
      'Dakar', 'Thiès', 'Saint-Louis', 'Kaolack', 'Ziguinchor',
      'Diourbel', 'Tambacounda', 'Kolda', 'Fatick', 'Louga',
      'Matam', 'Kaffrine', 'Kédougou', 'Sédhiou',
    ],
  ),
  CountryData(
    name: 'France', nameFr: 'France', iso: 'FR', flag: '🇫🇷',
    cities: [
      'Paris', 'Lyon', 'Marseille', 'Toulouse', 'Nice',
      'Nantes', 'Strasbourg', 'Montpellier', 'Bordeaux', 'Lille',
    ],
  ),
  CountryData(
    name: "Cote d'Ivoire", nameFr: "Côte d'Ivoire", iso: 'CI', flag: '🇨🇮',
    cities: [
      'Abidjan', 'Bouaké', 'Daloa', 'Korhogo', 'Yamoussoukro',
      'San-Pédro', 'Man', 'Divo', 'Gagnoa',
    ],
  ),
  CountryData(
    name: 'Mali', nameFr: 'Mali', iso: 'ML', flag: '🇲🇱',
    cities: ['Bamako', 'Sikasso', 'Mopti', 'Koutiala', 'Kayes', 'Gao', 'Ségou'],
  ),
  CountryData(
    name: 'Guinea', nameFr: 'Guinée', iso: 'GN', flag: '🇬🇳',
    cities: ['Conakry', 'Nzérékoré', 'Kindia', 'Kankan', 'Labé'],
  ),
  CountryData(
    name: 'Mauritania', nameFr: 'Mauritanie', iso: 'MR', flag: '🇲🇷',
    cities: ['Nouakchott', 'Nouadhibou', 'Rosso', 'Kaédi'],
  ),
  CountryData(
    name: 'Gambia', nameFr: 'Gambie', iso: 'GM', flag: '🇬🇲',
    cities: ['Banjul', 'Serekunda', 'Brikama'],
  ),
  CountryData(
    name: 'Benin', nameFr: 'Bénin', iso: 'BJ', flag: '🇧🇯',
    cities: ['Cotonou', 'Porto-Novo', 'Parakou', 'Abomey'],
  ),
  CountryData(
    name: 'Togo', nameFr: 'Togo', iso: 'TG', flag: '🇹🇬',
    cities: ['Lomé', 'Sokodé', 'Kara', 'Atakpamé'],
  ),
  CountryData(
    name: 'Morocco', nameFr: 'Maroc', iso: 'MA', flag: '🇲🇦',
    cities: ['Casablanca', 'Rabat', 'Marrakech', 'Fès', 'Tanger'],
  ),
  CountryData(
    name: 'Belgium', nameFr: 'Belgique', iso: 'BE', flag: '🇧🇪',
    cities: ['Bruxelles', 'Anvers', 'Gand', 'Liège'],
  ),
  CountryData(
    name: 'Germany', nameFr: 'Allemagne', iso: 'DE', flag: '🇩🇪',
    cities: ['Berlin', 'Munich', 'Hambourg', 'Cologne', 'Francfort'],
  ),
  CountryData(
    name: 'United States', nameFr: 'États-Unis', iso: 'US', flag: '🇺🇸',
    cities: ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Miami'],
  ),
];

CountryData? findCountryByIso(String iso) {
  try {
    return kCountries.firstWhere(
        (c) => c.iso.toUpperCase() == iso.toUpperCase());
  } catch (_) {
    return null;
  }
}
