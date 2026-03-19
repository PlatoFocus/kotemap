import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_lang.dart';

class S {
  final AppLang lang;
  const S(this.lang);

  // ── Onglets ─────────────────────────────────────────────────────────────────
  String get tabMap => _t('Kat', 'Carte', 'Map');
  String get tabAlerts => _t('Alèt', 'Alertes', 'Alerts');
  String get tabContribute => _t('Kontribiye', 'Contribuer', 'Contribute');
  String get tabProfile => _t('Pwofil', 'Profil', 'Profile');

  // ── Carte ───────────────────────────────────────────────────────────────────
  String get searchHint => _t('Ki kote ou vle ale ?', 'Où voulez-vous aller ?', 'Where do you want to go?');
  String get filterAll => _t('Tout', 'Tout', 'All');
  String get legendBus => _t('Bis', 'Bus', 'Bus');
  String get legendTaptap => _t('Taptap', 'Taptap', 'Taptap');
  String get legendRisk => _t('Zòn riske', 'Zone risque', 'Risk zone');
  String get mapTapHint => _t('Tape pou chwazi destinasyon', 'Touchez pour définir une destination', 'Tap to set destination');

  // ── Itinéraires ─────────────────────────────────────────────────────────────
  String get itinerariesTitle => _t('Chemen IA', 'Itinéraires IA', 'AI Routes');
  String get chooseRoute => _t('Chwazi chemen sa', 'Choisir cet itinéraire', 'Choose this route');
  String get tagFastest => _t('Pi vit', 'Le plus rapide', 'Fastest');
  String get tagSafest => _t('Pi an sekirite', 'Le plus sûr', 'Safest');
  String get tagCheapest => _t('Pi bon mache', 'Le moins cher', 'Cheapest');
  String get options => _t('opsyon', 'options', 'options');
  String get routeMin => _t('min', 'min', 'min');
  String get routeHTG => _t('HTG', 'HTG', 'HTG');

  // ── Station sheet ────────────────────────────────────────────────────────────
  String get goBtn => _t('Ale', 'Aller', 'Go');
  String tarif(int min, int max) =>
      _t('Tarif : $min–$max HTG', 'Tarif : $min–$max HTG', 'Fare: $min–$max HTG');

  // ── Types de transport ───────────────────────────────────────────────────────
  String get typeBus => _t('Bis (konpayi)', 'Bus (compagnie)', 'Bus (company)');
  String get typeTaptap => _t('Taptap (kamyon)', 'Taptap (camionnette)', 'Taptap (pickup)');
  String get typeMoto => _t('Mototaksi', 'Moto-taxi', 'Moto-taxi');

  // ── Sécurité ────────────────────────────────────────────────────────────────
  String get secSafe => _t('An sekirite', 'Sûr', 'Safe');
  String get secModerate => _t('Modere', 'Modéré', 'Moderate');
  String get secDangerous => _t('Danjere', 'Dangereux', 'Dangerous');

  // ── Alertes ──────────────────────────────────────────────────────────────────
  String get alertsTitle => _t('Alèt ak Ensidan', 'Alertes & Incidents', 'Alerts & Incidents');
  String get confirmed => _t('Konfime', 'Confirmé', 'Confirmed');
  String get information => _t('Enfòmasyon', 'Information', 'Information');
  String confirmations(int n) =>
      _t('$n konfirmasyon', '$n confirmations', '$n confirmations');

