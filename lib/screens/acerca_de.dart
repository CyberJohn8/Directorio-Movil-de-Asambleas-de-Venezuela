// lib/screens/acerca_de.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/app_drawer.dart';
import '../utils/theme.dart';
import '../utils/launch_utils.dart';

/// Pantalla "Acerca de" que muestra información sobre la aplicación,
/// derechos de autor, políticas de privacidad y agradecimientos.
class AcercaDeScreen extends StatelessWidget {
  const AcercaDeScreen({super.key});

  // Correo electrónico de contacto
  static const String emailContacto = 'directorioasambleas@gmail.com';

  // ========================================
  // ESTILOS REUTILIZABLES
  // ========================================

  /// Color del título (mismo que "Acerca de esta aplicación")
  static const Color _colorTitulo = Color(0xFF192E2F);

  /// Estilo de título unificado:
  /// - Mismo color que "Acerca de esta aplicación" (0xFF192E2F)
  /// - Mismo tamaño que "Últimas Actualizaciones" (20)
  static const TextStyle _estiloTitulo = TextStyle(
    fontFamily: 'OleoScript',
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: _colorTitulo,
  );

  // Función para abrir el cliente de correo
  Future<void> _enviarCorreo(BuildContext context) async {
    final bool launched = await sendEmailWithIntent(
      context,
      email: emailContacto,
      asunto: 'Sugerencia o Comentario - Directorio de Asambleas',
      cuerpo: 'Hola, me gustaría hacer una sugerencia sobre la aplicación.',
    );

    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el cliente de correo'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ========================================
  // WIDGET: TÍTULO UNIFICADO DE SECCIÓN
  // ========================================
  Widget _buildTituloSeccion(String texto) {
    return Text(
      texto,
      style: _estiloTitulo,
      textAlign: TextAlign.center,
    );
  }

  // ========================================
  // WIDGET: TÍTULO DE SECCIÓN CON ICONO (estilo Últimas Actualizaciones)
  // ========================================
  Widget _buildTituloSeccionConIcono({
    required IconData icon,
    required String texto,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: _colorTitulo),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: _estiloTitulo,
            softWrap: true,
            maxLines: 2,
            textAlign: TextAlign.left,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Acerca de'),
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

      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo_mapa_tlf.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      // ================================
                      // TÍTULO PRINCIPAL
                      // ================================
                      _buildTituloSeccion('Acerca de esta aplicación'),
                      const SizedBox(height: 20),

                      // ================================
                      // OBJETIVO
                      // ================================
                      const Text(
                        'Esta aplicación fue desarrollada con el objetivo de ofrecer una versión digital del Directorio de Asambleas de Hermanos en Venezuela, incluyendo funciones como:',
                        style: TextStyle(
                          fontFamily: 'Sansation',
                          fontSize: 16,
                          height: 1.5,
                          color: Color(0xFF192E2F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      _buildFuncionItem('Acceso a direcciones y horarios de reuniones'),
                      const SizedBox(height: 8),
                      _buildFuncionItem('Mapas interactivos de ubicaciones'),
                      const SizedBox(height: 8),
                      _buildFuncionItem('Búsqueda por cercanía'),
                      const SizedBox(height: 8),
                      _buildFuncionItem('Lectura de Biblia e Himnario'),
                      const SizedBox(height: 8),
                      _buildFuncionItem('Texto a voz para la Biblia'),
                      const SizedBox(height: 24),

                      // ================================
                      // SECCIÓN: CONTÁCTANOS
                      // ================================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF637983).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF637983).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTituloSeccionConIcono(
                              icon: Icons.contact_mail,
                              texto: 'Contáctanos',
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              '¿Tienes sugerencias, comentarios o ideas para mejorar la aplicación?',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Puedes enviarnos tus comentarios al siguiente correo electrónico:',
                                    style: TextStyle(
                                      fontFamily: 'Sansation',
                                      fontSize: 13,
                                      color: Color(0xFF192E2F),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),

                                  InkWell(
                                    onTap: () => _enviarCorreo(context),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF637983),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.email,
                                            size: 20,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Enviar Correo',
                                            style: TextStyle(
                                              fontFamily: 'Sansation',
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF192E2F).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    size: 16,
                                    color: Color(0xFF637983),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '¡Gracias por ayudarnos a mejorar!',
                                      style: TextStyle(
                                        fontFamily: 'Sansation',
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF192E2F),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ================================
                      // SECCIÓN: ÚLTIMAS ACTUALIZACIONES
                      // ================================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF637983).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF637983).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTituloSeccionConIcono(
                              icon: Icons.update,
                              texto: 'Últimas Actualizaciones',
                            ),
                            const SizedBox(height: 16),

                            _buildUpdateItem(
                              icon: Icons.smartphone,
                              title: 'Migración a Aplicación Móvil',
                              description:
                                  'El sistema ha sido completamente migrado de plataforma web a una aplicación móvil nativa, mejorando la experiencia de usuario y el rendimiento.',
                              date: 'Junio 2026',
                            ),

                            const SizedBox(height: 12),

                            _buildUpdateItem(
                              icon: Icons.add_circle_outline,
                              title: 'Nuevas Funciones',
                              description:
                                  '• Mapas interactivos con zoom\n• Búsqueda por cercanía usando GPS\n• Texto a voz para la Biblia\n• Diseño responsivo para todos los dispositivos',
                              date: 'Junio 2026',
                            ),

                            const SizedBox(height: 12),

                            _buildUpdateItem(
                              icon: Icons.engineering,
                              title: 'Mejoras Técnicas',
                              description:
                                  '• Base de datos local para funcionamiento offline\n• Interfaz más rápida y fluida\n• Mejor manejo de errores\n• Optimización de imágenes y recursos',
                              date: 'Junio 2026',
                            ),

                            const SizedBox(height: 12),

                            _buildUpdateItem(
                              icon: Icons.engineering,
                              title: 'Actualización de la Biblia',
                              description:
                                  '• Elegir la Biblia entre Español e Inglés\n• Guardar versiculos favoritos\n• Buscador Biblico\n• Ajustes en el sistema de audio',
                              date: 'Septiembre 2026',
                            ),

                            const SizedBox(height: 12),

                            _buildUpdateItem(
                              icon: Icons.upcoming,
                              title: 'Próximamente',
                              description: '• Elegir entre Español o Inglés',
                              date: '',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ================================
                      // SECCIÓN: POLÍTICA DE PRIVACIDAD
                      // ================================
                      _buildTituloSeccion('Política de Privacidad'),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF192E2F).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Esta aplicación NO recopila ni almacena datos personales de los usuarios.',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.5,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'La información que se muestra en la aplicación proviene exclusivamente de la base de datos generada del Directorio de Asambleas de Venezuela. Estos datos incluyen:',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              '• Nombres y ubicaciones de las iglesias\n• Direcciones y horarios de reuniones\n',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 13,
                                height: 1.5,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'La aplicación no requiere registro de usuarios, no almacena información personal, y no comparte datos con terceros. Todos los datos mostrados son de carácter público e institucional.',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Al utilizar esta aplicación, usted acepta que solo se maneja información pública de las Iglesias Congregadas Al Nombre del Señor en Venezuela, sin recopilar datos personales de los usuarios.',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.5,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ================================
                      // SECCIÓN: AGRADECIMIENTOS
                      // (Mismo diseño que "Últimas Actualizaciones")
                      // ================================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF637983).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF637983).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildTituloSeccion('Agradecimientos'),
                            const SizedBox(height: 16),

                            _buildUpdateItem(
                              icon: Icons.design_services,
                              title: 'Alexa Malavé',
                              description:
                                  'Diseño visual e interfaz de la aplicación.',
                              date: '',
                            ),

                            const SizedBox(height: 12),

                            _buildUpdateItem(
                              icon: Icons.library_music,
                              title: 'Andrés Padrón',
                              description: 'Base de datos del Himnario.',
                              date: '',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ================================
                      // FOOTER
                      // ================================
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: const Color(0xFF192E2F).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '© 2025-2026 John Malavé. Todos los derechos reservados.',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 12,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Prohibida su reproducción total o parcial sin autorización previa.',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 12,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Versión 2.5 | Aplicación Móvil',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 12,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Última actualización: septiembre 2026',
                              style: TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 12,
                                color: Color(0xFF192E2F),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ========================================
  // WIDGET: ITEM DE FUNCIÓN
  // ========================================
  Widget _buildFuncionItem(String texto) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 20,
          color: Color(0xFF637983),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontFamily: 'Sansation',
              fontSize: 14,
              color: Color(0xFF192E2F),
            ),
          ),
        ),
      ],
    );
  }

  // ========================================
  // WIDGET: ITEM DE ACTUALIZACIÓN / AGRADECIMIENTO
  // ========================================
  Widget _buildUpdateItem({
    required IconData icon,
    required String title,
    required String description,
    required String date,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF637983).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF637983)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Sansation',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF192E2F),
                        ),
                      ),
                    ),
                    // Solo mostrar el badge de fecha si no está vacío
                    if (date.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF637983).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          date,
                          style: const TextStyle(
                            fontFamily: 'Sansation',
                            fontSize: 10,
                            color: Color(0xFF637983),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'Sansation',
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF192E2F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}