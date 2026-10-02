// lib/screens/estudio_biblico/versiculos_guardados_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/versiculo_guardado.dart';
import '../../services/versiculos_guardados_service.dart';
import '../../utils/theme.dart';

class VersiculosGuardadosScreen extends StatefulWidget {
  const VersiculosGuardadosScreen({super.key});

  @override
  State<VersiculosGuardadosScreen> createState() =>
      _VersiculosGuardadosScreenState();
}

class _VersiculosGuardadosScreenState extends State<VersiculosGuardadosScreen> {
  List<VersiculoGuardado> _versiculos = [];
  bool _cargando = true;
  String _filtro = '';

  // Idioma seleccionado para filtrar (es = Español, en = Inglés)
  String _idiomaFiltro = 'es';

  @override
  void initState() {
    super.initState();
    _cargarVersiculos();
  }

  Future<void> _cargarVersiculos() async {
    setState(() => _cargando = true);
    final lista = await VersiculosGuardadosService.obtenerGuardados();
    if (mounted) {
      setState(() {
        _versiculos = lista;
        _cargando = false;
      });
    }
  }

  // ========================================
  // FILTRADO POR IDIOMA Y BÚSQUEDA
  // ========================================
  List<VersiculoGuardado> get _versiculosFiltrados {
    // 1. Filtrar por idioma
    final porIdioma = _versiculos
        .where((v) => v.idioma == _idiomaFiltro)
        .toList();

    // 2. Filtrar por búsqueda de texto (si hay)
    if (_filtro.isEmpty) return porIdioma;

    final q = _filtro.toLowerCase();
    return porIdioma.where((v) =>
        v.texto.toLowerCase().contains(q) ||
        v.cita.toLowerCase().contains(q) ||
        v.notas.any((n) => n.texto.toLowerCase().contains(q))).toList();
  }

  // Contadores por idioma
  int get _totalEspanol =>
      _versiculos.where((v) => v.idioma == 'es').length;

  int get _totalIngles =>
      _versiculos.where((v) => v.idioma == 'en').length;

  // ========================================
  // ELIMINAR
  // ========================================
  Future<void> _eliminarVersiculo(VersiculoGuardado v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar versículo'),
        content: Text('¿Deseas eliminar "${v.cita}" de tus guardados?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF637983)),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await VersiculosGuardadosService.eliminarVersiculo(v.id);
      _cargarVersiculos();
    }
  }

  // ========================================
  // FORMATEAR VERSÍCULO CON NOTAS
  // ========================================
  String _formatearConNotas(VersiculoGuardado v) {
    final buffer = StringBuffer();

    buffer.writeln('"${v.texto}"');
    buffer.writeln('— ${v.cita}');

    if (v.notas.isNotEmpty) {
      buffer.writeln();
      for (int i = 0; i < v.notas.length; i++) {
        buffer.writeln('Nota ${i + 1}: ${v.notas[i].texto}');
        if (i < v.notas.length - 1) {
          buffer.writeln();
        }
      }
    }

    return buffer.toString().trim();
  }

  // ========================================
  // COMPARTIR
  // ========================================
  Future<void> _compartir(VersiculoGuardado v) async {
    if (v.notas.isEmpty) {
      final texto = '"${v.texto}"\n\n— ${v.cita}';
      await Share.share(texto, subject: 'Versículo: ${v.cita}');
      return;
    }

    if (!mounted) return;

    final incluirNotas = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.share, color: Color(0xFF637983)),
            SizedBox(width: 8),
            Text(
              'Compartir versículo',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF637983),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este versículo tiene ${v.notas.length} nota${v.notas.length == 1 ? '' : 's'} guardada${v.notas.length == 1 ? '' : 's'}.',
              style: const TextStyle(fontFamily: 'Sansation', fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Deseas incluir las notas al compartir?',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 13,
                color: Color(0xFF637983),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Solo versículo',
              style: TextStyle(fontFamily: 'Sansation'),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sticky_note_2, size: 16),
            label: const Text(
              'Con notas',
              style: TextStyle(fontFamily: 'Sansation'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF637983),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (incluirNotas == null) return;

    final textoCompartir = incluirNotas
        ? _formatearConNotas(v)
        : '"${v.texto}"\n\n— ${v.cita}';

    await Share.share(textoCompartir, subject: 'Versículo: ${v.cita}');
  }

