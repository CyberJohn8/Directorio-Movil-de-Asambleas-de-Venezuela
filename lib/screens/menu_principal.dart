import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;
import '../utils/theme.dart';
import '../widgets/app_drawer.dart';
import '../services/permission_service.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  final PermissionService _permissionService = PermissionService();
  bool _permissionsChecked = false;

  @override
  void initState() {
    super.initState();
    _verificarPermisosAlIniciar();
  }

  // ========== VERIFICAR PERMISOS AL INICIAR (SOLO SI ES NECESARIO) ==========
  Future<void> _verificarPermisosAlIniciar() async {
    await _permissionService.checkAndRequestOnStartup(context);
    
    if (mounted) {
      setState(() {
        _permissionsChecked = true;
      });
    }
  }

  // Lista de opciones del menú
  List<Map<String, dynamic>> getOpciones() => [
    {
      'titulo': 'Ubicaciones',
      'ruta': '/ubicaciones',
    },
    {
      'titulo': 'Estudio Bíblico',
      'ruta': '/estudio',
    },
    {
      'titulo': 'Material Literario',
      'ruta': '/material',
    },
    {
      'titulo': 'Criptograma',
      'ruta': '/criptograma',
    },
    {
      'titulo': '¿Quiénes Somos?',
      'ruta': '/quienes-somos',
    },
    {
      'titulo': 'Acerca de',
      'ruta': '/acerca-de',
    },

    //este segmento se debe conservar
    // {
    //   'titulo': 'Revisar Errores',
    //   'ruta': '/analisis-errores',
    // },
    
    {
      'titulo': 'Cerrar Programa',
      'ruta': 'cerrar',
    },
  ];

  // ========== FUNCIÓN PARA CERRAR LA APLICACIÓN ==========
  void _cerrarAplicacion(BuildContext context) {
    if (Platform.isAndroid) {
      SystemNavigator.pop();
    } else if (Platform.isIOS) {
      exit(0);
    } else {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = screenWidth * 0.5;
    const double fontSize = 15;

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              'assets/icons/menu.png',
              width: 28,
              height: 28,
              color: AppTheme.color4,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        // 👈 ELIMINADO: BOTÓN DE PERMISOS
      ),
      drawer: const AppDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/icons/titulo.png',
                      width: 200,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '"Porque donde están dos o tres congregados en mi nombre, allí estoy yo en medio de ellos."',
                      style: TextStyle(
                        color: AppTheme.color5,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 1.5,
                      width: 40,
                      color: AppTheme.color6.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Mateo 18:20',
                      style: TextStyle(
                        color: AppTheme.color5,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Center(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: getOpciones().length,
                    itemBuilder: (context, index) {
                      final opcion = getOpciones()[index];
                      if (opcion['ruta'] == 'cerrar') {
                        return _buildExitButton(
                          context: context,
                          titulo: opcion['titulo'],
                          buttonWidth: buttonWidth,
                          fontSize: fontSize,
                        );
                      }
                      return _buildMenuItem(
                        context: context,
                        titulo: opcion['titulo'],
                        ruta: opcion['ruta'],
                        buttonWidth: buttonWidth,
                        fontSize: fontSize,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== BOTÓN DE CERRAR PROGRAMA ==========
  Widget _buildExitButton({
    required BuildContext context,
    required String titulo,
    required double buttonWidth,
    required double fontSize,
  }) {
    return Center(
      child: SizedBox(
        width: buttonWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _mostrarDialogoSalir(context),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF637983),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      color: const Color(0xFFEAE4D5),
                      fontSize: fontSize,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== MÉTODO PARA CONSTRUIR CADA BOTÓN DEL MENÚ ==========
  Widget _buildMenuItem({
    required BuildContext context,
    required String titulo,
    required String ruta,
    required double buttonWidth,
    required double fontSize,
  }) {
    return Center(
      child: SizedBox(
        width: buttonWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.pushNamed(context, ruta);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFF637983),
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      offset: Offset(0, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    titulo,
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      color: const Color(0xFFEAE4D5),
                      fontSize: fontSize,
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ========== DIÁLOGO DE CONFIRMACIÓN PARA SALIR ==========
  void _mostrarDialogoSalir(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Salir del Programa',
            style: TextStyle(
              fontFamily: 'Sansation',
              fontWeight: FontWeight.normal,
            ),
          ),
          content: const Text(
            '¿Estás seguro que deseas salir de la aplicación?',
            style: TextStyle(fontSize: 14, fontFamily: 'Sansation'),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontFamily: 'Sansation'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _cerrarAplicacion(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF637983),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Salir',
                style: TextStyle(fontFamily: 'Sansation'),
              ),
            ),
          ],
        );
      },
    );
  }
}