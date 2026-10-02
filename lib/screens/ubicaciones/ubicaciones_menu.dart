import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class UbicacionesMenu extends StatelessWidget {
  const UbicacionesMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== BARRA SUPERIOR DE NAVEGACIÓN =====
      appBar: AppBar(
        // Botón de retroceso a la izquierda
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Título con fuente Oleo Script
        title: const Text('Ubicaciones'),
        // Mismos colores que el menú principal
        backgroundColor: AppTheme.color6,
        foregroundColor: AppTheme.color4,
        elevation: 0,
        // Botón de menú lateral ELIMINADO - actions removido
      ),
      body: Container(
        // Fondo con la imagen
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          // Centrar el contenido vertical y horizontalmente
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centrar verticalmente
              crossAxisAlignment: CrossAxisAlignment.center, // Centrar horizontalmente
              children: [
                // ===== BOTONES DE MENÚ =====
                _buildMenuItem(
                  context,
                  titulo: 'Vista por Lista',
                  color: AppTheme.color6,
                  ruta: '/ubicaciones/lista',
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  titulo: 'Vista por Mapa',
                  color: AppTheme.color6,
                  ruta: '/ubicaciones/mapa',
                ),
                const SizedBox(height: 16),
                _buildMenuItem(
                  context,
                  titulo: 'Vista por Cercanía',
                  color: AppTheme.color6,
                  ruta: '/ubicaciones/cercania',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===== TARJETA DE MENÚ PARA CADA OPCIÓN (SIN ICONOS) =====
  Widget _buildMenuItem(
    BuildContext context, {
    required String titulo,
    required Color color,
    required String ruta,
  }) {
    return SizedBox(
      width: 250, // Ancho fijo para los botones
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        color: color, // Fondo color6
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, ruta);
          },
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Center(
              child: Text(
                titulo,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 18,
                  fontWeight: FontWeight.normal, // 👈 Sin negrita (cambiado de w600 a normal)
                  color: AppTheme.color4, // Texto color4
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}