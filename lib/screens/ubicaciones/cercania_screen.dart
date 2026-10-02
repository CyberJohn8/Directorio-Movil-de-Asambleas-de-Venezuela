import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';
import '../../models/iglesia.dart';
import '../../services/data_manager.dart';
import '../../widgets/app_drawer.dart';
import '../ubicaciones/detalle_asamblea.dart';

class CercaniaScreen extends StatefulWidget {
  const CercaniaScreen({super.key});

  @override
  State<CercaniaScreen> createState() => _CercaniaScreenState();
}

class _CercaniaScreenState extends State<CercaniaScreen> {
  final DataManager _dataManager = DataManager();
  
  List<Iglesia> iglesiasCercanas = [];
  bool cargando = true;
  String mensaje = 'Obteniendo ubicación...';
  Position? posicionActual;

  int maxResultados = 8;
  double radioBusqueda = 50.0;

  @override
  void initState() {
    super.initState();
    _refrescarCercania();
  }

  Future<void> _refrescarCercania() async {
    setState(() { 
      cargando = true; 
      mensaje = 'Obteniendo ubicación...'; 
    });
    await _obtenerUbicacionYFiltrarIglesias();
  }

  Future<void> _obtenerUbicacionYFiltrarIglesias() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() { 
            mensaje = 'Permisos de ubicación denegados'; 
            cargando = false; 
          });
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() { 
          mensaje = 'Permisos denegados permanentemente'; 
          cargando = false; 
        });
        }
        return;
      }

      posicionActual = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final todasIglesias = await _dataManager.getIglesias();
      
      final iglesiasConCoordenadas = todasIglesias.where((i) => 
        i.coordenadas != null && i.coordenadas!.isNotEmpty
      ).toList();

      final List<Map<String, dynamic>> distancias = [];
      for (var iglesia in iglesiasConCoordenadas) {
        final coords = _parsearCoordenadas(iglesia.coordenadas!);
        if (coords == null) continue;
        final d = _calcularDistancia(posicionActual!, coords[0], coords[1]);
        if (d <= radioBusqueda) distancias.add({'iglesia': iglesia, 'distancia': d});
      }

      distancias.sort((a, b) => (a['distancia'] as double).compareTo(b['distancia'] as double));
      final seleccionadas = distancias.take(min(maxResultados, distancias.length)).map((x) => x['iglesia'] as Iglesia).toList();

      if (mounted) {
        setState(() {
        iglesiasCercanas = seleccionadas;
        cargando = false;
        if (iglesiasCercanas.isEmpty) {
          mensaje = 'No se encontraron iglesias dentro de ${radioBusqueda.toStringAsFixed(0)} km.';
        }
      });
      }
    } catch (e) {
      if (mounted) {
        setState(() { 
        mensaje = 'Error: $e'; 
        cargando = false; 
      });
      }
    }
  }

  List<double>? _parsearCoordenadas(String coordenadas) {
    final parts = coordenadas.split(',');
    if (parts.length == 2) {
      try { 
        return [double.parse(parts[0].trim()), double.parse(parts[1].trim())]; 
      } catch (e) { 
        return null; 
      }
    }
    return null;
  }

  double _calcularDistancia(Position pos1, double lat2, double lon2) {
    const double radioTierra = 6371;
    final double dLat = _gradosARadianes(lat2 - pos1.latitude);
    final double dLon = _gradosARadianes(lon2 - pos1.longitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) + 
                     cos(_gradosARadianes(pos1.latitude)) * 
                     cos(_gradosARadianes(lat2)) * 
                     sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radioTierra * c;
  }

  double _gradosARadianes(double grados) => grados * pi / 180;

  // ========== Cargar detalle completo antes de mostrar la pantalla ==========
  Future<void> _mostrarDetalleAsamblea(Iglesia iglesia) async {
    final detalle = await _obtenerIglesiaCompleta(iglesia.id);
    if (detalle == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el detalle de la iglesia.')),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetalleAsambleaScreen(iglesia: detalle),
        ),
      );
    }
  }

  // Método auxiliar para obtener una iglesia completa
  Future<Iglesia?> _obtenerIglesiaCompleta(int id) async {
    try {
      final todas = await _dataManager.getIglesias();
      return todas.firstWhere(
        (i) => i.id == id,
        orElse: () => throw Exception('Iglesia no encontrada'),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pop(context)
        ),
        title: const Text('Asambleas Cercanas'),
        backgroundColor: const Color(0xFF637983),
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/icons/menu.png', 
                width: 24, 
                height: 24, 
                color: Colors.white
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Panel de configuración
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05), 
                    blurRadius: 8
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '⚙️ Configuración de búsqueda', 
                    style: TextStyle(fontWeight: FontWeight.normal, fontSize: 16)
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    const Icon(Icons.list, size: 20, color: Color(0xFF637983)),
                    const SizedBox(width: 8),
                    const Text('Resultados: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Slider(
                        min: 3, 
                        max: 20, 
                        divisions: 17, 
                        label: maxResultados.toString(), 
                        value: maxResultados.toDouble(), 
                        activeColor: const Color(0xFF637983), 
                        onChanged: (v) => setState(() => maxResultados = v.toInt()), 
                        onChangeEnd: (_) => _refrescarCercania()
                      )
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
                      decoration: BoxDecoration(
                        color: const Color(0xFF637983).withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(20)
                      ), 
                      child: Text(
                        '$maxResultados', 
                        style: const TextStyle(
                          fontWeight: FontWeight.normal, 
                          color: Color(0xFF637983)
                        )
                      )
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.radar, size: 20, color: Color(0xFF637983)),
                    const SizedBox(width: 8),
                    const Text('Radio (km): ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Slider(
                        min: 5, 
                        max: 200, 
                        divisions: 39, 
                        label: radioBusqueda.toStringAsFixed(0), 
                        value: radioBusqueda, 
                        activeColor: const Color(0xFF637983), 
                        onChanged: (v) => setState(() => radioBusqueda = v), 
                        onChangeEnd: (_) => _refrescarCercania()
                      )
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), 
                      decoration: BoxDecoration(
                        color: const Color(0xFF637983).withValues(alpha: 0.1), 
                        borderRadius: BorderRadius.circular(20)
                      ), 
                      child: Text(
                        '${radioBusqueda.toStringAsFixed(0)} km', 
                        style: const TextStyle(
                          fontWeight: FontWeight.normal, 
                          color: Color(0xFF637983)
                        )
                      )
                    ),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, 
                    child: ElevatedButton.icon(
                      onPressed: _refrescarCercania, 
                      icon: const Icon(Icons.refresh, size: 18), 
                      label: const Text('Actualizar cercanía'), 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF637983), 
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 12), 
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)
                        )
                      )
                    )
                  ),
                ],
              ),
            ),
            // Lista de resultados
            Expanded(
              child: cargando
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF637983)), 
                          const SizedBox(height: 20), 
                          Text(mensaje)
                        ]
                      )
                    )
                  : iglesiasCercanas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center, 
                            children: [
                              Icon(Icons.location_off, size: 64, color: Colors.grey[400]), 
                              const SizedBox(height: 16), 
                              Text(mensaje)
                            ]
                          )
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16), 
                          itemCount: iglesiasCercanas.length, 
                          itemBuilder: (context, index) {
                            final iglesia = iglesiasCercanas[index];
                            final coords = _parsearCoordenadas(iglesia.coordenadas ?? '');
                            final distancia = (coords != null && posicionActual != null) 
                                ? _calcularDistancia(posicionActual!, coords[0], coords[1]) 
                                : 0.0;
                            return _buildResultCard(iglesia, distancia, index);
                          }
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Iglesia iglesia, double distancia, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalleAsamblea(iglesia),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40, 
                height: 40, 
                decoration: BoxDecoration(
                  color: const Color(0xFF637983).withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(10)
                ), 
                child: Center(
                  child: Text(
                    '${index + 1}', 
                    style: const TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.normal, 
                      color: Color(0xFF637983)
                    )
                  )
                )
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  children: [
                    Text(
                      iglesia.asamblea, 
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.normal
                      ), 
                      maxLines: 1, 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${iglesia.ciudad}, ${iglesia.estado}', 
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])
                    ),
                  ]
                )
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1), 
                  borderRadius: BorderRadius.circular(20)
                ), 
                child: Row(
                  mainAxisSize: MainAxisSize.min, 
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey), 
                    const SizedBox(width: 4), 
                    Text(
                      '${distancia.toStringAsFixed(1)} km', 
                      style: const TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.w600, 
                        color: Colors.grey
                      )
                    )
                  ]
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}