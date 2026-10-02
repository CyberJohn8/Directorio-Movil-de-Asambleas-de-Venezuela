// lib/utils/launch_utils.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Valida y formatea una URL para asegurar que tenga protocolo
String validateAndFormatUrl(String url) {
  String trimmedUrl = url.trim();
  
  if (trimmedUrl.isEmpty) {
    return '';
  }
  
  if (!trimmedUrl.startsWith('http://') && !trimmedUrl.startsWith('https://')) {
    trimmedUrl = 'https://$trimmedUrl';
  }
  
  return trimmedUrl;
}

/// Verifica si una URL es válida y se puede lanzar
Future<bool> canLaunchUrlString(String url) async {
  try {
    final formattedUrl = validateAndFormatUrl(url);
    if (formattedUrl.isEmpty) return false;
    
    final uri = Uri.parse(formattedUrl);
    return await canLaunchUrl(uri);
  } catch (e) {
    debugPrint('Error al verificar URL: $e');
    return false;
  }
}

/// Lanza una URL con confirmación del usuario
Future<bool> confirmAndLaunchUrl(
  BuildContext context,
  String url, {
  String? confirmMessage,
}) async {
  final formattedUrl = validateAndFormatUrl(url);
  
  if (formattedUrl.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El enlace no es válido'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  final canLaunch = await canLaunchUrlString(formattedUrl);
  if (!canLaunch) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se puede abrir: $formattedUrl'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  final shouldLaunch = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.open_in_browser_rounded,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 10),
            const Text(
              'Abrir enlace externo',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              confirmMessage ?? '¿Deseas abrir el siguiente enlace?',
              style: const TextStyle(
                fontFamily: 'Sansation',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                formattedUrl,
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 13,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Serás redirigido al navegador externo',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontFamily: 'Sansation',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Sansation',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text(
              'Abrir',
              style: TextStyle(
                fontFamily: 'Sansation',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF637983),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldLaunch == true) {
    try {
      final uri = Uri.parse(formattedUrl);
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
        ),
      );
      
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return false;
      }
      
      return launched;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  
  return false;
}

/// Lanza una URL sin confirmación (para uso interno)
Future<bool> launchUrlDirect(String url) async {
  final formattedUrl = validateAndFormatUrl(url);
  if (formattedUrl.isEmpty) return false;
  
  try {
    final uri = Uri.parse(formattedUrl);
    return await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    debugPrint('Error al lanzar URL: $e');
    return false;
  }
}

// ============================================================
// 👇 FUNCIÓN PARA ENVIAR CORREO - VERSIÓN DE EMERGENCIA
// ============================================================

/// Envía un correo electrónico usando mailto: con fallback a copiar
Future<bool> sendEmailWithIntent(
  BuildContext context, {
  required String email,
  String? asunto,
  String? cuerpo,
}) async {
  if (email.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La dirección de correo no es válida'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    return false;
  }

  // Mostrar diálogo de confirmación
  final shouldSend = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.email_rounded, color: Color(0xFF637983)),
            SizedBox(width: 10),
            Text(
              'Enviar Correo',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Deseas enviar un correo a?',
              style: TextStyle(
                fontFamily: 'Sansation',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, size: 20, color: Color(0xFF637983)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      email,
                      style: const TextStyle(
                        fontFamily: 'Sansation',
                        fontSize: 14,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (asunto != null && asunto.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Asunto: $asunto',
                style: const TextStyle(
                  fontFamily: 'Sansation',
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Se abrirá Gmail con el correo pre-cargado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber,
                        fontFamily: 'Sansation',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                fontFamily: 'Sansation',
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send, size: 18),
            label: const Text(
              'Enviar',
              style: TextStyle(
                fontFamily: 'Sansation',
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF637983),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      );
    },
  );

  if (shouldSend == true) {
    try {
      // Construir mailto URI
      String mailtoUri = 'mailto:$email';
      List<String> queryParams = [];
      
      if (asunto != null && asunto.isNotEmpty) {
        queryParams.add('subject=${Uri.encodeComponent(asunto)}');
      }
      if (cuerpo != null && cuerpo.isNotEmpty) {
        queryParams.add('body=${Uri.encodeComponent(cuerpo)}');
      }
      
      if (queryParams.isNotEmpty) {
        mailtoUri += '?${queryParams.join('&')}';
      }
      
      final uri = Uri.parse(mailtoUri);
      
      // INTENTAR 1: mailto normal
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      
      // INTENTAR 2: Si falla, intentar con Gmail específicamente
      if (!launched) {
        final gmailUri = Uri.parse(
          'mailto:$email?subject=${Uri.encodeComponent(asunto ?? '')}&body=${Uri.encodeComponent(cuerpo ?? '')}'
        );
        launched = await launchUrl(
          gmailUri,
          mode: LaunchMode.externalApplication,
        );
      }
      
      // INTENTAR 3: Si aún falla, mostrar opción de copiar
      if (!launched && context.mounted) {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'No se pudo abrir Gmail',
                style: TextStyle(
                  fontFamily: 'Sansation',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Puedes copiar la dirección y enviarla manualmente:',
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF637983).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            email,
                            style: const TextStyle(
                              fontFamily: 'Sansation',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF637983),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, color: Color(0xFF637983)),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: email));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Correo copiado al portapapeles'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Luego abre Gmail y pega la dirección en el campo "Para"',
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(
                      fontFamily: 'Sansation',
                      color: Color(0xFF637983),
                    ),
                  ),
                ),
              ],
            );
          },
        );
        return false;
      }
      
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir correo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }
  
  return false;
}

/// Normaliza el nombre de un estado para búsqueda de mapas
String normalizeStateName(String estado) {
  final normalized = estado.trim().toLowerCase();
  return normalized[0].toUpperCase() + normalized.substring(1);
}