import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlLauncherService {
  // Método para abrir enlaces web
  static Future<bool> abrirWeb(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      
      // Verificar si se puede lanzar el enlace
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // Abre en navegador externo
          webViewConfiguration: const WebViewConfiguration(
            enableJavaScript: true,
          ),
        );
        return true;
      } else {
        throw 'No se puede abrir la URL: $url';
      }
    } catch (e) {
      debugPrint('Error al abrir enlace: $e');
      return false;
    }
  }

  // Método para enviar correos
  static Future<bool> enviarCorreo({
    required String email,
    String? asunto,
    String? cuerpo,
  }) async {
    try {
      // Construir el mailto URI
      String uriString = 'mailto:$email';
      
      // Añadir parámetros opcionales
      final params = <String, String>{};
      if (asunto != null && asunto.isNotEmpty) {
        params['subject'] = asunto;
      }
      if (cuerpo != null && cuerpo.isNotEmpty) {
        params['body'] = cuerpo;
      }
      
      // Construir URI con parámetros
      if (params.isNotEmpty) {
        final queryParams = params.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        uriString += '?$queryParams';
      }
      
      final Uri uri = Uri.parse(uriString);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      } else {
        throw 'No se puede abrir el cliente de correo';
      }
    } catch (e) {
      debugPrint('Error al enviar correo: $e');
      return false;
    }
  }

  // Método para abrir enlaces con confirmación
  static Future<void> abrirWebConConfirmacion(
    BuildContext context,
    String url, {
    String? mensajeConfirmacion,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Abrir enlace externo'),
          content: Text(
            mensajeConfirmacion ?? '¿Deseas abrir el siguiente enlace?\n\n$url',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Abrir'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await abrirWeb(url);
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el enlace'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Método para enviar correo con confirmación
  static Future<void> enviarCorreoConConfirmacion(
    BuildContext context, {
    required String email,
    String? asunto,
    String? cuerpo,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enviar correo'),
          content: Text(
            '¿Deseas enviar un correo a:\n\n$email?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final success = await enviarCorreo(
        email: email,
        asunto: asunto,
        cuerpo: cuerpo,
      );
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo abrir el cliente de correo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}