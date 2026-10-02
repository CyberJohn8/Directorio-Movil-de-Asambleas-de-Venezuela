import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/iglesia.dart';
import '../../services/data_manager.dart';
import '../../utils/launch_utils.dart';
import 'detalle_asamblea.dart';
import 'mapa_ciudad_screen.dart';

class MapaEstadoScreen extends StatefulWidget {
  final String estado;

  const MapaEstadoScreen({super.key, required this.estado});

  @override
  State<MapaEstadoScreen> createState() => _MapaEstadoScreenState();
}

class _MapaEstadoScreenState extends State<MapaEstadoScreen> {
  final DataManager _dataManager = DataManager();
  List<Iglesia> iglesias = [];
  bool cargando = true;
  bool leyendaExpandida = false;
  double buttonSize = 34.0;
  static const String _buttonSizePreferenceKey = 'mapButtonSize';
  
  static const Size _mapSizeGeneral = Size(900, 800);
  static const Size _mapSizeColombia = Size(1200, 1200);

  // ============================================================================
  // COORDENADAS ESPECÍFICAS POR ASAMBLEA (CON ACENTOS ORIGINALES)
  // ============================================================================
  final Map<String, Map<String, Offset>> coordenadasPorAsamblea = {
    // ========== ESTADO ANZOÁTEGUI (3 asambleas) ==========
    'anzoategui': {
      'Ciudad Orinoco (Soledad)': const Offset(0.77, 0.73),
      'El Tigrito': const Offset(0.48, 0.48),
      'Puerto La Cruz': const Offset(0.32, 0.078),
    },
    
    // ========== ESTADO BARINAS (5 asambleas) ==========
    'barinas': {
      'Barinas': const Offset(0.39, 0.41),
      'Barinitas': const Offset(0.30, 0.36),
      'BARRANCAS': const Offset(0.40, 0.36),
      'Guamito': const Offset(0.36, 0.42),
      'Los Rastrojos': const Offset(0.42, 0.40),
    },
    
    // ========== ESTADO BOLÍVAR (9 asambleas) ==========
    'bolivar': {
      'Barrio Ajuro': const Offset(0.51, 0.19),
      'Caicara del Orinoco': const Offset(0.23, 0.25),
      'Ciudad Bolívar - Cuyuní': const Offset(0.54, 0.19),
      'La Sabanita': const Offset(0.53, 0.23),
      'Puerto Ordaz': const Offset(0.65, 0.14),
      'San Felix': const Offset(0.63, 0.16),
      'Santa Elena de Uairen': const Offset(0.82, 0.71),
      'Santa Rosa del Buey': const Offset(0.72, 0.18),
      'Tumeremo': const Offset(0.86, 0.28),
    },
    
    // ========== ESTADO COJEDES (15 asambleas) ==========
    'cojedes': {
      'Barrio Ezequiel Zamora': const Offset(0.40, 0.30),
      'Barrio Nuevo': const Offset(0.40, 0.22),
      'Buenos Aires': const Offset(0.24, 0.22),
      'El Baul': const Offset(0.60, 0.14),
      'El Muertico': const Offset(0.315, 0.41),
      'El Penitente': const Offset(0.27, 0.32),
      'Genareño': const Offset(0.31, 0.445),
      'La Chorrera': const Offset(0.24, 0.35),
      'Las Vegas': const Offset(0.38, 0.36),
      'Los Colorados': const Offset(0.38, 0.25),
      'Manrique': const Offset(0.47, 0.17),
      'Pueste Onoto': const Offset(0.22, 0.28),
      'San Carlos': const Offset(0.38, 0.28),
      'Tinaco': const Offset(0.47, 0.26),
      'Tinaquillo': const Offset(0.54, 0.08),
    },
  };

