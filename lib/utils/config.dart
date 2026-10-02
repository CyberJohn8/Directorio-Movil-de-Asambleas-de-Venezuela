import 'package:flutter/foundation.dart';
import 'dart:io';

class Config {
  // URLs de producción (InfinityFree)
  static const String _productionUrl = "https://cyberant.rf.gd/Directorio/directorio_api";
  static const String _productionUrlHttp = "http://cyberant.rf.gd/Directorio/directorio_api";
  
  // URLs locales (desarrollo)
  static const String _webApiUrl = "http://localhost:8080/directorio_api";
  static const String _emulatorApiUrl = "http://10.0.2.2:8080/directorio_api";
  
  static String _currentApiUrl = "";
  static bool _isUsingProduction = false;
  
  static const int timeoutSeconds = 30;
  static const int fallbackTimeoutSeconds = 15;
  
  // Inicializar configuración
  static Future<void> initialize() async {
    if (_currentApiUrl.isNotEmpty) return;
    
    // Intentar conectar al servidor principal
    bool connected = await _testConnection(_productionUrl);
    
    if (connected) {
      _currentApiUrl = _productionUrl;
      _isUsingProduction = true;
      if (kDebugMode) {
        debugPrint('✅ Conectado a producción: $_currentApiUrl');
      }
    } else {
      // Si falla producción, intentar con HTTP (sin SSL)
      if (kDebugMode) {
        debugPrint('⚠️ Falló conexión HTTPS, intentando HTTP...');
      }
      connected = await _testConnection(_productionUrlHttp);
      
      if (connected) {
        _currentApiUrl = _productionUrlHttp;
        _isUsingProduction = true;
        if (kDebugMode) {
          debugPrint('⚠️ Conectado a producción (HTTP): $_currentApiUrl');
        }
      } else {
        // Usar modo local (desarrollo)
        _isUsingProduction = false;
        if (kIsWeb) {
          _currentApiUrl = _webApiUrl;
        } else {
          _currentApiUrl = _emulatorApiUrl;
        }
        if (kDebugMode) {
          debugPrint('🔄 Usando modo local: $_currentApiUrl');
        }
      }
    }
  }
  
  // Probar conexión con un servidor
  static Future<bool> _testConnection(String url) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: fallbackTimeoutSeconds);
      final request = await client.getUrl(Uri.parse('$url/test_connection.php'));
      final response = await request.close();
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // Obtener la URL actual
  static String get apiUrl {
    if (_currentApiUrl.isEmpty) {
      if (kIsWeb) {
        return _webApiUrl;
      }
      return _emulatorApiUrl;
    }
    return _currentApiUrl;
  }
  
  static bool get isProduction => _isUsingProduction;
}