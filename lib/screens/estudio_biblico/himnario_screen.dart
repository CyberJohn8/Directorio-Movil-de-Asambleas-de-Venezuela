// lib/screens/himnario/himnario_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/himno.dart';
import '../../models/corito.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme.dart';

// Enum para el tipo de contenido
enum TipoContenido { himnos, coritos }

class HimnarioScreen extends StatefulWidget {
  const HimnarioScreen({super.key});

  @override
  State<HimnarioScreen> createState() => _HimnarioScreenState();
}

class _HimnarioScreenState extends State<HimnarioScreen> {
  // Listas para Himnos
  List<Himno> himnos = [];
  List<Himno> himnosFiltrados = [];
  
  // Listas para Coritos
  List<Corito> coritos = [];
  List<Corito> coritosFiltrados = [];
  
  bool cargando = true;
  double fontSize = 18.0;
  TipoContenido tipoActual = TipoContenido.himnos; // Por defecto: Himnos
  
  // Controladores para búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _cargarContenido();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filtroBusqueda = _searchController.text;
      _filtrarContenido();
    });
  }

  void _filtrarContenido() {
    if (_filtroBusqueda.isEmpty) {
      setState(() {
        if (tipoActual == TipoContenido.himnos) {
          himnosFiltrados = List.from(himnos);
        } else {
          coritosFiltrados = List.from(coritos);
        }
      });
    } else {
      final busquedaLower = _filtroBusqueda.toLowerCase();
      setState(() {
        if (tipoActual == TipoContenido.himnos) {
          himnosFiltrados = himnos.where((item) {
            return item.numero.toString().contains(busquedaLower) ||
                item.primeraLinea.toLowerCase().contains(busquedaLower) ||
                (item.tema?.toLowerCase().contains(busquedaLower) ?? false) ||
                item.letra.toLowerCase().contains(busquedaLower);
          }).toList();
        } else {
          coritosFiltrados = coritos.where((item) {
            return item.numero.toString().contains(busquedaLower) ||
                item.primeraLinea.toLowerCase().contains(busquedaLower) ||
                (item.tema?.toLowerCase().contains(busquedaLower) ?? false) ||
                item.letra.toLowerCase().contains(busquedaLower);
          }).toList();
        }
      });
    }
  }

  Future<void> _cargarContenido() async {
    setState(() => cargando = true);
    
    try {
      // Cargar himnos
      final listaHimnos = await ApiService.getHimnos();
      // Cargar coritos
      final listaCoritos = await ApiService.getCoritos();
      
      if (mounted) {
        setState(() {
          himnos = listaHimnos;
          himnosFiltrados = listaHimnos;
          coritos = listaCoritos;
          coritosFiltrados = listaCoritos;
          cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar contenido: $e')),
        );
      }
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        fontSize = prefs.getDouble('himnarioFontSize') ?? 18.0;
        // Cargar el tipo de contenido guardado
        final tipoGuardado = prefs.getString('himnarioTipo');
        if (tipoGuardado != null) {
          tipoActual = tipoGuardado == 'coritos' 
              ? TipoContenido.coritos 
              : TipoContenido.himnos;
        }
      });
    }
  }

  Future<void> _saveFontSizePreference(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('himnarioFontSize', value);
  }

  Future<void> _saveTipoPreference(TipoContenido tipo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('himnarioTipo', 
      tipo == TipoContenido.coritos ? 'coritos' : 'himnos'
    );
  }

  // Cambiar entre Himnos y Coritos
  void _cambiarTipo(TipoContenido nuevoTipo) {
    if (tipoActual == nuevoTipo) return;
    
    setState(() {
      tipoActual = nuevoTipo;
      _filtroBusqueda = '';
      _searchController.clear();
      _filtrarContenido();
    });
    _saveTipoPreference(nuevoTipo);
  }

  // ========== VENTANA EMERGENTE PARA TAMAÑO DE TEXTO ==========
  void _mostrarDialogoTamanio() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempFontSize = fontSize;
        
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                constraints: const BoxConstraints(maxWidth: 350),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE4D5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF637983).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.text_fields,
                            color: Color(0xFF637983),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tamaño del texto',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: const Color(0xFF192E2F),
                                fontFamily: 'OleoScript',
                              ) ?? const TextStyle(fontSize: 26, color: Color(0xFF192E2F)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Vista previa del tamaño
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Vista previa',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Versiculo de ejemplo',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: tempFontSize,
                              fontWeight: FontWeight.normal,
                              color: const Color(0xFF637983),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Porque de tal manera amo Dios al mundo...',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: tempFontSize * 0.8,
                              color: const Color(0xFF192E2F),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Slider para ajustar tamaño
                    Row(
                      children: [
                        const Icon(Icons.format_size, size: 20, color: Color(0xFF637983)),
                        const SizedBox(width: 8),
                        Text(
                          '${tempFontSize.toInt()}px',
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontWeight: FontWeight.normal,
                            color: Color(0xFF637983),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: tempFontSize,
                      min: 12,
                      max: 32,
                      divisions: 10,
                      label: '${tempFontSize.toInt()}',
                      activeColor: const Color(0xFF637983),
                      inactiveColor: const Color(0xFF637983).withValues(alpha: 0.3),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempFontSize = value;
                        });
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Botones de accion
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF637983),
                              side: const BorderSide(color: Color(0xFF637983)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                fontSize = tempFontSize;
                              });
                              _saveFontSizePreference(tempFontSize);
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF637983),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Aplicar',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
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

  // ========== CONSTRUCCIÓN DEL WIDGET ==========
  @override
  Widget build(BuildContext context) {
    // Obtener el título según el tipo actual
    final String titulo = tipoActual == TipoContenido.himnos ? 'Himnario' : 'Coritos';
    
    // Obtener el conteo de resultados
    final int totalItems = tipoActual == TipoContenido.himnos 
        ? himnos.length 
        : coritos.length;
    final int itemsFiltrados = tipoActual == TipoContenido.himnos 
        ? himnosFiltrados.length 
        : coritosFiltrados.length;
    
    return Scaffold(
      drawer: const AppDrawer(),
      // ===== BARRA SUPERIOR =====
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(titulo),
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
        // 👈 Barra inferior con el interruptor (SIN ICONOS)
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.color6.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Botón para Himnos (SIN ICONO)
                _buildToggleButton(
                  label: 'Himnos',
                  isSelected: tipoActual == TipoContenido.himnos,
                  onTap: () => _cambiarTipo(TipoContenido.himnos),
                ),
                const SizedBox(width: 8),
                // Botón para Coritos (SIN ICONO)
                _buildToggleButton(
                  label: 'Coritos',
                  isSelected: tipoActual == TipoContenido.coritos,
                  onTap: () => _cambiarTipo(TipoContenido.coritos),
                ),
              ],
            ),
          ),
        ),
      ),
      // ===== CUERPO PRINCIPAL =====
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: cargando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // ===== BARRA DE BUSQUEDA Y BOTON TAMAÑO =====
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Campo de búsqueda
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
                                hintText: tipoActual == TipoContenido.himnos
                                    ? 'Buscar himno (numero, titulo, tema o letra)...'
                                    : 'Buscar corito (numero, titulo, tema o letra)...',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFEAE4D5), 
                                  fontSize: 12
                                ),
                                prefixIcon: const Icon(
                                  Icons.search, 
                                  size: 20, 
                                  color: Color(0xFFEAE4D5)
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                suffixIcon: _filtroBusqueda.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.clear, 
                                          size: 18, 
                                          color: Color(0xFFEAE4D5)
                                        ),
                                        onPressed: () => _searchController.clear(),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Boton de tamaño de texto
                        Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            color: const Color(0xFF637983),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.text_fields, 
                              size: 22, 
                              color: Color(0xFFEAE4D5)
                            ),
                            onPressed: _mostrarDialogoTamanio,
                            tooltip: 'Ajustar tamaño del texto',
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contador de resultados
                  if (!cargando && itemsFiltrados > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Mostrando $itemsFiltrados de $totalItems ${tipoActual == TipoContenido.himnos ? "himnos" : "coritos"}',
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  
                  // Lista de contenido
                  Expanded(
                    child: _buildContentList(),
                  ),
                ],
              ),
      ),
    );
  }

  // ========== CONSTRUCTOR DEL BOTÓN TOGGLE (SIN ICONOS) ==========
  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFEAE4D5) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFFEAE4D5) 
                  : const Color(0xFFEAE4D5).withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Sansation',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected 
                  ? const Color(0xFF637983) 
                  : const Color(0xFFEAE4D5),
            ),
          ),
        ),
      ),
    );
  }

  // ========== CONSTRUCTOR DE LA LISTA DE CONTENIDO ==========
  Widget _buildContentList() {
    final bool isEmpty = tipoActual == TipoContenido.himnos
        ? himnosFiltrados.isEmpty
        : coritosFiltrados.isEmpty;
    
    final String tipoTexto = tipoActual == TipoContenido.himnos ? 'himnos' : 'coritos';
    
    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off, 
              size: 64, 
              color: Colors.grey
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron $tipoTexto',
              style: const TextStyle(
                fontFamily: 'Sansation',
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tipoActual == TipoContenido.himnos
          ? himnosFiltrados.length
          : coritosFiltrados.length,
      itemBuilder: (context, index) {
        if (tipoActual == TipoContenido.himnos) {
          final himno = himnosFiltrados[index];
          return _buildHimnoCard(himno);
        } else {
          final corito = coritosFiltrados[index];
          return _buildCoritoCard(corito);
        }
      },
    );
  }

  // ========== TARJETA PARA HIMNO ==========
  Widget _buildHimnoCard(Himno himno) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          '${himno.numero}. ${himno.primeraLinea}',
          style: const TextStyle(
            fontFamily: 'Sansation',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: himno.tema != null && himno.tema!.isNotEmpty
            ? Text(
                himno.tema!,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 12,
                  color: Color(0xFF637983),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              himno.letra,
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: fontSize,
                height: 1.5,
                color: const Color(0xFF192E2F),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (himno.versiculos != null && himno.versiculos!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '📖 ${himno.versiculos}',
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF637983),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const Divider(height: 1),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ========== TARJETA PARA CORITO ==========
  Widget _buildCoritoCard(Corito corito) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          '${corito.numero}. ${corito.primeraLinea}',
          style: const TextStyle(
            fontFamily: 'Sansation',
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: corito.tema != null && corito.tema!.isNotEmpty
            ? Text(
                corito.tema!,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 12,
                  color: Color(0xFF637983),
                ),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              corito.letra,
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: fontSize,
                height: 1.5,
                color: const Color(0xFF192E2F),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (corito.versiculos != null && corito.versiculos!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '📖 ${corito.versiculos}',
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF637983),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const Divider(height: 1),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}