  // ============================================================================
  // COORDENADAS PARA CIUDADES DE CARABOBO
  // ============================================================================
  final Map<String, Offset> coordenadasCarabobo = {
    'Alpargatón': const Offset(0.16, 0.14),
    'Bejuma': const Offset(0.19, 0.56),
    'Boqueron': const Offset(0.57, 0.62),
    'Campo Carabobo': const Offset(0.28, 0.74),
    'Canoabo': const Offset(0.16, 0.35),
    'Chirgua': const Offset(0.25, 0.54),
    'Guacara': const Offset(0.57, 0.47),
    'Güigüe': const Offset(0.68, 0.68),
    'Juaniquero': const Offset(0.72, 0.80),
    'La Compañía': const Offset(0.61, 0.44),
    'La Jobera': const Offset(0.12, 0.20),
    'La Lagunita': const Offset(0.30, 0.68),
    'LA SABANA - CANOABO': const Offset(0.12, 0.32),
    'Las Trincheras': const Offset(0.32, 0.36),
    'Los Caracaros': const Offset(0.24, 0.57),
    'Mariara': const Offset(0.78, 0.38),
    'PRIMAVERA': const Offset(0.49, 0.59),
    'San Joaquin': const Offset(0.67, 0.41),
    'San Pablo': const Offset(0.10, 0.14),
    'Tocuyito': const Offset(0.32, 0.58),
    'Morón': const Offset(0.22, 0.14),
    'Puerto Cabello,San Esteban': const Offset(0.48, 0.18),
    'Valencia': const Offset(0.44, 0.50),
  };

