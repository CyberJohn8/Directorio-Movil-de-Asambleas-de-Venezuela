import 'package:flutter/material.dart';
import '../../models/sitio_web.dart';
import '../../models/sitio_web_otros.dart';
import '../../services/api_service.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/theme.dart';
import '../../utils/launch_utils.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: const AppDrawer(),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Material Literario'),
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Español'),
              Tab(text: 'English'),
            ],
            labelStyle: TextStyle(
              fontFamily: 'Sansation',
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            unselectedLabelStyle: TextStyle(
              fontFamily: 'Sansation',
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            indicatorColor: Color(0xFFEAE4D5),
            labelColor: Color(0xFFEAE4D5),
            unselectedLabelColor: Color(0xFFEAE4D5),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/fondo_mapa_tlf.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: const TabBarView(
            children: [
              SitiosWebTab(),
              SitiosWebOtrosTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== PESTAÑA DE SITIOS WEB EN ESPAÑOL =====
class SitiosWebTab extends StatelessWidget {
  const SitiosWebTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SitioWeb>>(
      future: ApiService.getSitiosWeb(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF637983)),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los sitios web',
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    (context as Element).markNeedsBuild();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF637983),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.web_asset_off_rounded,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay sitios web disponibles',
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        } else {
          final sitios = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sitios.length,
            itemBuilder: (context, index) {
              final sitio = sitios[index];
              return _buildMaterialCard(
                context,
                titulo: sitio.titular,
                descripcion: sitio.descripcion ?? '',
                url: sitio.enlace,
              );
            },
          );
        }
      },
    );
  }
}

// ===== PESTAÑA DE SITIOS WEB EN INGLÉS =====
class SitiosWebOtrosTab extends StatelessWidget {
  const SitiosWebOtrosTab({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SitioWebOtros>>(
      future: ApiService.getSitiosWebOtros(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF637983)),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 60,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error al cargar los sitios web',
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.web_asset_off_rounded,
                  size: 60,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay sitios web disponibles en inglés',
                  style: TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        } else {
          final sitios = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sitios.length,
            itemBuilder: (context, index) {
              final sitio = sitios[index];
              return _buildMaterialCard(
                context,
                titulo: sitio.titular,
                descripcion: sitio.descripcion ?? '',
                url: sitio.enlace,
              );
            },
          );
        }
      },
    );
  }
}

// ===== TARJETA DE MATERIAL - MODIFICADA (SIN DIÁLOGO) =====
Widget _buildMaterialCard(
  BuildContext context, {
  required String titulo,
  required String descripcion,
  required String url,
}) {
  return Card(
    elevation: 4,
    color: const Color(0xFFEEEFF1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: InkWell(
      onTap: () => _launchUrlDirectly(context, url), // 👈 CAMBIADO: Nueva función
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Color(0xFF333333),
                    ),
                  ),
                  if (descripcion.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.open_in_browser, // 👈 CAMBIADO: Ícono de abrir en navegador
              color: AppTheme.color6,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}

// ===== LANZAR ENLACE EXTERNO - SIN DIÁLOGO DE CONFIRMACIÓN =====
void _launchUrlDirectly(BuildContext context, String url) async {
  // Validar que la URL no esté vacía
  if (url.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace no está disponible'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return;
  }

  try {
    // 👈 ABRIR DIRECTAMENTE SIN CONFIRMACIÓN
    final launched = await launchUrlDirect(url);
    
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el enlace. Verifica tu conexión a internet.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }
}