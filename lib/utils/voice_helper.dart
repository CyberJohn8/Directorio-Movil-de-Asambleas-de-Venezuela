// lib/utils/voice_helper.dart
import 'package:flutter/foundation.dart';

class VoiceHelper {
  /// Idiomas permitidos (español e inglés)
  static const List<String> allowedLanguagePrefixes = ['es', 'en'];

  /// Mapeo de nombres técnicos a nombres amigables
  static const Map<String, String> _voiceNameMap = {
    // Google
    'es-es-x-eed-local': 'Español (España) - Mujer',
    'es-es-x-eed-network': 'Español (España) - Mujer',
    'es-es-x-eea-local': 'Español (España) - Hombre',
    'es-es-x-eea-network': 'Español (España) - Hombre',
    'es-es-x-eeb-local': 'Español (España) - Mujer 2',
    'es-es-x-eeb-network': 'Español (España) - Mujer 2',
    'es-es-x-eec-local': 'Español (España) - Hombre 2',
    'es-es-x-eec-network': 'Español (España) - Hombre 2',
    'es-us-x-esd-local': 'Español (EE.UU.) - Mujer',
    'es-us-x-esd-network': 'Español (EE.UU.) - Mujer',
    'es-us-x-esf-local': 'Español (EE.UU.) - Hombre',
    'es-us-x-esf-network': 'Español (EE.UU.) - Hombre',
    'es-mx-x-ese-local': 'Español (México) - Mujer',
    'es-mx-x-esg-local': 'Español (México) - Hombre',
    'es-ar-x-esa-local': 'Español (Argentina)',
    'es-co-x-esb-local': 'Español (Colombia)',
    'es-cl-x-esb-local': 'Español (Chile)',
    'es-ve-x-esb-local': 'Español (Venezuela)',

    // Microsoft
    'microsoft sabina desktop': 'Español (Microsoft) - Sabina',
    'microsoft helena desktop': 'Español (Microsoft) - Helena',
    'microsoft laura desktop': 'Español (Microsoft) - Laura',
    'microsoft pablo desktop': 'Español (Microsoft) - Pablo',
    'microsoft raul desktop': 'Español (Microsoft) - Raúl',
    'microsoft sabina': 'Español (Microsoft) - Sabina',
    'microsoft helena': 'Español (Microsoft) - Helena',
    'microsoft laura': 'Español (Microsoft) - Laura',
    'microsoft pablo': 'Español (Microsoft) - Pablo',
    'microsoft raul': 'Español (Microsoft) - Raúl',

    // iOS / macOS
    'monica': 'Español (iOS) - Mónica',
    'paulina': 'Español (iOS) - Paulina',
    'jorge': 'Español (iOS) - Jorge',
    'diego': 'Español (iOS) - Diego',
    'angelica': 'Español (iOS) - Angélica',
    'juan': 'Español (iOS) - Juan',
    'marisol': 'Español (iOS) - Marisol',
    'carlos': 'Español (iOS) - Carlos',

    // Inglés
    'en-us-x-sfg-local': 'Inglés (EE.UU.) - Mujer',
    'en-us-x-sfg-network': 'Inglés (EE.UU.) - Mujer',
    'en-us-x-tpf-local': 'Inglés (EE.UU.) - Hombre',
    'en-us-x-tpf-network': 'Inglés (EE.UU.) - Hombre',
    'en-gb-x-gba-local': 'Inglés (Reino Unido) - Mujer',
    'en-gb-x-gbb-local': 'Inglés (Reino Unido) - Hombre',
    'en-au-x-aud-local': 'Inglés (Australia)',
    'en-in-x-end-local': 'Inglés (India)',
    'microsoft david desktop': 'Inglés (Microsoft) - David',
    'microsoft mark desktop': 'Inglés (Microsoft) - Mark',
    'microsoft zira desktop': 'Inglés (Microsoft) - Zira',
    'samantha': 'Inglés (iOS) - Samantha',
    'alex': 'Inglés (iOS) - Alex',
    'karen': 'Inglés (iOS) - Karen',
    'daniel': 'Inglés (iOS) - Daniel',
    'moira': 'Inglés (iOS) - Moira',
    'tessa': 'Inglés (iOS) - Tessa',
  };

  /// Mapeo de códigos de idioma a nombre legible
  static const Map<String, String> _languageNames = {
    'es': 'Español',
    'es-es': 'Español (España)',
    'es-mx': 'Español (México)',
    'es-us': 'Español (EE.UU.)',
    'es-ar': 'Español (Argentina)',
    'es-co': 'Español (Colombia)',
    'es-cl': 'Español (Chile)',
    'es-ve': 'Español (Venezuela)',
    'es-pe': 'Español (Perú)',
    'en': 'Inglés',
    'en-us': 'Inglés (EE.UU.)',
    'en-gb': 'Inglés (Reino Unido)',
    'en-au': 'Inglés (Australia)',
    'en-ca': 'Inglés (Canadá)',
    'en-in': 'Inglés (India)',
    'en-ie': 'Inglés (Irlanda)',
    'en-nz': 'Inglés (Nueva Zelanda)',
    'en-za': 'Inglés (Sudáfrica)',
  };

