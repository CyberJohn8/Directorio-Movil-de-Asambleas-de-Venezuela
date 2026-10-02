// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'utils/theme.dart';
import 'utils/config.dart';
import 'utils/api_service.dart';
import 'services/local_database_service.dart';
import 'screens/menu_principal.dart';
import 'screens/ubicaciones/ubicaciones_menu.dart';
import 'screens/ubicaciones/ubicaciones_lista.dart';
import 'screens/ubicaciones/mapa_screen.dart';
import 'screens/ubicaciones/cercania_screen.dart';
import 'screens/ubicaciones/detalle_asamblea.dart';
import 'screens/eventos/eventos_screen.dart';
import 'screens/criptograma/cryptogram_game.dart';
import 'screens/material_literario/material_screen.dart';
import 'screens/estudio_biblico/estudio_screen.dart';
import 'screens/estudio_biblico/biblia_screen.dart' as biblia;  // 👈 Usar alias
import 'screens/estudio_biblico/buscador_biblia.dart' as buscador;  // 👈 Usar alias
import 'screens/quienes_somos.dart';
import 'screens/acerca_de.dart';
import 'screens/escaner/analisis_errores.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kDebugMode) {
    debugPrint('🚀 Iniciando aplicación...');
  }
  
  await Config.initialize();
  
  try {
    await LocalDatabaseService().database;
    if (kDebugMode) {
      debugPrint('✅ Base de datos local inicializada');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ Error inicializando base de datos: $e');
      debugPrint('📦 La aplicación usará respaldos JSON como fallback');
    }
  }
  
  try {
    await ApiService.getIglesias();
    if (kDebugMode) {
      debugPrint('✅ Datos iniciales cargados en caché');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('⚠️ No se pudieron cargar datos iniciales: $e');
    }
  }
  
  runApp(const DirectorioApp());
}

class DirectorioApp extends StatelessWidget {
  const DirectorioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Directorio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MenuPrincipal(),
        '/ubicaciones': (context) => const UbicacionesMenu(),
        '/ubicaciones/lista': (context) => const UbicacionesLista(),
        '/ubicaciones/mapa': (context) => const MapaScreen(),
        '/ubicaciones/cercania': (context) => const CercaniaScreen(),
        '/eventos': (context) => const EventosScreen(),
        '/material': (context) => const MaterialScreen(),
        '/estudio': (context) => const EstudioScreen(),
        '/biblia': (context) => const biblia.BibliaScreen(),  // 👈 Usar el alias
        '/quienes-somos': (context) => const QuienesSomosScreen(),
        '/acerca-de': (context) => const AcercaDeScreen(),
        '/criptograma': (context) => const CryptogramGame(),
        '/analisis-errores': (context) => const AnalisisErroresScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/ubicaciones/detalle') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => DetalleAsambleaScreen(
              iglesia: args?['iglesia'],
            ),
          );
        }
        return null;
      },
    );
  }
}