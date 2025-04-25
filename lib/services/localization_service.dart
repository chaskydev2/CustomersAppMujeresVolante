import 'package:customer/lang/app_ar.dart';
import 'package:customer/lang/app_en.dart';
import 'package:customer/lang/app_es.dart'; // <-- importa español
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  // Idioma predeterminado (ahora español)
  static const locale = Locale('es', 'ES');

  static final locales = [
    const Locale('en'),
    const Locale('ar'),
    const Locale('es'), // <-- añade español a la lista
  ];

  // Claves y sus traducciones
  @override
  Map<String, Map<String, String>> get keys => {
        'en': enUS,
        'ar': arAR,
        'es': esES, // <-- añade el mapa español
      };

  // Cambia el idioma según el código
  void changeLocale(String lang) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.updateLocale(Locale(lang));
    });
  }
}
