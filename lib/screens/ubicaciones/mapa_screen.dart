import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/iglesia.dart';
import '../../services/data_manager.dart';
import '../../widgets/app_drawer.dart';
import 'detalle_asamblea.dart';
import 'mapa_estado_screen.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final DataManager _dataManager = DataManager();
  
  // ==================== VARIABLES DE ESTADO ====================
  final List<String> estados = const [
    'Amazonas', 'Anzoátegui', 'Apure', 'Aragua', 'Barinas', 'Bolívar', 
    'Carabobo', 'Cojedes', 'Delta Amacuro', 'Distrito Capital', 'Falcón', 
    'Guárico', 'Lara', 'Mérida', 'Miranda', 'Monagas', 'Nueva Esparta', 
    'Portuguesa', 'Sucre', 'Táchira', 'Trujillo', 'Vargas', 'Yaracuy', 'Zulia', 'Frontera Colombia'
  ];
  
  List<Iglesia> iglesias = [];
  bool cargandoIglesias = false;
  bool leyendaExpandida = false;
  String? selectedEstado;

  // ==================== MÉTODOS DE NAVEGACIÓN ====================
  
  /// Muestra un diálogo con la lista de todos los estados disponibles
  Future<void> _mostrarEstados() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFEEEFF1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text(
          'Seleccionar Estado',
          style: TextStyle(
            fontFamily: 'Sansation',
            color: Color(0xFF000000),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: estados.length,
            itemBuilder: (context, index) {
              final estado = estados[index];
              return ListTile(
                title: Text(
                  estado,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    color: Color(0xFF000000),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapaEstadoScreen(estado: estado),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cerrar',
              style: TextStyle(
                fontFamily: 'Sansation',
                color: Color(0xFF637983),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo con búsqueda de iglesias
  Future<void> _mostrarIglesias() async {
    setState(() {
      cargandoIglesias = true;
    });

    try {
      final lista = await _dataManager.getIglesias();
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) {
          final TextEditingController filtroController = TextEditingController();
          List<Iglesia> filtradas = lista;

          return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                backgroundColor: const Color(0xFFEEEFF1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                title: const Text(
                  'Buscar Iglesia',
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    color: Color(0xFF000000),
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: filtroController,
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        color: Color(0xFF000000),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Buscar por nombre, ciudad o estado',
                        labelStyle: const TextStyle(
                          fontFamily: 'Sansation',
                          color: Color(0xFF000000),
                        ),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF637983)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        setStateDialog(() {
                          filtradas = lista
                              .where((d) =>
                                  d.asamblea.toLowerCase().contains(value.toLowerCase()) ||
                                  d.ciudad.toLowerCase().contains(value.toLowerCase()) ||
                                  d.estado.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtradas.length,
                        itemBuilder: (context, index) {
                          final iglesia = filtradas[index];
                          return ListTile(
                            title: Text(
                              iglesia.asamblea,
                              style: const TextStyle(
                                fontFamily: 'Sansation',
                                color: Color(0xFF000000),
                              ),
                            ),
                            subtitle: Text(
                              '${iglesia.estado} - ${iglesia.ciudad}',
                              style: const TextStyle(
                                fontFamily: 'Sansation',
                                color: Color(0xFF000000),
                              ),
                            ),
                            onTap: () async {
                              Navigator.pop(context);
                              
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                              
                              final detalle = await _obtenerIglesiaCompleta(iglesia.id);
                              
                              if (mounted) Navigator.pop(context);
                              
                              if (detalle != null && mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetalleAsambleaScreen(
                                      iglesia: detalle,
                                    ),
                                  ),
                                );
                              } else if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No se pudo cargar el detalle completo de la iglesia'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cerrar',
                      style: TextStyle(
                        fontFamily: 'Sansation',
                        color: Color(0xFF637983),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar iglesias: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          cargandoIglesias = false;
        });
      }
    }
  }

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

  // ==================== MAPA INTERACTIVO ====================
  static const Size _mapSize = Size(900, 800);

  final Map<String, Offset> estadoPositions = {
    'Amazonas': const Offset(0.50, 0.75),
    'Anzoátegui': const Offset(0.66, 0.27),
    'Apure': const Offset(0.36, 0.44),
    'Aragua': const Offset(0.46, 0.20),
    'Barinas': const Offset(0.24, 0.35),
    'Bolívar': const Offset(0.74, 0.55),
    'Carabobo': const Offset(0.40, 0.18),
    'Cojedes': const Offset(0.38, 0.26),
    'Delta Amacuro': const Offset(0.88, 0.27),
    'Distrito Capital': const Offset(0.49, 0.18),
    'Falcón': const Offset(0.28, 0.08),
    'Guárico': const Offset(0.50, 0.30),
    'Lara': const Offset(0.28, 0.18),
    'Mérida': const Offset(0.16, 0.34),
    'Miranda': const Offset(0.56, 0.18),
    'Monagas': const Offset(0.77, 0.24),
    'Nueva Esparta': const Offset(0.68, 0.12),
    'Portuguesa': const Offset(0.30, 0.28),
    'Sucre': const Offset(0.74, 0.16),
    'Táchira': const Offset(0.10, 0.38),
    'Trujillo': const Offset(0.22, 0.26),
    'Vargas': const Offset(0.50, 0.14),
    'Yaracuy': const Offset(0.34, 0.18),
    'Zulia': const Offset(0.10, 0.20),
    'Frontera Colombia': const Offset(0.33, 0.75),
  };

  void _onSelectEstado(String estado) {
    selectedEstado = estado;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapaEstadoScreen(estado: estado)),
    );
  }

  // ==================== TABLA DE LEYENDA ====================
  
  Widget _buildLeyendaTabla() {
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
            onTap: () {
              setState(() {
                leyendaExpandida = !leyendaExpandida;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16), // 👈 Reducido padding
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
                  const Icon(Icons.map, color: Color(0xFFEAE4D5), size: 18), // 👈 Reducido tamaño
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Estados de Venezuela',
                      style: TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 16, // 👈 Reducido tamaño
                        fontWeight: FontWeight.normal,
                        color: Color(0xFFEAE4D5),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
              constraints: const BoxConstraints(maxHeight: 350), // 👈 Aumentado para mostrar más
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  margin: const EdgeInsets.all(6), // 👈 Reducido margen
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF637983),
                      width: 1.5, // 👈 Reducido ancho
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < estados.length; i++)
                        _buildFilaLeyenda(
                          numero: i + 1,
                          nombre: estados[i],
                          onTap: () => _onSelectEstado(estados[i]),
                          esUltima: i == estados.length - 1,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilaLeyenda({
    required int numero,
    required String nombre,
    required VoidCallback onTap,
    required bool esUltima,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: esUltima
            ? null
            : const Border(
                bottom: BorderSide(
                  color: Color(0xFF637983),
                  width: 0.5, // 👈 Reducido ancho
                  style: BorderStyle.solid,
                ),
              ),
      ),
      child: InkWell(
        onTap: onTap,
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
                    '$numero',
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
                  nombre,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 13, // 👈 Reducido tamaño
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF192E2F),
                  ),
                  overflow: TextOverflow.ellipsis,
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
  }

  // ==================== CONSTRUCCIÓN DE LA INTERFAZ ====================
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Mapa de Venezuela'),
        backgroundColor: const Color(0xFF637983),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // ========== BOTONES SUPERIORES ==========
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), // 👈 Reducido padding
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ElevatedButton(
                        onPressed: _mostrarEstados,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF637983),
                          foregroundColor: const Color(0xFFEAE4D5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 👈 Reducido padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('Elegir Estado', style: TextStyle(fontSize: 12)), // 👈 Reducido tamaño
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ElevatedButton(
                        onPressed: _mostrarIglesias,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF637983),
                          foregroundColor: const Color(0xFFEAE4D5),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 👈 Reducido padding
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('Elegir Asamblea', style: TextStyle(fontSize: 12)), // 👈 Reducido tamaño
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // ========== MAPA - OCUPA EL 50% DEL ESPACIO (reducido) ==========
            Expanded(
              flex: 2,  // 👈 Reducido de 3 a 2 (40% del espacio)
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const double horizontalMargin = 16;
                  final availableWidth = constraints.maxWidth - (horizontalMargin * 2);
                  final availableHeight = constraints.maxHeight;
                  
                  final scale = math.min(
                    availableWidth / _mapSize.width,
                    availableHeight / _mapSize.height,
                  );
                  final mapWidth = _mapSize.width * scale;
                  final mapHeight = _mapSize.height * scale;

                  return Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: horizontalMargin),
                      width: mapWidth,
                      height: mapHeight,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF637983), width: 2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 4.0,
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/images/mapa.png',
                                fit: BoxFit.fill,
                                width: mapWidth,
                                height: mapHeight,
                              ),
                              ...estadoPositions.entries.map((entry) {
                                final estado = entry.key;
                                final position = entry.value;
                                final itemIndex = estados.indexOf(estado) + 1;

                                return Positioned(
                                  left: position.dx * mapWidth - 18,
                                  top: position.dy * mapHeight - 18,
                                  child: GestureDetector(
                                    onTap: () => _onSelectEstado(estado),
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black54,
                                      child: Text(
                                        '$itemIndex',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // ========== INDICADOR DE CARGA ==========
            if (cargandoIglesias)
              const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: CircularProgressIndicator(),
              ),
            
            // ========== LEYENDA - CENTRADA VERTICALMENTE CON MÁS ESPACIO ==========
            Expanded(
              flex: 3,  // 👈 Aumentado de 2 a 3 (60% del espacio)
              child: Center(
                child: _buildLeyendaTabla(),
              ),
            ),
            
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}