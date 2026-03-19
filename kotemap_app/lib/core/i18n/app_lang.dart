import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppLang { creole, french, english }

extension AppLangExt on AppLang {
  String get code => switch (this) {
        AppLang.creole => 'cr',
        AppLang.french => 'fr',
        AppLang.english => 'en',
      };

  String get label => switch (this) {
        AppLang.creole => 'Kreyòl',
        AppLang.french => 'Français',
        AppLang.english => 'English',
      };

  String get flag => switch (this) {
        AppLang.creole => '🇭🇹',
        AppLang.french => '🇫🇷',
        AppLang.english => '🇬🇧',
      };
}

class LocaleNotifier extends Notifier<AppLang> {
  @override
  AppLang build() => AppLang.french;

  void setLang(AppLang lang) => state = lang;
}

final localeProvider =
    NotifierProvider<LocaleNotifier, AppLang>(LocaleNotifier.new);
