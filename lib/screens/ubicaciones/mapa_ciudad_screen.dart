import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/iglesia.dart';
import 'detalle_asamblea.dart';

class MapaCiudadScreen extends StatefulWidget {
  final String ciudad;
  final List<Iglesia> iglesias;

  const MapaCiudadScreen({super.key, required this.ciudad, required this.iglesias});

  @override
  State<MapaCiudadScreen> createState() => _MapaCiudadScreenState();
}

class _MapaCiudadScreenState extends State<MapaCiudadScreen> {
  // ========== CONFIGURACIÓN DE LA LEYENDA ==========
  bool leyendaExpandida = false;
  
  // ========== TAMAÑO BASE DEL MAPA ==========
  static const Size _mapSize = Size(900, 600);
  
  // ========== CONTROL DE IMÁGENES ==========
  bool _imagenDisponible = true;
  bool _verificandoImagen = true;

  // ========== CONFIGURACIÓN DE BOTONES/MARCADORES ==========
  static const double _buttonSize = 32;
  static const double _buttonBorderWidth = 2.0;
  double buttonSize = _buttonSize;
  static const String _buttonSizePreferenceKey = 'mapButtonSize';
  
  static const Color _markerColor = Colors.grey;
  static const Color _markerBgColor = Colors.black54;
  