  // ── Contribution ────────────────────────────────────────────────────────────
  String get back => _t('Tounen', 'Retour', 'Back');
  String get newContrib => _t('Nouvo kontribisyon', 'Nouvelle contribution', 'New contribution');
  String get verifiedContrib => _t('Kontribitè verifye', 'Contributeur vérifié', 'Verified contributor');
  String get contribTypeTitle => _t('Tip kontribisyon', 'Type de contribution', 'Contribution type');
  String get typeNewStation => _t('Nouvo estasyon', 'Nouvelle station', 'New station');
  String get typeFare => _t('Tarif', 'Tarif', 'Fare');
  String get typeIncident => _t('Ensidan', 'Incident', 'Incident');
  String get typeCorrection => _t('Koreksyon', 'Correction', 'Correction');
  String get fieldStationName => _t('Non estasyon', 'Nom de la station', 'Station name');
  String get fieldStationHint => _t('Eks: Estasyon Delmas 33', 'Ex: Station Delmas 33', 'Ex: Delmas 33 Station');
  String get fieldStationPlaceholder => _t('Estasyon Delmas 33', 'Station Delmas 33', 'Delmas 33 Station');
  String get fieldVehicle => _t('Tip transpo', 'Type de véhicule', 'Vehicle type');
  String get fieldSecurity => _t('Nivo sekirite', 'Niveau de sécurité', 'Security level');
  String get gpsSection => _t('Lokalizasyon GPS', 'Localisation GPS', 'GPS Location');
  String get fareSection => _t('Tarif (HTG)', 'Tarif indicatif (HTG)', 'Fare range (HTG)');
  String get fareMin => _t('Minimòm', 'Minimum', 'Minimum');
  String get fareMax => _t('Maksimòm', 'Maximum', 'Maximum');
  String get cancel => _t('Anile', 'Annuler', 'Cancel');
  String get ok => _t('OK', 'OK', 'OK');
  String get submitBtn => _t('Voye kontribisyon', 'Soumettre la contribution', 'Submit contribution');
  String get submitNote => _t(
    '3 kontribitè pral verifye kontribisyon ou anvan li pibliye.',
    'Votre contribution sera validée par 3 contributeurs\navant d\'être publiée sur la carte.',
    'Your contribution will be validated by 3 contributors\nbefore being published on the map.',
  );
  String get successTitle => _t('Kontribisyon voye !', 'Contribution envoyée !', 'Contribution sent!');
  String get successBody => _t(
    '3 kontribitè pral verifye li anvan li pibliye sou kat la.',
    'Votre contribution sera validée par 3 contributeurs avant d\'être publiée sur la carte.',
    'Your contribution will be validated by 3 contributors before being published on the map.',
  );
  String get newContribBtn => _t('Nouvo kontribisyon', 'Nouvelle contribution', 'New contribution');

  // ── Admin / Dashboard ────────────────────────────────────────────────────────
  String get dashTitle => _t('Tablo de bò', 'Tableau de bord', 'Dashboard');
  String get activeStations => _t('Estasyon aktif', 'Stations actives', 'Active stations');
  String get activeUsers => _t('Itilizatè aktif', 'Utilisateurs actifs', 'Active users');
  String get verifiedContributors => _t('Kontribitè verifye', 'Contributeurs vérifiés', 'Verified contributors');
  String get activeIncidents => _t('Ensidan aktif', 'Incidents actifs', 'Active incidents');
  String unconfirmedIncidents(int n) =>
      _t('$n pa konfime', '$n non confirmés', '$n unconfirmed');
  String pendingContributions(int n) =>
      _t('Kontribisyon an atant ($n)', 'Contributions en attente ($n)', 'Pending contributions ($n)');
  String get seeAll => _t('Wè tout', 'Tout voir', 'See all');
  String get securityIncidents => _t('Ensidan sekirite', 'Incidents sécurité', 'Security incidents');
  String get mapLink => _t('Kat', 'Carte', 'Map');
  String get exportBtn => _t('Ekspòte done CSV / JSON', 'Exporter les données CSV / JSON', 'Export data CSV / JSON');
  String get exportSoon => _t('Ekspòtasyon — poko disponib', 'Export CSV/JSON — fonctionnalité à venir', 'Export CSV/JSON — coming soon');
  String get statusPending => _t('An atant', 'En attente', 'Pending');
  String get statusValidated => _t('Valide', 'Validé', 'Validated');
  String get statusToModerate => _t('Pou modere', 'À modérer', 'To moderate');
  String get approveBtn => _t('Aprouve', 'Approuver', 'Approve');
  String get rejectBtn => _t('Rejte', 'Rejeter', 'Reject');
  String get moderationAction => _t('Aksyon modèrasyon', 'Action de modération', 'Moderation action');

