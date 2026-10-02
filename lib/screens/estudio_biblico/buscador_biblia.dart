// lib/screens/estudio_biblico/buscador_biblia.dart
import 'package:flutter/material.dart';
import '../../models/biblia.dart';
import '../../services/biblia_service.dart';
import '../../utils/theme.dart';
import '../../widgets/app_drawer.dart';

class BuscadorBibliaScreen extends StatefulWidget {
  const BuscadorBibliaScreen({super.key});

  @override
  State<BuscadorBibliaScreen> createState() => _BuscadorBibliaScreenState();
}

class _BuscadorBibliaScreenState extends State<BuscadorBibliaScreen> {
  // ========== CONTROLADORES Y VARIABLES ==========
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<BibliaVerse> searchResults = [];
  bool isSearching = false;
  bool cargando = true;

  // Idioma de búsqueda (es = Español, en = Inglés)
  String _searchLanguage = 'es';

  // Cache de libros por idioma
  Map<String, List<BibliaBook>> _booksCache = {};

  // ========== INICIALIZACIÓN ==========
  @override
  void initState() {
    super.initState();
    _cargarLibros();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ========== CARGA DE LIBROS ==========
  Future<void> _cargarLibros() async {
    try {
      // Guardar idioma actual del servicio
      final idiomaOriginal = BibliaService.currentLanguage;

      // Cargar libros en español
      await BibliaService.setLanguage('es');
      _booksCache['es'] = await BibliaService.getBooks();

      // Cargar libros en inglés
      await BibliaService.setLanguage('en');
      _booksCache['en'] = await BibliaService.getBooks();

      // Restaurar idioma original
      await BibliaService.setLanguage(idiomaOriginal);

      if (mounted) {
        setState(() => cargando = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar libros: $e')),
        );
      }
    }
  }

  // ========== BÚSQUEDA ==========
  Future<void> _buscar() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un término para buscar')),
      );
      return;
    }

    setState(() {
      isSearching = true;
      searchResults = [];
    });

    try {
      // Guardar idioma actual del servicio
      final idiomaOriginal = BibliaService.currentLanguage;

      // Cambiar al idioma de búsqueda
      await BibliaService.setLanguage(_searchLanguage);

      // Obtener libros del idioma seleccionado
      final libros = _booksCache[_searchLanguage] ?? [];
      final List<BibliaVerse> resultados = [];
      final String queryLower = query.toLowerCase();

      // Buscar en todos los libros y capítulos
      for (final book in libros) {
        for (int chapter = 1; chapter <= book.chapters; chapter++) {
          try {
            final verses = await BibliaService.getChapter(book, chapter);
            for (final verse in verses) {
              if (verse.text.toLowerCase().contains(queryLower)) {
                resultados.add(verse.copyWith(
                  bookId: book.id,
                  chapter: chapter,
                ));
              }
            }
          } catch (e) {
            // Continuar con el siguiente capítulo si falla
          }
        }

        // Limitar a 500 resultados para no sobrecargar
        if (resultados.length >= 500) break;
      }

      // Restaurar idioma original
      await BibliaService.setLanguage(idiomaOriginal);

      // Ordenar resultados
      resultados.sort((a, b) {
        if (a.bookId != b.bookId) return a.bookId.compareTo(b.bookId);
        if (a.chapter != b.chapter) return a.chapter.compareTo(b.chapter);
        return a.verse.compareTo(b.verse);
      });

      if (mounted) {
        setState(() {
          searchResults = resultados;
          isSearching = false;
        });

        if (resultados.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se encontraron resultados'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Se encontraron ${resultados.length} resultados'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la búsqueda: $e')),
        );
      }
    }
  }

  // ========== CAMBIAR IDIOMA DE BÚSQUEDA ==========
  void _cambiarIdioma(String lang) {
    setState(() {
      _searchLanguage = lang;
      searchResults = [];
    });
  }

  // ========== OBTENER NOMBRE DEL LIBRO ==========
  String _getBookName(int bookId) {
    final libros = _booksCache[_searchLanguage] ?? [];
    final book = libros.firstWhere(
      (b) => b.id == bookId,
      orElse: () => libros.isNotEmpty ? libros.first : BibliaBook(
        id: 0, key: '', title: '', shortTitle: '', abbr: '',
        category: '', testament: '', chapters: 0, verses: 0,
      ),
    );
    return book.shortTitle;
  }

  // ========== BUILD ==========
  @override
  Widget build(BuildContext context) {
    final bool isEnglish = _searchLanguage == 'en';

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buscador Bíblico',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'OleoScript',
            fontWeight: FontWeight.normal,
            color: AppTheme.color4,
          ),
        ),
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
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.menu, color: Colors.white);
                },
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
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
        child: Column(
          children: [
            // ========== BARRA DE BÚSQUEDA ==========
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Campo de texto + botón buscar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onSubmitted: (_) => isSearching ? null : _buscar(),
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontSize: 14,
                            color: Color(0xFF192E2F),
                          ),
                          decoration: InputDecoration(
                            hintText: isEnglish
                                ? 'Search the Bible...'
                                : 'Buscar en la Biblia...',
                            hintStyle: TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF637983),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.clear,
                                      color: Color(0xFF637983),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        searchResults = [];
                                      });
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isSearching ? null : _buscar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF637983),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          disabledBackgroundColor: Colors.grey.shade400,
                        ),
                        child: isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.search),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ========== SELECTOR DE IDIOMA ==========
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFA2B0BE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _cambiarIdioma('es'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _searchLanguage == 'es'
                                    ? const Color(0xFF637983)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Español (RVR1960)',
                                  style: TextStyle(
                                    fontFamily: 'Sansation',
                                    fontSize: 12,
                                    fontWeight: _searchLanguage == 'es'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _searchLanguage == 'es'
                                        ? Colors.white
                                        : const Color(0xFF637983),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _cambiarIdioma('en'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: _searchLanguage == 'en'
                                    ? const Color(0xFF637983)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Inglés (KJV)',
                                  style: TextStyle(
                                    fontFamily: 'Sansation',
                                    fontSize: 12,
                                    fontWeight: _searchLanguage == 'en'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _searchLanguage == 'en'
                                        ? Colors.white
                                        : const Color(0xFF637983),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ========== CONTADOR DE RESULTADOS ==========
            if (searchResults.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.format_list_numbered,
                      color: Color(0xFF637983),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${searchResults.length} ${isEnglish ? 'results' : 'resultados'}',
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 13,
                        color: Color(0xFF637983),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _searchController.text,
                      style: TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ========== RESULTADOS ==========
            Expanded(
              child: cargando
                  ? const Center(child: CircularProgressIndicator())
                  : isSearching
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Color(0xFF637983),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Buscando...',
                                style: TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 16,
                                  color: Color(0xFF637983),
                                ),
                              ),
                            ],
                          ),
                        )
                      : searchResults.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    isEnglish
                                        ? 'Search the Bible'
                                        : 'Busca en la Biblia',
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isEnglish
                                        ? 'Enter a term and press search'
                                        : 'Ingresa un término y presiona buscar',
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isEnglish
                                        ? 'Version: King James Version'
                                        : 'Versión: Reina-Valera 1960',
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 12,
                                      color: Colors.grey.shade400,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(12),
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final verse = searchResults[index];
                                return _buildResultItem(verse);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ========== WIDGET DE RESULTADO ==========
  Widget _buildResultItem(BibliaVerse verse) {
    final String bookName = _getBookName(verse.bookId);
    final String citation = '$bookName ${verse.chapter}:${verse.verse}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF637983).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cita
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF637983),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                citation,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Texto del versículo
            Text(
              verse.text,
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 15,
                color: Color(0xFF192E2F),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}