  // ============================================================================
  // COORDENADAS PARA TODOS LOS ESTADOS (FALLBACK)
  // ============================================================================
  final Map<String, List<Offset>> posiciones = {
    'amazonas': [const Offset(0.20, 0.12)],
    'anzoategui': [],
    'apure': [
      const Offset(0.82, 0.38), const Offset(0.83, 0.41), const Offset(0.50, 0.50),
      const Offset(0.28, 0.47), const Offset(0.81, 0.35),
    ],
    'aragua': [
      const Offset(0.72, 0.58), const Offset(0.24, 0.24), const Offset(0.20, 0.18),
      const Offset(0.22, 0.20), const Offset(0.24, 0.30), const Offset(0.26, 0.30),
      const Offset(0.34, 0.20), const Offset(0.63, 0.42), const Offset(0.34, 0.24),
      const Offset(0.26, 0.26), const Offset(0.35, 0.28), const Offset(0.0, 0.0),
    ],
    'barinas': [],
    'bolivar': [],
    'carabobo': [],
    'cojedes': [],
    'delta amacuro': [const Offset(0.22, 0.42)],
    'distrito capital': [
      const Offset(0.56, 0.42), const Offset(0.60, 0.44), const Offset(0.46, 0.48),
      const Offset(0.30, 0.56), const Offset(0.48, 0.36),
    ],
    'falcon': [
      const Offset(0.43, 0.24), const Offset(0.93, 0.62), const Offset(0.56, 0.64),
      const Offset(0.46, 0.44), const Offset(0.20, 0.57), const Offset(0.90, 0.55),
      const Offset(0.80, 0.55), const Offset(0.83, 0.56), const Offset(0.82, 0.52),
      const Offset(0.50, 0.35), const Offset(0.62, 0.41), const Offset(0.36, 0.33),
      const Offset(0.66, 0.64), const Offset(0.37, 0.30), const Offset(0.68, 0.40),
      const Offset(0.93, 0.66), const Offset(0.88, 0.58),
    ],
    'guarico': [
      const Offset(0.52, 0.18), const Offset(0.20, 0.12), const Offset(0.22, 0.26),
      const Offset(0.60, 0.38), const Offset(0.78, 0.30),
    ],
    'lara': [
      const Offset(0.70, 0.48), const Offset(0.77, 0.45), const Offset(0.40, 0.45),
      const Offset(0.60, 0.16), const Offset(0.87, 0.36), const Offset(0.74, 0.47),
      const Offset(0.66, 0.18), const Offset(0.66, 0.62), const Offset(0.49, 0.54),
      const Offset(0.82, 0.20), const Offset(0.75, 0.43),
    ],
    'merida': [
      const Offset(0.53, 0.385), const Offset(0.27, 0.34), const Offset(0.47, 0.32),
      const Offset(0.53, 0.35),
    ],
    'miranda': [
      const Offset(0.54, 0.43), const Offset(0.20, 0.54), const Offset(0.31, 0.36),
      const Offset(0.34, 0.36), const Offset(0.22, 0.58), const Offset(0.12, 0.44),
      const Offset(0.26, 0.60), const Offset(0.215, 0.37), const Offset(0.32, 0.46),
      const Offset(0.12, 0.36),
    ],
    'monagas': [const Offset(0.48, 0.28)],
    'nueva esparta': [const Offset(0.84, 0.48)],
    'portuguesa': [
      const Offset(0.59, 0.19), const Offset(0.19, 0.28), const Offset(0.50, 0.65),
      const Offset(0.20, 0.48), const Offset(0.58, 0.66), const Offset(0.64, 0.21),
      const Offset(0.70, 0.24), const Offset(0.64, 0.10), const Offset(0.61, 0.14),
    ],
    'sucre': [
      const Offset(0.44, 0.39), const Offset(0.88, 0.39), const Offset(0.08, 0.61),
      const Offset(0.11, 0.56), const Offset(0.06, 0.52), const Offset(0.09, 0.58),
    ],
    'tachira': [const Offset(0.15, 0.69), const Offset(0.29, 0.69)],
    'trujillo': [
      const Offset(0.80, 0.67), const Offset(0.36, 0.46), const Offset(0.42, 0.53),
      const Offset(0.44, 0.65),
    ],
    'vargas': [const Offset(0.36, 0.40)],
    'yaracuy': [
      const Offset(0.58, 0.32), const Offset(0.36, 0.26), const Offset(0.50, 0.16),
      const Offset(0.40, 0.63), const Offset(0.74, 0.30), const Offset(0.80, 0.38),
      const Offset(0.79, 0.50), const Offset(0.44, 0.46), const Offset(0.34, 0.62),
      const Offset(0.80, 0.315), const Offset(0.56, 0.34), const Offset(0.69, 0.70),
      const Offset(0.46, 0.49), const Offset(0.74, 0.62), const Offset(0.54, 0.36),
      const Offset(0.52, 0.38), const Offset(0.66, 0.76), const Offset(0.75, 0.49),
      const Offset(0.10, 0.69),
    ],
    'zulia': [
      const Offset(0.64, 0.41), const Offset(0.56, 0.33), const Offset(0.59, 0.34),
      const Offset(0.55, 0.27), const Offset(0.42, 0.46), const Offset(0.63, 0.32),
      const Offset(0.57, 0.37), const Offset(0.74, 0.48),
    ],
    // ========== COORDENADAS CORREGIDAS PARA FRONTERA COLOMBIA ========== X - Y
    // Basado en la imagen del mapa correcto (izquierda)
    // Nota: Las coordenadas están ajustadas para un mapa con relación de aspecto 800x1000
    'frontera colombia': [
      // 1 - CALI – MARIANO RAMOS (Abajo izquierda)
      const Offset(0.35, 0.46),
      // 2 - Cartagena (Arriba derecha)
      const Offset(0.40, 0.10),
      // 3 - Caucasia Antioquia (Centro-derecha abajo)
      const Offset(0.395, 0.24),
      // 4 - Macaján (Centro-izquierda arriba)
      const Offset(0.38, 0.16),
      // 5 - La Sierpe (Centro-abajo izquierda)
      const Offset(0.46, 0.22),
      // 6 - Manguitos (Centro)
      const Offset(0.36, 0.22),
      // 7 - Manizales (Centro-derecha abajo)
      const Offset(0.35, 0.37),
      // 8 - Manuela Beltrán - Barranquilla (Arriba izquierda)
      const Offset(0.43, 0.08),
      // 9 - Medellín (Centro-izquierda abajo)
      const Offset(0.35, 0.32),
      // 10 - Pasto (Abajo derecha)
      const Offset(0.33, 0.58),
      // 11 - SINCELEJO – SANTA MARÍA (Centro-derecha arriba)
      const Offset(0.40, 0.18),
      // 12 - Tesoro (Centro-abajo)
      const Offset(0.35, 0.26),
      // 13 - Soacha (Centro)
      const Offset(0.46, 0.39),
      // 14 - Valledupar (Arriba centro)
      const Offset(0.47, 0.10),
      // 15 - VILLA DEL ROSARIO – CUCUTA (Centro-derecha arriba)
      const Offset(0.50, 0.25),
      // 16 - Villavicencio (Centro-izquierda)
      const Offset(0.47, 0.16),
    ],
  };

