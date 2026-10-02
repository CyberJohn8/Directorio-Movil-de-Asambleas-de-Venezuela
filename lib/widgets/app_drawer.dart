import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform, exit;
import '../screens/estudio_biblico/biblia_screen.dart';
import '../screens/estudio_biblico/himnario_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  static const List<Map<String, dynamic>> _opciones = [
    {
      'titulo': 'Menú Principal',
      'icono': Icons.home,
      'iconoAsset': 'assets/icons/inicio.png',
      'ruta': '/',
    },
    // 👈 UBICACIONES ahora está aquí (como elemento independiente)
    // 👈 ESTUDIO BÍBLICO ahora está aquí (como elemento independiente)
    {
      'titulo': 'Material Literario',
      'icono': Icons.menu_book,
      'iconoAsset': 'assets/icons/material.png',
      'ruta': '/material',
    },
    {
      'titulo': 'Criptograma',
      'icono': Icons.videogame_asset,
      'ruta': '/criptograma',
    },
  ];

  // Función para cerrar la aplicación
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
    return Drawer(
      child: Container(
        color: const Color(0xFF637983),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ===== ENCABEZADO =====
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF637983),
              ),
              child: DrawerHeader(
                child: Center(
                  child: Text(
                    'Menú Principal',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFFEEEFF1),
                          fontFamily: 'OleoScript',
                        ) ?? const TextStyle(fontSize: 26, color: Color(0xFFEEEFF1)),
                  ),
                ),
              ),
            ),

            // ===== 1. MENÚ PRINCIPAL =====
            ..._opciones.where((opcion) => opcion['titulo'] == 'Menú Principal').map((opcion) {
              final bool hasIconoAsset = opcion.containsKey('iconoAsset') && opcion['iconoAsset'] != null;
              
              return ListTile(
                leading: hasIconoAsset
                    ? Image.asset(
                        opcion['iconoAsset'] as String,
                        width: 28,
                        height: 28,
                        color: const Color(0xFFEEEFF1),
                      )
                    : Icon(opcion['icono'] as IconData, 
                        color: const Color(0xFFEEEFF1),
                        size: 28),
                title: Text(
                  opcion['titulo'] as String,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFFEEEFF1),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFEEEFF1),
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, opcion['ruta'] as String);
                },
                tileColor: Colors.transparent,
                hoverColor: const Color(0xFFEEEFF1).withValues(alpha: 0.1),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              );
            }),

            // ===== 2. UBICACIONES (expandible con flecha) =====
            ExpansionTile(
              leading: Image.asset('assets/icons/ubicaciones.png', width: 28, height: 28, color: const Color(0xFFEEEFF1)),
              title: const Text('Ubicaciones', style: TextStyle(fontFamily: 'Sansation', fontSize: 16, color: Color(0xFFEEEFF1), fontWeight: FontWeight.normal)),
              iconColor: const Color(0xFFEEEFF1),
              collapsedIconColor: const Color(0xFFEEEFF1),
              children: [
                ListTile(
                  title: const Text('Lista', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/ubicaciones/lista');
                  },
                ),
                ListTile(
                  title: const Text('Mapa', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/ubicaciones/mapa');
                  },
                ),
                ListTile(
                  title: const Text('Cercanía', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/ubicaciones/cercania');
                  },
                ),
              ],
            ),

            // ===== 3. ESTUDIO BÍBLICO (expandible) =====
            ExpansionTile(
              leading: Image.asset('assets/icons/biblia.png', width: 28, height: 28, color: const Color(0xFFEEEFF1)),
              title: const Text('Estudio Bíblico', style: TextStyle(fontFamily: 'Sansation', fontSize: 16, color: Color(0xFFEEEFF1), fontWeight: FontWeight.normal)),
              iconColor: const Color(0xFFEEEFF1),
              collapsedIconColor: const Color(0xFFEEEFF1),
              children: [
                ListTile(
                  title: const Text('Leer la Biblia', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const BibliaScreen()));
                  },
                ),
                ListTile(
                  title: const Text('Leer el Himnario', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (c) => const HimnarioScreen()));
                  },
                ),
              ],
            ),

            // ===== 4. MATERIAL LITERARIO =====
            ..._opciones.where((opcion) => opcion['titulo'] == 'Material Literario').map((opcion) {
              final bool hasIconoAsset = opcion.containsKey('iconoAsset') && opcion['iconoAsset'] != null;
              
              return ListTile(
                leading: hasIconoAsset
                    ? Image.asset(
                        opcion['iconoAsset'] as String,
                        width: 28,
                        height: 28,
                        color: const Color(0xFFEEEFF1),
                      )
                    : Icon(opcion['icono'] as IconData, 
                        color: const Color(0xFFEEEFF1),
                        size: 28),
                title: Text(
                  opcion['titulo'] as String,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFFEEEFF1),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFEEEFF1),
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, opcion['ruta'] as String);
                },
                tileColor: Colors.transparent,
                hoverColor: const Color(0xFFEEEFF1).withValues(alpha: 0.1),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              );
            }),

            // ===== 5. CRIPTOGRAMA =====
            ..._opciones.where((opcion) => opcion['titulo'] == 'Criptograma').map((opcion) {
              final bool hasIconoAsset = opcion.containsKey('iconoAsset') && opcion['iconoAsset'] != null;
              
              return ListTile(
                leading: hasIconoAsset
                    ? Image.asset(
                        opcion['iconoAsset'] as String,
                        width: 28,
                        height: 28,
                        color: const Color(0xFFEEEFF1),
                      )
                    : Icon(opcion['icono'] as IconData, 
                        color: const Color(0xFFEEEFF1),
                        size: 28),
                title: Text(
                  opcion['titulo'] as String,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFFEEEFF1),
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFEEEFF1),
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, opcion['ruta'] as String);
                },
                tileColor: Colors.transparent,
                hoverColor: const Color(0xFFEEEFF1).withValues(alpha: 0.1),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              );
            }),

            // ===== INFORMACIÓN (expandible) =====
            ExpansionTile(
              leading: const Icon(Icons.info, color: Color(0xFFEEEFF1), size: 28),
              title: const Text(
                'Información',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFFEEEFF1),
                ),
              ),
              iconColor: const Color(0xFFEEEFF1),
              collapsedIconColor: const Color(0xFFEEEFF1),
              children: [
                ListTile(
                  title: const Text('¿Quiénes Somos?', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/quienes-somos');
                  },
                ),
                ListTile(
                  title: const Text('Acerca de', style: TextStyle(color: Color(0xFFEEEFF1))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFEEEFF1), size: 18),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/acerca-de');
                  },
                ),
              ],
            ),

            const Divider(color: Color(0xFFEEEFF1), thickness: 0.5, height: 24),

            // ===== OPCIÓN DE SALIR =====
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Color(0xFFEEEFF1), size: 28),
              title: const Text(
                'Salir',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  color: Color(0xFFEEEFF1),
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFFEEEFF1),
                size: 20,
              ),
              onTap: () {
                _mostrarDialogoSalir(context);
              },
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoSalir(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Salir de la aplicación',
            style: TextStyle(
              fontFamily: 'Sansation',
              fontWeight: FontWeight.normal,
              color: Color(0xFF192E2F),
            ),
          ),
          content: const Text(
            '¿Estás seguro que deseas salir de la aplicación?',
            style: TextStyle(
              fontFamily: 'Sansation',
              fontSize: 14,
              color: Color(0xFF192E2F),
            ),
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  color: Color(0xFF637983),
                ),
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
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
              ),
              child: const Text(
                'Salir',
                style: TextStyle(
                  fontFamily: 'Sansation',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}