  /// Verifica si una voz está en español o inglés
  static bool isAllowedVoice(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').toLowerCase();
    if (locale.isEmpty) return false;
    return allowedLanguagePrefixes.any((prefix) => locale.startsWith(prefix));
  }

  /// Filtra y ordena las voces permitidas
  static List<Map<String, String>> filterAndSort(
    List<Map<String, String>> voices,
  ) {
    final filtered = voices.where(isAllowedVoice).toList();

    // Ordenar: primero español, luego inglés
    filtered.sort((a, b) {
      final aLocale = (a['locale'] ?? '').toLowerCase();
      final bLocale = (b['locale'] ?? '').toLowerCase();
      final aEs = aLocale.startsWith('es');
      final bEs = bLocale.startsWith('es');

      if (aEs && !bEs) return -1;
      if (!aEs && bEs) return 1;
      return aLocale.compareTo(bLocale);
    });

    return filtered;
  }

  /// Obtiene un nombre amigable para una voz
  static String getFriendlyName(Map<String, String> voice) {
    final rawName = (voice['name'] ?? '').trim();
    final locale = (voice['locale'] ?? '').toLowerCase();

    // 1. Buscar en el mapa por nombre exacto (lowercase)
    final lowerName = rawName.toLowerCase();
    if (_voiceNameMap.containsKey(lowerName)) {
      return _voiceNameMap[lowerName]!;
    }

    // 2. Buscar coincidencia parcial
    for (final entry in _voiceNameMap.entries) {
      if (lowerName.contains(entry.key) || entry.key.contains(lowerName)) {
        return entry.value;
      }
    }

    // 3. Generar nombre a partir del locale y nombre técnico
    final languageName = _languageNames[locale] ??
        _languageNames[locale.split('-').first] ??
        locale.toUpperCase();

    // Limpiar el nombre técnico
    String cleanName = rawName
        .replaceAll(RegExp(r'[-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Capitalizar palabras
    cleanName = cleanName
        .split(' ')
        .map((w) => w.isEmpty
            ? w
            : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');

    // Detectar género por palabras clave
    final lower = rawName.toLowerCase();
    String genderSuffix = '';
    if (lower.contains('female') ||
        lower.contains('mujer') ||
        lower.contains('woman') ||
        lower.contains('femenina')) {
      genderSuffix = ' - Mujer';
    } else if (lower.contains('male') ||
        lower.contains('hombre') ||
        lower.contains('man') ||
        lower.contains('masculina')) {
      genderSuffix = ' - Hombre';
    }

    // Si el nombre limpio es muy técnico, usar solo el idioma
    if (cleanName.length < 3 ||
        cleanName.toLowerCase() == 'voice' ||
        cleanName.toLowerCase() == 'tts') {
      return '$languageName$genderSuffix';
    }

    return '$languageName - $cleanName$genderSuffix';
  }

  /// Obtiene la etiqueta del idioma (Español / Inglés)
  static String getLanguageLabel(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').toLowerCase();
    if (locale.startsWith('es')) return 'Español';
    if (locale.startsWith('en')) return 'Inglés';
    return 'Otro';
  }

  /// Obtiene un ícono de bandera según el idioma
  static String getFlagEmoji(Map<String, String> voice) {
    final locale = (voice['locale'] ?? '').toLowerCase();
    if (locale.startsWith('es-es')) return '🇪🇸';
    if (locale.startsWith('es-mx')) return '🇲🇽';
    if (locale.startsWith('es-us')) return '🇺🇸';
    if (locale.startsWith('es-ar')) return '🇦🇷';
    if (locale.startsWith('es-co')) return '🇨🇴';
    if (locale.startsWith('es-cl')) return '🇨🇱';
    if (locale.startsWith('es-ve')) return '🇻🇪';
    if (locale.startsWith('es')) return '🇪🇸';
    if (locale.startsWith('en-us')) return '🇺🇸';
    if (locale.startsWith('en-gb')) return '🇬🇧';
    if (locale.startsWith('en-au')) return '🇦🇺';
    if (locale.startsWith('en-ca')) return '🇨🇦';
    if (locale.startsWith('en')) return '🇬🇧';
    return '🌐';
  }

  /// Formatea una voz para mostrarla en un Dropdown
  static String formatForDisplay(Map<String, String> voice) {
    final flag = getFlagEmoji(voice);
    final name = getFriendlyName(voice);
    return '$flag  $name';
  }
}