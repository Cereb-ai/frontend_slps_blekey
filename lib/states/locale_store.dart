import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleOption {
  const LocaleOption({
    required this.code,
    required this.locale,
    required this.label,
  });

  final String code;
  final Locale locale;
  final String label;
}

class LocaleStore extends ChangeNotifier {
  LocaleStore._();

  static final LocaleStore instance = LocaleStore._();

  static const String _keyLocaleCode = 'app_locale_code';

  static const List<LocaleOption> options = <LocaleOption>[
    LocaleOption(code: 'en', locale: Locale('en'), label: 'English'),
    LocaleOption(code: 'de', locale: Locale('de'), label: 'Deutsch'),
    LocaleOption(
      code: 'zh_Hant',
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      label: '繁體中文',
    ),
    LocaleOption(
      code: 'zh_Hans',
      locale: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      label: '简体中文',
    ),
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  String _localeCode = 'zh_Hans';

  String get localeCode => _localeCode;

  Locale get locale {
    for (final item in options) {
      if (item.code == _localeCode) {
        return item.locale;
      }
    }
    return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
  }

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_keyLocaleCode);
    if (saved == null || saved.isEmpty) return;
    if (options.any((item) => item.code == saved)) {
      _localeCode = saved;
      notifyListeners();
    }
  }

  Future<void> setLocaleCode(String code) async {
    if (_localeCode == code) return;
    if (!options.any((item) => item.code == code)) return;
    _localeCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocaleCode, code);
  }
}