  // ============================================================================
  // LISTA DE ASAMBLEAS/CUIDADES DE CARABOBO
  // ============================================================================
  final List<String> asambleasCarabobo = [
    'Alpargatón', 'Bejuma', 'Boqueron', 'Campo Carabobo', 'Canoabo', 'Chirgua',
    'Guacara', 'Güigüe', 'Juaniquero', 'La Compañía', 'La Jobera', 'La Lagunita',
    'LA SABANA - CANOABO', 'Las Trincheras', 'Los Caracaros', 'Mariara',
    'PRIMAVERA', 'San Joaquin', 'San Pablo', 'Tocuyito',
    'Morón', 'Puerto Cabello,San Esteban', 'Valencia',
  ];

  // ============================================================================
  // FUNCIONES DE UTILIDAD
  // ============================================================================
  
  String _normalize(String s) {
    return s.trim().toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
  }

  // 👈 NUEVA FUNCIÓN: Normaliza con acentos originales para comparación exacta
  String _normalizeOriginal(String s) {
    return s.trim().toLowerCase();
  }

  List<String> _ciudadesParaMapa(String ciudad) {
    final norm = _normalize(ciudad).replaceAll(' ', '');
    if (norm.contains('puertocabello') && norm.contains('sanesteban')) {
      return ['Puerto Cabello', 'San Esteban'];
    }
    if (norm.contains('puertocabello')) return ['Puerto Cabello'];
    if (norm.contains('sanesteban')) return ['San Esteban'];
    return [ciudad.trim()];
  }

  bool _esCiudadPrincipal(String item) {
    final ciudades = _ciudadesParaMapa(item);
    return ciudades.length > 1 || ciudades.first == 'Valencia' || ciudades.first == 'Morón' || ciudades.first == 'Puerto Cabello';
  }

  bool get _isMobile => MediaQuery.of(context).size.width < 768;
  bool get _isColombia => _normalize(widget.estado) == 'frontera colombia';
  bool get _isMiranda => _normalize(widget.estado) == 'miranda';
  bool get _isCarabobo => _normalize(widget.estado) == 'carabobo';

  Size _getImageSize() {
    if (_isColombia) return _mapSizeColombia;
    return _mapSizeGeneral;
  }

  // ============================================================================
  // OBTENER POSICIÓN CORREGIDA
  // ============================================================================
  Offset _obtenerPosicion(int index, {String? nombreAsamblea}) {
    final estadoNormalizado = _normalize(widget.estado);
    
    // 1. Para Carabobo, usar coordenadas específicas por ciudad
    if (_isCarabobo && nombreAsamblea != null) {
      // Buscar coincidencia exacta primero (con el nombre original)
      if (coordenadasCarabobo.containsKey(nombreAsamblea)) {
        return coordenadasCarabobo[nombreAsamblea]!;
      }
      // Buscar coincidencia normalizada
      final keyNormalized = _normalize(nombreAsamblea);
      for (var entry in coordenadasCarabobo.entries) {
        final entryNormalized = _normalize(entry.key);
        if (keyNormalized == entryNormalized || 
            keyNormalized.contains(entryNormalized) || 
            entryNormalized.contains(keyNormalized)) {
          return entry.value;
        }
      }
    }
    
    // 2. Buscar en coordenadas específicas por asamblea (para otros estados)
    final coordenadasEstado = coordenadasPorAsamblea[estadoNormalizado];
    if (coordenadasEstado != null && nombreAsamblea != null) {
      final key = _normalize(nombreAsamblea);
      // Buscar coincidencia exacta
      for (var entry in coordenadasEstado.entries) {
        final entryNormalized = _normalize(entry.key);
        if (key == entryNormalized) {
          return entry.value;
        }
      }
      // Buscar coincidencia parcial
      for (var entry in coordenadasEstado.entries) {
        final entryNormalized = _normalize(entry.key);
        if (key.contains(entryNormalized) || entryNormalized.contains(key)) {
          return entry.value;
        }
      }
    }
    
    // 3. Para Miranda, verificar si es Distrito Capital
    if (_isMiranda && nombreAsamblea == 'Distrito Capital') {
      return const Offset(0.42, 0.44);
    }
    
    // 4. Usar posiciones por índice de la lista genérica
    final lista = posiciones[estadoNormalizado];
    if (lista != null && lista.isNotEmpty && index < lista.length) {
      return lista[index];
    }
    
    // 5. Fallback: generar posición basada en índice
    return Offset(0.2 + (index * 0.05) % 0.6, 0.2 + (index * 0.04) % 0.6);
  }

