import 'package:flutter/material.dart';
import '../../models/iglesia.dart';
import '../../utils/theme.dart';
import '../../utils/launch_utils.dart';

class DetalleAsambleaScreen extends StatelessWidget {
  final Iglesia iglesia;
  
  static const String emailContacto = 'directorioasambleas@gmail.com';

  const DetalleAsambleaScreen({super.key, required this.iglesia});

  // ========== FUNCIÓN PARA ABRIR GOOGLE MAPS DIRECTAMENTE ==========
  Future<void> _abrirGoogleMapsDirectamente(BuildContext context, String url) async {
    final String trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El enlace no está disponible.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final bool launched = await launchUrlDirect(trimmedUrl);
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir Google Maps. Verifica tu conexión a internet.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir el enlace: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // ========== FUNCIÓN PARA ENVIAR CORREO - CORREGIDA ==========
  Future<void> _enviarCorreo(BuildContext context) async {
    final bool launched = await sendEmailWithIntent(
      context,
      email: emailContacto,
      asunto: 'Enlace de Google Maps - ${iglesia.asamblea}',
      cuerpo: 'Iglesia: ${iglesia.asamblea}\n'
              'N°: ${iglesia.numero}\n'
              'Ciudad: ${iglesia.ciudad}\n'
              'Estado: ${iglesia.estado}\n\n'
              'Enlace de Google Maps:\n',
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

  String _constructMapUrl() {
    if (iglesia.googleMaps.isNotEmpty) {
      return iglesia.googleMaps;
    }
    if (iglesia.coordenadas != null && iglesia.coordenadas!.isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(iglesia.coordenadas!)}';
    }
    return '';
  }

  // ========== FUNCIÓN ACTUALIZADA PARA FORMATO DD-MM-YYYY ==========
  String _formatearFechaFundacion() {
    if (iglesia.fechaFundacion.isEmpty) {
      return 'No disponible';
    }
    
    final fecha = iglesia.fechaFundacion.trim();
    
    // Si está vacío o es "No disponible"
    if (fecha.isEmpty || fecha.toLowerCase() == 'no disponible') {
      return 'No disponible';
    }
    
    // Intentar parsear formato DD-MM-YYYY
    final partes = fecha.split('-');
    if (partes.length == 3) {
      final dia = partes[0].padLeft(2, '0');
      final mes = partes[1].padLeft(2, '0');
      final anio = partes[2];
      
      // Validar que sean números
      if (int.tryParse(dia) != null && 
          int.tryParse(mes) != null && 
          int.tryParse(anio) != null) {
        // Devolver en formato DD/MM/YYYY para mejor visualización
        return '$dia/$mes/$anio';
      }
    }
    
    // Si no se pudo parsear, devolver el valor original
    return fecha;
  }

  Widget _buildInfoContainer(BuildContext context, {
    required String titulo,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color(0xFFEEEFF1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF000000),
                    fontFamily: 'Sansation',
                    fontWeight: FontWeight.bold,
                  ) ?? const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    if (value.isEmpty || value == 'No disponible') return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 14,
                color: Color(0xFF000000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioCompleto(BuildContext context) {
    final Map<String, String?> dias = {
      'Domingo': iglesia.domingo,
      'Lunes': iglesia.lunes,
      'Martes': iglesia.martes,
      'Miércoles': iglesia.miercoles,
      'Jueves': iglesia.jueves,
      'Viernes': iglesia.viernes,
      'Sábado': iglesia.sabado,
    };

    final diasConHorario = dias.entries.where((e) => 
      e.value != null && 
      e.value!.isNotEmpty && 
      e.value!.toLowerCase() != 'sin reuniones' &&
      e.value!.toLowerCase() != 'sin reuniones.' &&
      e.value!.toLowerCase() != 'ninguna' &&
      e.value!.toLowerCase() != 'ninguno' &&
      e.value!.toLowerCase() != 'no disponible'
    ).toList();
    
    if (diasConHorario.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: const Color(0xFFEEEFF1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Horarios de Reuniones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF000000),
                    fontFamily: 'Sansation',
                    fontWeight: FontWeight.bold,
                  ) ?? const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF000000)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ...diasConHorario.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 85,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.color6.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value!,
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 14,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapUrl = _constructMapUrl();
    final fechaFundacion = _formatearFechaFundacion();
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Asamblea',
          style: TextStyle(
            fontFamily: 'OleoScript',
            fontSize: 30,
            fontWeight: FontWeight.normal,
            color: Color(0xFFEAE4D5),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ========== CUADRO DE TÍTULO ==========
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      color: const Color(0xFFEEEFF1),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              iglesia.asamblea,
                              style: const TextStyle(
                                fontFamily: 'Sansation',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF000000),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.color6.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'N° ${iglesia.numero}',
                                style: const TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.color6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ========== SECCIÓN DE UBICACIÓN ==========
                    _buildInfoContainer(
                      context,
                      titulo: 'Ubicación',
                      children: [
                        _buildInfoRow('Dirección:', iglesia.direccion),
                        _buildInfoRow('Ciudad:', iglesia.ciudad),
                        _buildInfoRow('Estado:', iglesia.estado),
                        // ========== NUEVA LÍNEA: FECHA DE FUNDACIÓN ==========Fecha de Fundación
                        if (fechaFundacion != 'No disponible')
                          _buildInfoRow('Establecida el:', fechaFundacion),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // ========== SECCIÓN DE HORARIOS ==========
                    _buildHorarioCompleto(context),
                    
                    const SizedBox(height: 16),
                    
                    // ========== SECCIÓN DE OBRAS Y MINISTERIOS ==========
                    if (iglesia.obras != null && iglesia.obras!.isNotEmpty) ...[
                      _buildInfoContainer(
                        context,
                        titulo: 'Obras y Ministerios',
                        children: [
                          Text(
                            iglesia.obras!,
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF000000),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // ========== BOTÓN DE GOOGLE MAPS O MENSAJE DE COLABORACIÓN ==========
                    if (mapUrl.isNotEmpty)
                      Center(
                        child: SizedBox(
                          width: constraints.maxWidth * 0.5,
                          child: ElevatedButton(
                            onPressed: () => _abrirGoogleMapsDirectamente(context, mapUrl),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.color6,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.map, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Abrir en Google Maps',
                                  style: TextStyle(
                                    fontFamily: 'Sansation',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Center(
                        child: Container(
                          width: constraints.maxWidth * 0.85,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEFF1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '¿Conoces la ubicación exacta de esta asamblea?',
                                style: TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF192E2F),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Ayúdanos a mejorar el directorio compartiendo el enlace de Google Maps.',
                                style: TextStyle(
                                  fontFamily: 'Sansation',
                                  fontSize: 12,
                                  color: Color(0xFF555555),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _enviarCorreo(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.color6,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.email,
                                        size: 18,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        emailContacto,
                                        style: const TextStyle(
                                          fontFamily: 'Sansation',
                                          fontSize: 12,
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
                      ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}