  // ── Profil ───────────────────────────────────────────────────────────────────
  String get profileTitle => _t('Pwofil', 'Profil', 'Profile');
  String get verifiedBadge => _t('Kontribitè verifye', 'Contributeur vérifié', 'Verified contributor');
  String get statContribs => _t('Kontribisyon', 'Contributions', 'Contributions');
  String get statValidated => _t('Valide', 'Validées', 'Validated');
  String get statPoints => _t('Pwen', 'Points', 'Points');
  String get menuDashboard => _t('Tablo Admin', 'Dashboard Admin', 'Admin Dashboard');
  String get menuMyContribs => _t('Kontribisyon mwen', 'Mes contributions', 'My contributions');
  String get menuHowTo => _t('Kijan pou kontribiye ?', 'Comment contribuer ?', 'How to contribute?');
  String get menuLogout => _t('Dekonekte', 'Déconnexion', 'Log out');
  String get languageTitle => _t('Lang', 'Langue', 'Language');
  String get logoutTitle => _t('Dekoneksyon', 'Déconnexion', 'Log out');
  String get logoutConfirm => _t(
    'Ou sèten ou vle dekonekte ?',
    'Êtes-vous sûr de vouloir vous déconnecter ?',
    'Are you sure you want to log out?',
  );
  String get howToTitle => _t('Kijan pou kontribiye ?', 'Comment contribuer ?', 'How to contribute?');
  String get howToStep1 => _t(
    '1. Tape "Kontibiye" nan ba anba a',
    '1. Appuyez sur "Contribuer" dans la barre du bas',
    '1. Tap "Contribute" in the bottom bar',
  );
  String get howToStep2 => _t(
    '2. Chwazi tip kontribisyon an',
    '2. Choisissez le type de contribution',
    '2. Choose the contribution type',
  );
  String get howToStep3 => _t(
    '3. Ranpli fòm nan epi voye',
    '3. Remplissez le formulaire et soumettez',
    '3. Fill in the form and submit',
  );
  String get howToNote => _t(
    '3 kontribitè pral valide kontribisyon ou.',
    'Votre contribution sera validée par 3 contributeurs.',
    'Your contribution will be validated by 3 contributors.',
  );

  // ── Thème ────────────────────────────────────────────────────────────────────
  String get themeTitle => _t('Aparans', 'Apparence', 'Appearance');
  String get themeLight => _t('Klè', 'Clair', 'Light');
  String get themeDark => _t('Nwa', 'Sombre', 'Dark');

  // ── Navigation ───────────────────────────────────────────────────────────────
  String get startNavigation =>
      _t('Kòmanse navigasyon', 'Démarrer la navigation', 'Start navigation');
  String get stopNavigation =>
      _t('Kanpe navigasyon', 'Arrêter', 'Stop');
  String get myPosition =>
      _t('Pozisyon mwen', 'Ma position', 'My position');
  String get fromLabel => _t('Depi', 'Depuis', 'From');
  String get changeOrigin =>
      _t('Chanje pwen depa', 'Changer le départ', 'Change start');
  String get arrived =>
      _t('Ou rive !', 'Vous êtes arrivé !', 'You have arrived!');
  String get fetchingRoute =>
      _t('Kalkil chemen...', 'Calcul du trajet...', 'Calculating route...');
  String get routeNotFound =>
      _t('Pa kapab jwenn chemen', 'Itinéraire introuvable', 'Route not found');
  String get searchOriginHint =>
      _t('Ki kote ou prale ?', 'D\'où partez-vous ?', 'Where are you starting?');
  String get continueNavigation =>
      _t('Kontinye tout dwa', 'Continuez tout droit', 'Continue straight');
  String formatDistanceM(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _t(String cr, String fr, String en) => switch (lang) {
        AppLang.creole => cr,
        AppLang.french => fr,
        AppLang.english => en,
      };
}

final stringsProvider = Provider<S>((ref) => S(ref.watch(localeProvider)));