  // ========================================
  // COPIAR
  // ========================================
  Future<void> _copiar(VersiculoGuardado v) async {
    if (v.notas.isEmpty) {
      await Clipboard.setData(
        ClipboardData(text: '"${v.texto}"\n\n— ${v.cita}'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Versículo copiado al portapapeles')),
        );
      }
      return;
    }

    if (!mounted) return;

    final incluirNotas = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.copy, color: Color(0xFF637983)),
            SizedBox(width: 8),
            Text(
              'Copiar versículo',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF637983),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Este versículo tiene ${v.notas.length} nota${v.notas.length == 1 ? '' : 's'} guardada${v.notas.length == 1 ? '' : 's'}.',
              style: const TextStyle(fontFamily: 'Sansation', fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              '¿Deseas incluir las notas al copiar?',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 13,
                color: Color(0xFF637983),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Solo versículo',
              style: TextStyle(fontFamily: 'Sansation'),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.sticky_note_2, size: 16),
            label: const Text(
              'Con notas',
              style: TextStyle(fontFamily: 'Sansation'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF637983),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );

    if (incluirNotas == null) return;

    final textoCopiar = incluirNotas
        ? _formatearConNotas(v)
        : '"${v.texto}"\n\n— ${v.cita}';

    await Clipboard.setData(ClipboardData(text: textoCopiar));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            incluirNotas
                ? '✅ Versículo con notas copiado'
                : '✅ Versículo copiado al portapapeles',
          ),
        ),
      );
    }
  }

  void _mostrarNotas(VersiculoGuardado v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NotasBottomSheet(
        versiculo: v,
        onUpdate: _cargarVersiculos,
      ),
    );
  }

  // ========================================
  // CAMBIAR IDIOMA
  // ========================================
  void _cambiarIdioma(String lang) {
    setState(() {
      _idiomaFiltro = lang;
      _filtro = '';
    });
  }

  // ========================================
  // BUILD
  // ========================================
  @override
  Widget build(BuildContext context) {
    final lista = _versiculosFiltrados;
    final bool isEnglish = _idiomaFiltro == 'en';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Versículos Guardados',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'OleoScript',
            color: AppTheme.color4,
          ),
        ),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // ========================================
              // SELECTOR DE IDIOMA
              // ========================================
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFA2B0BE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _cambiarIdioma('es'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _idiomaFiltro == 'es'
                                ? const Color(0xFF637983)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Español',
                                style: TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 13,
                                  fontWeight: _idiomaFiltro == 'es'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _idiomaFiltro == 'es'
                                      ? Colors.white
                                      : const Color(0xFF637983),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _idiomaFiltro == 'es'
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : const Color(0xFF637983)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_totalEspanol',
                                  style: TextStyle(
                                    fontFamily: 'Sansation',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _idiomaFiltro == 'es'
                                        ? Colors.white
                                        : const Color(0xFF637983),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _cambiarIdioma('en'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _idiomaFiltro == 'en'
                                ? const Color(0xFF637983)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Inglés',
                                style: TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 13,
                                  fontWeight: _idiomaFiltro == 'en'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _idiomaFiltro == 'en'
                                      ? Colors.white
                                      : const Color(0xFF637983),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _idiomaFiltro == 'en'
                                      ? Colors.white.withValues(alpha: 0.25)
                                      : const Color(0xFF637983)
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$_totalIngles',
                                  style: TextStyle(
                                    fontFamily: 'Sansation',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _idiomaFiltro == 'en'
                                        ? Colors.white
                                        : const Color(0xFF637983),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ========================================
              // BARRA DE BÚSQUEDA
              // ========================================
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF637983)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => _filtro = v),
                  style: const TextStyle(fontFamily: 'Sansation'),
                  decoration: InputDecoration(
                    hintText: isEnglish
                        ? 'Search saved verses...'
                        : 'Buscar en guardados...',
                    hintStyle: TextStyle(
                      fontFamily: 'Sansation',
                      color: Colors.grey.shade500,
                    ),
                    prefixIcon:
                        const Icon(Icons.search, color: Color(0xFF637983)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ========================================
              // CONTADOR
              // ========================================
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF637983),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isEnglish
                          ? '${lista.length} saved'
                          : '${lista.length} guardado${lista.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ========================================
              // LISTA
              // ========================================
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator())
                    : lista.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.bookmark_border,
                                  size: 64,
                                  color: const Color(0xFF637983)
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _filtro.isEmpty
                                      ? (isEnglish
                                          ? 'No saved verses yet'
                                          : 'Aún no has guardado versículos')
                                      : (isEnglish
                                          ? 'No results found'
                                          : 'No se encontraron resultados'),
                                  style: const TextStyle(
                                    fontFamily: 'Sansation',
                                    color: Color(0xFF637983),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _filtro.isEmpty
                                      ? (isEnglish
                                          ? 'Use the ⋮ button to save verses in English'
                                          : 'Usa el botón ⋮ de cada versículo para guardarlo')
                                      : (isEnglish
                                          ? 'Try another search'
                                          : 'Intenta con otra búsqueda'),
                                  style: TextStyle(
                                    fontFamily: 'Sansation',
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: lista.length,
                            itemBuilder: (context, index) {
                              final v = lista[index];
                              return _buildVersiculoCard(v, isEnglish);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========================================
  // TARJETA DE VERSÍCULO
  // ========================================
  Widget _buildVersiculoCard(VersiculoGuardado v, bool isEnglish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF637983).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF637983),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    v.cita,
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (v.notasCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sticky_note_2,
                            size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text(
                          '${v.notasCount}/3',
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Texto del versículo
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              v.texto,
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF192E2F),
              ),
            ),
          ),
          // Acciones
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                _iconBtn(
                  icon: Icons.note_add,
                  tooltip: isEnglish
                      ? 'Notes (${v.notasCount}/3)'
                      : 'Notas (${v.notasCount}/3)',
                  onTap: () => _mostrarNotas(v),
                  color: v.notasCount >= 3
                      ? Colors.orange
                      : const Color(0xFF637983),
                ),
                _iconBtn(
                  icon: Icons.share,
                  tooltip: isEnglish ? 'Share' : 'Compartir',
                  onTap: () => _compartir(v),
                ),
                _iconBtn(
                  icon: Icons.copy,
                  tooltip: isEnglish ? 'Copy' : 'Copiar',
                  onTap: () => _copiar(v),
                ),
                const Spacer(),
                _iconBtn(
                  icon: Icons.delete_outline,
                  tooltip: isEnglish ? 'Delete' : 'Eliminar',
                  onTap: () => _eliminarVersiculo(v),
                  color: const Color(0xFF637983),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = const Color(0xFF637983),
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      tooltip: tooltip,
      onPressed: onTap,
      splashRadius: 20,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
    );
  }
}

