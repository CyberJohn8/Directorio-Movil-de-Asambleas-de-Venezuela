// lib/screens/ubicaciones/ubicaciones_lista.dart
import 'package:flutter/material.dart';
import '../../models/iglesia.dart';
import '../../utils/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme.dart';
import 'detalle_asamblea.dart';

class UbicacionesLista extends StatefulWidget {
  const UbicacionesLista({super.key});

  @override
  State<UbicacionesLista> createState() => _UbicacionesListaState();
}

class _UbicacionesListaState extends State<UbicacionesLista> {
  List<Iglesia> iglesias = [];
  List<Iglesia> iglesiasFiltradas = [];
  bool cargando = true;

  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';
  String _ordenPor = 'asamblea';
  bool _ordenAscendente = true;

  @override
  void initState() {
    super.initState();
    _cargarIglesias();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _filtroBusqueda = _searchController.text);
    _aplicarFiltros();
  }

  Future<void> _cargarIglesias() async {
    setState(() {
      cargando = true;
    });
    
    try {
      final lista = await ApiService.getIglesias();
      
      if (mounted) {
        setState(() {
          iglesias = lista;
          cargando = false;
        });
        _aplicarFiltros();
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

  void _aplicarFiltros() {
    List<Iglesia> resultado = List.from(iglesias);
    
    if (_filtroBusqueda.isNotEmpty) {
      resultado = resultado.where((iglesia) {
        final busquedaLower = _filtroBusqueda.toLowerCase();
        return iglesia.asamblea.toLowerCase().contains(busquedaLower) ||
            iglesia.estado.toLowerCase().contains(busquedaLower) ||
            iglesia.ciudad.toLowerCase().contains(busquedaLower);
      }).toList();
    }
    
    resultado.sort((a, b) {
      int comparacion;
      switch (_ordenPor) {
        case 'asamblea':
          comparacion = a.asamblea.compareTo(b.asamblea);
          break;
        case 'estado':
          comparacion = a.estado.compareTo(b.estado);
          break;
        case 'numero':
          int numA = int.tryParse(a.numero) ?? 0;
          int numB = int.tryParse(b.numero) ?? 0;
          comparacion = numA.compareTo(numB);
          break;
        default:
          comparacion = a.asamblea.compareTo(b.asamblea);
      }
      return _ordenAscendente ? comparacion : -comparacion;
    });
    
    setState(() => iglesiasFiltradas = resultado);
  }

  Future<void> _mostrarDetalleAsamblea(Iglesia iglesia) async {
    final detalle = await ApiService.getIglesiaById(iglesia.id);
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

  String _getEstadoAbreviatura(String estado) {
    final Map<String, String> mapaEstados = {
      'amazonas': 'AMAZ', 'anzoategui': 'ANZO', 'apure': 'APUR', 'aragua': 'ARAG',
      'barinas': 'BARI', 'bolivar': 'BOLI', 'carabobo': 'CARA', 'cojedes': 'COJE',
      'delta amacuro': 'DELT', 'distrito capital': 'DC', 'falcon': 'FALC',
      'guarico': 'GUAR', 'la guaira': 'VARG', 'lara': 'LARA', 'merida': 'MERI',
      'miranda': 'MIRA', 'monagas': 'MONA', 'nueva esparta': 'NE', 'portuguesa': 'PORT',
      'sucre': 'SUCR', 'tachira': 'TACH', 'trujillo': 'TRUJ', 'yaracuy': 'YARA', 'zulia': 'ZULI',
    };
    return mapaEstados[estado.toLowerCase()] ?? estado.toUpperCase().substring(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Búsqueda por Lista'),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: Image.asset(
                'assets/icons/menu.png',
                width: 24,
                height: 24,
                color: AppTheme.color4,
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
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFF637983),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Color(0xFFEAE4D5)),
                        decoration: InputDecoration(
                          hintText: 'Buscar asamblea, estado o ciudad...',
                          hintStyle: const TextStyle(color: Color(0xFFEAE4D5)),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFFEAE4D5)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          suffixIcon: _filtroBusqueda.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFFEAE4D5)),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF637983),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _ordenPor,
                        dropdownColor: const Color(0xFF637983),
                        style: const TextStyle(
                          fontFamily: 'Sansation',
                          color: Color(0xFFEAE4D5),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'asamblea', child: Text('Asamblea A-Z')),
                          DropdownMenuItem(value: 'asamblea_desc', child: Text('Asamblea Z-A')),
                          DropdownMenuItem(value: 'estado', child: Text('Estado A-Z')),
                          DropdownMenuItem(value: 'estado_desc', child: Text('Estado Z-A')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              if (value == 'asamblea_desc') {
                                _ordenPor = 'asamblea';
                                _ordenAscendente = false;
                              } else if (value == 'estado_desc') {
                                _ordenPor = 'estado';
                                _ordenAscendente = false;
                              } else {
                                _ordenPor = value;
                                _ordenAscendente = true;
                              }
                            });
                            _aplicarFiltros();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Botón de refrescar
            if (!cargando)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: _cargarIglesias,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refrescar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF637983),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Tabla de resultados
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : iglesiasFiltradas.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No se encontraron asambleas'),
                            ],
                          ),
                        )
                      : Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Encabezado de la tabla
                              Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF637983), Color(0xFF637983)],
                                  ),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 6, child: Text('Asamblea', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEAE4D5), fontSize: 14, fontWeight: FontWeight.normal))),
                                      Expanded(flex: 3, child: Text('Ciudad', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEAE4D5), fontSize: 14, fontWeight: FontWeight.normal))),
                                      Expanded(flex: 3, child: Text('Estado', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEAE4D5), fontSize: 14, fontWeight: FontWeight.normal))),
                                      Expanded(flex: 2, child: Text('Ver', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFEAE4D5), fontSize: 14, fontWeight: FontWeight.normal))),
                                    ],
                                  ),
                                ),
                              ),
                              // Cuerpo de la tabla
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFF637983), width: 2),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: iglesiasFiltradas.map((iglesia) {
                                        return Container(
                                          decoration: const BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(color: Color(0xFF637983), width: 1),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Row(
                                              children: [
                                                // Columna Asamblea
                                                Expanded(
                                                  flex: 6,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                                    decoration: const BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(color: Color(0xFF637983), width: 1),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      iglesia.asamblea,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                                // Columna Ciudad
                                                Expanded(
                                                  flex: 3,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                                    decoration: const BoxDecoration(
                                                      border: Border(
                                                        right: BorderSide(color: Color(0xFF637983), width: 1),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      iglesia.ciudad,
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                                // Columna Estado
                                                Expanded(
                                                  flex: 3,
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                                    child: Text(
                                                      _getEstadoAbreviatura(iglesia.estado),
                                                      textAlign: TextAlign.center,
                                                      style: const TextStyle(fontSize: 12),
                                                    ),
                                                  ),
                                                ),
                                                // Columna Ver
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: IconButton(
                                                      icon: const Icon(Icons.info_outline, size: 20),
                                                      color: const Color(0xFFEAE4D5),
                                                      onPressed: () => _mostrarDetalleAsamblea(iglesia),
                                                      tooltip: 'Ver detalles',
                                                      style: IconButton.styleFrom(
                                                        backgroundColor: const Color(0xFF637983),
                                                        padding: const EdgeInsets.all(8),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(5),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
            
            if (!cargando && iglesiasFiltradas.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Mostrando ${iglesiasFiltradas.length} de ${iglesias.length} asambleas',
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}