  // ========== POSICIONES DE LAS IGLESIAS POR CIUDAD ==========
  final Map<String, List<Offset>> posicionesPorCiudad = {
    'Moron': [
      const Offset(0.66, 0.31),
      const Offset(0.69, 0.31),
      const Offset(0.71, 0.28),
      const Offset(0.74, 0.25),
    ],
    
    'Puerto Cabello': [
      //1 - 3             
      const Offset(0.22, 0.54),
      const Offset(0.46, 0.19),
      const Offset(0.68, 0.42),
      //4
      const Offset(0.53, 0.18),
      //5
      const Offset(0.45, 0.27),
      //6
      const Offset(0.51, 0.25),
      //7
      const Offset(0.39, 0.21),
      //8
      const Offset(0.20, 0.20),
      //9
      const Offset(0.34, 0.24),
      //10
      const Offset(0.36, 0.18),
      //11
      const Offset(0.30, 0.20),
      //12
      const Offset(0.54, 0.32),
      //13
      const Offset(0.54, 0.50),
    ],

    'Valencia': [
      //1 - 3
      const Offset(0.44, 0.34),
      const Offset(0.43, 0.14),
      const Offset(0.46, 0.44),
      //4 - 6
      const Offset(0.49, 0.36),
      const Offset(0.44, 0.16),
      const Offset(0.55, 0.42),
      //7 - 9
      const Offset(0.36, 0.45),
      const Offset(0.47, 0.15),
      const Offset(0.44, 0.40),
      //10 - 12
      const Offset(0.38, 0.395),
      const Offset(0.55, 0.34),
      const Offset(0.42, 0.38),
      //13 - 15
      const Offset(0.41, 0.44),
      const Offset(0.405, 0.36),
      const Offset(0.53, 0.21),
      //16
      const Offset(0.41, 0.21),
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadButtonSizePreference();
    _verificarImagen();
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

  Future<void> _verificarImagen() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      
      final String rutaImagen = _getImagenCiudad(widget.ciudad);
      print('🔍 Verificando imagen en: $rutaImagen');
      
      try {
        await precacheImage(AssetImage(rutaImagen), context);
        print('✅ Imagen encontrada correctamente');
        if (mounted) {
          setState(() {
            _imagenDisponible = true;
            _verificandoImagen = false;
          });
        }
      } catch (e) {
        print('❌ Error al cargar imagen: $e');
        
        try {
          await DefaultAssetBundle.of(context).load(rutaImagen);
          print('✅ Imagen encontrada mediante DefaultAssetBundle');
          if (mounted) {
            setState(() {
              _imagenDisponible = true;
              _verificandoImagen = false;
            });
          }
        } catch (e2) {
          print('❌ Error definitivo: $e2');
          if (mounted) {
            setState(() {
              _imagenDisponible = false;
              _verificandoImagen = false;
            });
          }
        }
      }
    });
  }

  Map<int, Offset> getPosiciones() {
    final lista = posicionesPorCiudad[_cityKey(widget.ciudad)];
    if (lista != null) {
      final posiciones = <int, Offset>{};
      for (int i = 0; i < widget.iglesias.length && i < lista.length; i++) {
        posiciones[i] = lista[i];
      }
      return posiciones;
    } else {
      final posiciones = <int, Offset>{};
      for (int i = 0; i < widget.iglesias.length; i++) {
        final row = i ~/ 3;
        final col = i % 3;
        posiciones[i] = Offset(0.2 + col * 0.3, 0.2 + row * 0.3);
      }
      return posiciones;
    }
  }

  String _normalize(String texto) {
    return texto.trim().toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  String _cityKey(String ciudad) {
    final norm = _normalize(ciudad).replaceAll(' ', '');
    if (norm.contains('puertocabello')) return 'Puerto Cabello';
    if (norm.contains('sanesteban')) return 'San Esteban';
    if (norm.contains('moron')) return 'Moron';
    return ciudad.trim();
  }

  String _getImagenCiudad(String ciudad) {
    final String ciudadKey = _cityKey(ciudad);
    const Map<String, String> mapaCiudades = {
      'Valencia': 'assets/images/ciudades/valencia.png',
      'Puerto Cabello': 'assets/images/ciudades/puerto_cabello.png',
      'Moron': 'assets/images/ciudades/moron.png',
    };
    return mapaCiudades[ciudadKey] ?? 'assets/images/ciudades/default.png';
  }

  Size _getImageSize(String ciudad) {
    final String ciudadKey = _cityKey(ciudad);
    const Map<String, Size> tamanosImagenes = {
      'Valencia': Size(900, 800),
      'Puerto Cabello': Size(900, 600),
      'Moron': Size(900, 800),
    };
    return tamanosImagenes[ciudadKey] ?? _mapSize;
  }

  Widget _buildMapMarker({
    required int numero,
    required VoidCallback onTap,
    double size = _buttonSize,
    Color color = _markerColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _markerBgColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: color,
            width: _buttonBorderWidth,
          ),
        ),
        child: Center(
          child: Text(
            '$numero',
            style: TextStyle(
              fontSize: size * 0.45,
              fontWeight: FontWeight.normal,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ========== LEYENDA REPARADA - MÁS ESPACIO Y COMPACTA ==========
  Widget _buildLeyendaTabla() {
    if (widget.iglesias.isEmpty) return const SizedBox.shrink();

    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // 👈 Reducido margen vertical
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.95),
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
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14), // 👈 Reducido padding
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
                  const Icon(Icons.location_city, color: Color(0xFFEAE4D5), size: 18), // 👈 Reducido tamaño
                  const SizedBox(width: 6),
                  const Text(
                    'Asambleas',
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 16, // 👈 Reducido tamaño
                      fontWeight: FontWeight.normal,
                      color: Color(0xFFEAE4D5),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    leyendaExpandida ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFFEAE4D5),
                    size: 20, // 👈 Reducido tamaño
                  ),
                ],
              ),
            ),
          ),
          if (leyendaExpandida)
            Container(
              constraints: const BoxConstraints(maxHeight: 380), // 👈 Aumentado para mostrar más
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.all(6), // 👈 Reducido margen
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF637983), width: 1.5), // 👈 Reducido ancho
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: List.generate(widget.iglesias.length, (index) {
                      final iglesia = widget.iglesias[index];
                      final String displayText = iglesia.asamblea.length > 30 
                          ? '${iglesia.asamblea.substring(0, 27)}...' 
                          : iglesia.asamblea;
                      
                      return Container(
                        decoration: BoxDecoration(
                          border: index != widget.iglesias.length - 1
                              ? const Border(
                                  bottom: BorderSide(
                                    color: Color(0xFF637983),
                                    width: 0.5, // 👈 Reducido ancho
                                    style: BorderStyle.solid,
                                  ),
                                )
                              : null,
                        ),
                        child: InkWell(
                          onTap: () => _onSelectIglesia(iglesia),
                          hoverColor: const Color(0xFF637983).withValues(alpha: 0.1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10), // 👈 Reducido padding
                            child: Row(
                              children: [
                                Container(
                                  width: 24, // 👈 Reducido tamaño
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF637983).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 10, // 👈 Reducido tamaño
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF637983),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8), // 👈 Reducido espacio
                                Expanded(
                                  child: Text(
                                    displayText,
                                    style: const TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 12, // 👈 Reducido tamaño
                                      fontWeight: FontWeight.normal,
                                      color: Color(0xFF192E2F),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 16, // 👈 Reducido tamaño
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

  void _onSelectIglesia(Iglesia iglesia) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalleAsambleaScreen(iglesia: iglesia),
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
                              fontSize: 12,
                              color: Colors.grey,
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

  Widget _buildFallbackMap() {
    return Container(
      color: const Color(0xFFEAE4D5),
      child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: const Color(0xFF637983).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Mapa de ${widget.ciudad}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF637983),
                    fontFamily: 'Sansation',
                  ) ?? const TextStyle(fontSize: 26, color: Color(0xFF637983)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Imagen no disponible',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, Offset> posiciones = getPosiciones();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('${widget.ciudad}'),
        backgroundColor: const Color(0xFF637983),
        foregroundColor: Colors.white,
        actions: [
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
        child: widget.iglesias.isEmpty
            ? const Center(
                child: Text(
                  'No hay iglesias registradas en esta ciudad',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final Size imageSize = _getImageSize(widget.ciudad);
                  const double horizontalMargin = 16;
                  final double availableWidth = constraints.maxWidth - (horizontalMargin * 2);
                  
                  final double scale = math.min(
                    availableWidth / imageSize.width,
                    constraints.maxHeight / imageSize.height,
                  );
                  final double mapWidth = imageSize.width * scale;
                  final double mapHeight = imageSize.height * scale;

                  // ========== ESTRUCTURA: MAPA ARRIBA, LEYENDA CON MÁS ESPACIO ==========
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // Indicador de tamaño de botones
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
                      
                      // ========== MAPA - OCUPA EL 50% DEL ESPACIO (reducido) ==========
                      Expanded(
                        flex: 2, // 👈 Reducido de 3 a 2 (40% del espacio)
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: horizontalMargin),
                            width: mapWidth,
                            height: mapHeight,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF637983), width: 3), // 👈 Reducido ancho
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
                                      child: _verificandoImagen
                                          ? const Center(child: CircularProgressIndicator())
                                          : (_imagenDisponible
                                              ? Image.asset(
                                                  _getImagenCiudad(widget.ciudad),
                                                  fit: BoxFit.contain,
                                                  alignment: Alignment.center,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    print('❌ Error en errorBuilder: $error');
                                                    return _buildFallbackMap();
                                                  },
                                                )
                                              : _buildFallbackMap()),
                                    ),
                                    ...widget.iglesias.asMap().entries.map((entry) {
                                      final int index = entry.key;
                                      final Iglesia iglesia = entry.value;
                                      final Offset position = posiciones[index] ?? const Offset(0.5, 0.5);
                                      final double markerSize = buttonSize;
                                      return Positioned(
                                        left: position.dx * mapWidth - markerSize / 2,
                                        top: position.dy * mapHeight - markerSize / 2,
                                        child: _buildMapMarker(
                                          numero: index + 1,
                                          onTap: () => _onSelectIglesia(iglesia),
                                          size: markerSize,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // ========== LEYENDA - CENTRADA CON MÁS ESPACIO (60% del espacio) ==========
                      Expanded(
                        flex: 3, // 👈 Aumentado de 2 a 3 (60% del espacio)
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