  // ============================================================================
  // CICLO DE VIDA
  // ============================================================================
  
  @override
  void initState() {
    super.initState();
    _loadButtonSizePreference();
    _cargarIglesiasEstado();
  }

  Future<void> _loadButtonSizePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedSize = prefs.getDouble(_buttonSizePreferenceKey);
    if (mounted && savedSize != null) {
      setState(() {
        buttonSize = savedSize;
      });
    }
  }

  Future<void> _saveButtonSizePreference(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_buttonSizePreferenceKey, value);
  }

  Future<void> _cargarIglesiasEstado() async {
    setState(() {
      cargando = true;
    });
    
    try {
      await _dataManager.checkDbConnection();
      
      final todasLasIglesias = await _dataManager.getIglesias();
      
      // 👈 CORREGIDO: Normalizar ambos lados para comparación
      final estadoNormalizado = _normalize(widget.estado);
      final lista = todasLasIglesias.where((i) {
        final estadoIglesia = _normalize(i.estado);
        return estadoIglesia == estadoNormalizado;
      }).toList();
      
      // Ordenar por nombre para consistencia
      lista.sort((a, b) => a.asamblea.compareTo(b.asamblea));
      
      if (mounted) {
        setState(() {
          iglesias = lista;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          cargando = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar iglesias: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ============================================================================
  // OTRAS FUNCIONES
  // ============================================================================
  
  String _getImagenEstado(String estado) {
    final estadoNormalizado = _normalize(estado);
    
    final Map<String, String> mapaImagenes = {
      'amazonas': 'Amazonas.png',
      'anzoategui': 'Recurso 41-8.png',
      'apure': 'Apure.png',
      'aragua': 'Recurso 39-8.png',
      'barinas': 'Barinas.png',
      'bolivar': 'Bolivar.png',
      'carabobo': 'Recurso 36-8.png',
      'cojedes': 'Cojedes.png',
      'delta amacuro': 'Recurso 34-8.png',
      'distrito capital': 'Distrito_Capital.png',
      'falcon': 'Recurso 33-8.png',
      'guarico': 'Guarico.png',
      'lara': 'Lara.png',
      'merida': 'Recurso 10-8.png',
      'miranda': 'Miranda.png',
      'monagas': 'Recurso 7-8.png',
      'nueva esparta': 'Nueva Esparta.png',
      'portuguesa': 'Portuguesa.png',
      'sucre': 'Sucre.png',
      'tachira': 'Recurso 2-8.png',
      'trujillo': 'Trujillo.png',
      'vargas': 'Vargas.png',
      'yaracuy': 'Recurso 6-8.png',
      'zulia': 'Recurso 31-8.png',
      'frontera colombia': 'Frontera Colombia.png',
    };
    
    return 'assets/images/estados/${mapaImagenes[estadoNormalizado] ?? 'default.png'}';
  }

  void _onSelectIglesia(Iglesia iglesia) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DetalleAsambleaScreen(iglesia: iglesia)),
    );
  }

  void _onSelectCiudad(String ciudad) {
    final ciudades = _ciudadesParaMapa(ciudad);
    final iglesiasCiudad = iglesias.where((i) {
      final ciudadNormalized = _normalize(i.ciudad);
      return ciudades.any((ciudadFiltro) => ciudadNormalized.contains(_normalize(ciudadFiltro)));
    }).toList();

    final String ciudadTitulo = ciudades.firstWhere(
      (ciudadFiltro) => _normalize(ciudadFiltro).contains('puertocabello') || _normalize(ciudadFiltro).contains('sanesteban') ||
          _normalize(ciudadFiltro).contains('moron') || _normalize(ciudadFiltro).contains('valencia'),
      orElse: () => ciudades.first,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapaCiudadScreen(ciudad: ciudadTitulo, iglesias: iglesiasCiudad)),
    );
  }

  void _navegarADistritoCapital() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapaEstadoScreen(estado: 'Distrito Capital'),
      ),
    );
  }

  void _mostrarDialogoTamanioBotones() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempButtonSize = buttonSize;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE4D5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF637983).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.text_fields, color: Color(0xFF637983), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tamaño de los botones',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(0xFF192E2F),
                                  fontFamily: 'OleoScript',
                                ) ?? const TextStyle(fontSize: 26, color: Color(0xFF192E2F)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Vista previa',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF192E2F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: tempButtonSize,
                            height: tempButtonSize,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Center(
                              child: Text(
                                '1',
                                style: TextStyle(
                                  fontSize: tempButtonSize * 0.45,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Icon(Icons.format_size, size: 20, color: Color(0xFF637983)),
                        const SizedBox(width: 8),
                        Text(
                          '${tempButtonSize.toInt()} px',
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF637983),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempButtonSize,
                      min: 16,
                      max: 60,
                      divisions: 20,
                      label: '${tempButtonSize.toInt()}',
                      activeColor: const Color(0xFF637983),
                      inactiveColor: const Color(0xFF637983).withValues(alpha: 0.3),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempButtonSize = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF637983),
                              side: const BorderSide(color: Color(0xFF637983)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Cancelar', style: TextStyle(fontFamily: 'Sansation', fontSize: 14)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                buttonSize = tempButtonSize;
                              });
                              _saveButtonSizePreference(tempButtonSize);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF637983),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Aplicar', style: TextStyle(fontFamily: 'Sansation', fontSize: 14, fontWeight: FontWeight.normal)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapMarker({required int numero, required VoidCallback onTap, double buttonSize = 34}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            '$numero',
            style: TextStyle(fontSize: buttonSize * 0.45, fontWeight: FontWeight.normal, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildDistritoCapitalMarker({required VoidCallback onTap, double buttonSize = 34}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          color: Colors.black54,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Center(
          child: Text(
            'DC',
            style: TextStyle(
              fontSize: buttonSize * 0.4, 
              fontWeight: FontWeight.normal, 
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================================
  // LEYENDA
  // ============================================================================
  
  Widget _buildLeyendaTabla() {
    final items = _isCarabobo ? asambleasCarabobo : iglesias.map((i) => i.asamblea).toList();
    
    final List<String> displayItems = List.from(items);
    if (_isMiranda) {
      displayItems.add('Distrito Capital');
    }
    
    if (displayItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _isMobile ? 260 : 280,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.95),
        border: Border.all(color: Colors.black26, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => leyendaExpandida = !leyendaExpandida),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF637983), Color(0xFF4A5C66)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFFEAE4D5), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    _isCarabobo ? 'Ciudades' : 'Asambleas',
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFFEAE4D5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    leyendaExpandida ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFEAE4D5),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (leyendaExpandida)
            Container(
              constraints: BoxConstraints(maxHeight: _isMobile ? 300 : 400),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF637983), width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: List.generate(displayItems.length, (index) {
                      final item = displayItems[index];
                      final isDistritoCapital = _isMiranda && item == 'Distrito Capital';
                      final displayText = _isCarabobo
                          ? '${index + 1}. $item'
                          : '${index + 1}. ${item.length > 30 ? '${item.substring(0, 27)}...' : item}';
                      
                      final markerText = isDistritoCapital ? 'DC' : '${index + 1}';
                      
                      return Container(
                        decoration: BoxDecoration(
                          border: index != displayItems.length - 1
                              ? const Border(bottom: BorderSide(color: Color(0xFF637983), width: 0.5))
                              : null,
                        ),
                        child: InkWell(
                          onTap: () {
                            if (isDistritoCapital) {
                              _navegarADistritoCapital();
                            } else if (_isCarabobo) {
                              if (_esCiudadPrincipal(item)) {
                                _onSelectCiudad(item);
                              } else {
                                final iglesia = iglesias.firstWhere(
                                  (i) => i.asamblea.toLowerCase().contains(item.toLowerCase()),
                                  orElse: () => iglesias.first,
                                );
                                _onSelectIglesia(iglesia);
                              }
                            } else {
                              final iglesia = iglesias[index];
                              _onSelectIglesia(iglesia);
                            }
                          },
                          hoverColor: const Color(0xFF637983).withValues(alpha: 0.1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF637983).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      markerText,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF637983),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    displayText,
                                    style: const TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 12,
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFF192E2F),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right, 
                                  size: 16,
                                  color: Color(0xFF637983),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.estado),
        backgroundColor: const Color(0xFF637983),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar datos',
            onPressed: cargando ? null : _cargarIglesiasEstado,
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'Ajustar tamaño de botones',
            onPressed: _mostrarDialogoTamanioBotones,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : iglesias.isEmpty && !_isMiranda
                ? const Center(
                    child: Text(
                      'No hay iglesias registradas en este estado',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final imageSize = _getImageSize();
                      
                      const double horizontalMargin = 16;
                      final availableWidth = constraints.maxWidth - (horizontalMargin * 2);
                      
                      final double scale = math.min(
                        availableWidth / imageSize.width,
                        constraints.maxHeight / imageSize.height,
                      );
                      final double mapWidth = imageSize.width * scale;
                      final double mapHeight = imageSize.height * scale;
                      final String imagePath = _getImagenEstado(widget.estado);

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Center(
                              child: Text(
                                'Botones: ${buttonSize.toInt()} px',
                                style: const TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 10,
                                  color: Color(0xFFEAE4D5),
                                ),
                              ),
                            ),
                          ),
                          
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: horizontalMargin),
                                width: mapWidth,
                                height: mapHeight,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFF637983), width: 3),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: InteractiveViewer(
                                    minScale: 0.8,
                                    maxScale: 4.0,
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Image.asset(
                                            imagePath,
                                            fit: BoxFit.contain,
                                            alignment: Alignment.center,
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Error al cargar $imagePath: $error');
                                              return Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                      SizedBox(height: 8),
                                                      Text('Mapa no disponible', style: TextStyle(color: Colors.grey)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        
                                        // Marcadores para Carabobo
                                        if (_isCarabobo)
                                          ...asambleasCarabobo.asMap().entries.map((entry) {
                                            final int index = entry.key;
                                            final String asamblea = entry.value;
                                            final Offset position = _obtenerPosicion(index, nombreAsamblea: asamblea);
                                            final double markerSize = buttonSize;
                                            return Positioned(
                                              key: ValueKey('asamblea_$asamblea'),
                                              left: position.dx * mapWidth - markerSize / 2,
                                              top: position.dy * mapHeight - markerSize / 2,
                                              child: _buildMapMarker(
                                                numero: index + 1,
                                                onTap: () {
                                                  if (_esCiudadPrincipal(asamblea)) {
                                                    _onSelectCiudad(asamblea);
                                                  } else {
                                                    final iglesia = iglesias.firstWhere(
                                                      (i) => i.asamblea.toLowerCase().contains(asamblea.toLowerCase()),
                                                      orElse: () => iglesias.first,
                                                    );
                                                    _onSelectIglesia(iglesia);
                                                  }
                                                },
                                                buttonSize: markerSize,
                                              ),
                                            );
                                          }).toList(),
                                        
                                        // Marcadores para otros estados
                                        if (!_isCarabobo)
                                          ...iglesias.asMap().entries.map((entry) {
                                            final int index = entry.key;
                                            final Iglesia iglesia = entry.value;
                                            final Offset position = _obtenerPosicion(index, nombreAsamblea: iglesia.asamblea);
                                            final double markerSize = buttonSize;
                                            return Positioned(
                                              key: ValueKey('iglesia_${iglesia.id}'),
                                              left: position.dx * mapWidth - markerSize / 2,
                                              top: position.dy * mapHeight - markerSize / 2,
                                              child: _buildMapMarker(
                                                numero: index + 1,
                                                onTap: () => _onSelectIglesia(iglesia),
                                                buttonSize: markerSize,
                                              ),
                                            );
                                          }).toList(),
                                        
                                        // Marcador para Distrito Capital en Miranda
                                        if (_isMiranda)
                                          Positioned(
                                            key: const ValueKey('distrito_capital_marker'),
                                            left: 0.42 * mapWidth - buttonSize / 2,
                                            top: 0.44 * mapHeight - buttonSize / 2,
                                            child: _buildDistritoCapitalMarker(
                                              onTap: _navegarADistritoCapital,
                                              buttonSize: buttonSize,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: _buildLeyendaTabla(),
                            ),
                          ),
                          
                          const SizedBox(height: 4),
                        ],
                      );
                    },
                  ),
      ),
    );
  }
}