// ========================================
// BOTTOM SHEET DE NOTAS (SIN CAMBIOS)
// ========================================
class _NotasBottomSheet extends StatefulWidget {
  final VersiculoGuardado versiculo;
  final VoidCallback onUpdate;

  const _NotasBottomSheet({
    required this.versiculo,
    required this.onUpdate,
  });

  @override
  State<_NotasBottomSheet> createState() => _NotasBottomSheetState();
}

class _NotasBottomSheetState extends State<_NotasBottomSheet> {
  late List<NotaVersiculo> _notas;
  final TextEditingController _nuevoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notas = List.from(widget.versiculo.notas);
  }

  @override
  void dispose() {
    _nuevoController.dispose();
    super.dispose();
  }

  Future<void> _agregarNota() async {
    final texto = _nuevoController.text.trim();
    if (texto.isEmpty) return;

    if (_notas.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('⚠️ Solo puedes tener 3 notas por versículo')),
      );
      return;
    }

    final ok = await VersiculosGuardadosService.agregarNota(
      widget.versiculo.id,
      texto,
    );

    if (ok && mounted) {
      _nuevoController.clear();
      FocusScope.of(context).unfocus();
      final lista = await VersiculosGuardadosService.obtenerGuardados();
      final actualizado = lista.firstWhere(
        (v) => v.id == widget.versiculo.id,
        orElse: () => widget.versiculo,
      );
      setState(() => _notas = List.from(actualizado.notas));
      widget.onUpdate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Nota agregada')),
        );
      }
    }
  }

  Future<void> _editarNota(NotaVersiculo nota) async {
    final controller = TextEditingController(text: nota.texto);
    final nuevoTexto = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar nota'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Escribe tu nota...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoTexto != null && nuevoTexto.isNotEmpty) {
      await VersiculosGuardadosService.actualizarNota(
        widget.versiculo.id,
        nota.id,
        nuevoTexto,
      );
      final lista = await VersiculosGuardadosService.obtenerGuardados();
      final actualizado = lista.firstWhere(
        (v) => v.id == widget.versiculo.id,
        orElse: () => widget.versiculo,
      );
      setState(() => _notas = List.from(actualizado.notas));
      widget.onUpdate();
    }
  }

  Future<void> _eliminarNota(NotaVersiculo nota) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Deseas eliminar esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF637983)),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await VersiculosGuardadosService.eliminarNota(
        widget.versiculo.id,
        nota.id,
      );
      final lista = await VersiculosGuardadosService.obtenerGuardados();
      final actualizado = lista.firstWhere(
        (v) => v.id == widget.versiculo.id,
        orElse: () => widget.versiculo,
      );
      setState(() => _notas = List.from(actualizado.notas));
      widget.onUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFEAE4D5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2, color: Color(0xFF637983)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Notas de ${widget.versiculo.cita}',
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF637983),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _notas.length >= 3
                          ? Colors.orange.withValues(alpha: 0.2)
                          : const Color(0xFF637983).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_notas.length}/3',
                      style: TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _notas.length >= 3
                            ? const Color(0xFF637983)
                            : const Color(0xFF637983),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade300, height: 1),
            Expanded(
              child: _notas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_alt_outlined,
                              size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 8),
                          Text(
                            'Sin notas aún',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Escribe tu primera nota abajo',
                            style: TextStyle(
                              fontFamily: 'Sansation',
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: _notas.length,
                      itemBuilder: (_, i) {
                        final n = _notas[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF637983)
                                  .withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Nota ${i + 1}',
                                    style: const TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF637983),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    _formatFecha(n.fechaModificacion),
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                n.texto,
                                style: const TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 14,
                                  color: Color(0xFF192E2F),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 18),
                                    color: const Color(0xFF637983),
                                    onPressed: () => _editarNota(n),
                                    tooltip: 'Editar',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline, size: 18),
                                    color: const Color(0xFF637983),
                                    onPressed: () => _eliminarNota(n),
                                    tooltip: 'Eliminar',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            if (_notas.length < 3)
              Container(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nuevoController,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(fontFamily: 'Sansation'),
                        decoration: InputDecoration(
                          hintText: 'Escribe una nota...',
                          hintStyle: TextStyle(
                            fontFamily: 'Sansation',
                            color: Colors.grey.shade500,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _agregarNota,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF637983),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.all(14),
                      ),
                      child: const Icon(Icons.send, size: 20),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  border: Border(
                    top: BorderSide(color: Colors.orange.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: const Color(0xFF637983)),
                    const SizedBox(width: 6),
                    Text(
                      'Límite de 3 notas alcanzado',
                      style: TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 12,
                        color: const Color(0xFF637983),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatFecha(DateTime f) {
    return '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year} '
        '${f.hour.toString().padLeft(2, '0')}:${f.minute.toString().padLeft(2, '0')}';
  }
}