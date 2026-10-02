// lib/services/api_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/config.dart';
import '../models/iglesia.dart';
import '../models/himno.dart';
import '../models/sitio_web.dart';
import '../models/sitio_web_otros.dart';
import '../models/corito.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../models/institucion.dart';
import '../models/mensaje.dart';
import '../models/usuario.dart';
import '../models/categoria_tabla.dart';
import 'data_manager.dart';
import 'local_database_service.dart'; // 👈 IMPORTANTE: Agregar este import

class Logger {
  static void error(String message) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
    }
  }
  
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🔍 DEBUG: $message');
    }
  }
}

class ApiService {
  static final DataManager _dataManager = DataManager();
  static bool _useLocalDatabase = false;
  static bool _localDbChecked = false;

  // Verificar si usar base de datos local
  static Future<bool> shouldUseLocalDatabase() async {
    if (_localDbChecked) return _useLocalDatabase;
    
    try {
      String url = '${Config.apiUrl}/controllers/iglesias.php';
      Logger.debug('Intentando conectar a: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        try {
          json.decode(response.body);
          _useLocalDatabase = false;
          Logger.info('✅ Conexión al servidor exitosa - Usando API en línea');
        } catch (e) {
          _useLocalDatabase = true;
          Logger.debug('⚠️ El servidor devolvió HTML en lugar de JSON - Usando base de datos local');
        }
      } else {
        _useLocalDatabase = true;
        Logger.debug('⚠️ Servidor no responde (${response.statusCode}) - Usando base de datos local');
      }
    } catch (e) {
      _useLocalDatabase = true;
      Logger.error('⚠️ Error de conexión - Usando base de datos local: $e');
    }
    
    _localDbChecked = true;
    
    if (_useLocalDatabase) {
      try {
        await _dataManager.checkDbConnection();
        Logger.info('✅ DataManager disponible - Usando DB local o respaldos JSON');
      } catch (e) {
        Logger.error('❌ Error con DataManager: $e');
      }
    }
    
    return _useLocalDatabase;
  }

  // Helper para hacer peticiones con reintentos automáticos
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() request, {
    int retries = 2,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await request();
        if (response.statusCode == 200) {
          return response;
        }
        if (response.statusCode >= 400 && response.statusCode < 500) {
          return response;
        }
      } catch (e) {
        Logger.error('Intento ${i + 1} falló: $e');
        if (i == retries - 1) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }
    throw Exception('Todos los intentos fallaron');
  }

  // ==================== IGLESIAS ====================
  
  static Future<List<Iglesia>> getIglesias() async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para iglesias (DB o respaldo)');
        return await _dataManager.getIglesias();
      }
      
      String url = '${Config.apiUrl}/controllers/iglesias.php';
      Logger.debug('🌐 Obteniendo iglesias desde: $url');
      
      final response = await _makeRequest(() => http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: Config.timeoutSeconds)));
      
      if (response.statusCode == 200) {
        Logger.info('✅ API getIglesias exitoso - ${response.body.length} caracteres');
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Iglesia.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar iglesias: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error en getIglesias: $e');
      Logger.debug('🔄 Falló API, intentando con DataManager...');
      return await _dataManager.getIglesias();
    }
  }

  static Future<List<Iglesia>> getIglesiasByEstado(String estado) async {
    try {
      if (await shouldUseLocalDatabase()) {
        final todas = await _dataManager.getIglesias();
        return todas.where((i) => i.estado.toLowerCase() == estado.toLowerCase()).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/iglesias.php?estado=$estado'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Iglesia.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getIglesiasByEstado: $e');
      return [];
    }
  }

  static Future<List<Iglesia>> searchIglesias(String query) async {
    try {
      if (await shouldUseLocalDatabase()) {
        final todas = await _dataManager.getIglesias();
        final queryLower = query.toLowerCase();
        return todas.where((i) => 
          i.asamblea.toLowerCase().contains(queryLower) ||
          i.estado.toLowerCase().contains(queryLower) ||
          i.ciudad.toLowerCase().contains(queryLower)
        ).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/iglesias.php?search=$query'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Iglesia.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en searchIglesias: $e');
      return [];
    }
  }

  static Future<Iglesia?> getIglesiaById(int id) async {
    try {
      if (await shouldUseLocalDatabase()) {
        final todas = await _dataManager.getIglesias();
        try {
          return todas.firstWhere((i) => i.id == id);
        } catch (e) {
          return null;
        }
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/iglesias.php?id=$id'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        return Iglesia.fromJson(json.decode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      Logger.error('Error en getIglesiaById: $e');
      return null;
    }
  }

  static Future<List<String>> getEstados() async {
    try {
      if (await shouldUseLocalDatabase()) {
        final todas = await _dataManager.getIglesias();
        final estados = todas.map((i) => i.estado).toSet().toList();
        estados.sort();
        return estados;
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/iglesias.php?estados'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((e) => e.toString()).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getEstados: $e');
      return [];
    }
  }

  // ==================== HIMNOS ====================
  
  static Future<List<Himno>> getHimnos() async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para himnos (DB o respaldo)');
        return await _dataManager.getHimnos();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/himnos.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Himno.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getHimnos: $e');
      return await _dataManager.getHimnos();
    }
  }

  // ==================== SITIOS WEB ====================
  
  static Future<List<SitioWeb>> getSitiosWeb() async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para sitios web (DB o respaldo)');
        return await _dataManager.getSitiosWeb();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/sitios_web.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => SitioWeb.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getSitiosWeb: $e');
      return await _dataManager.getSitiosWeb();
    }
  }

  static Future<List<SitioWebOtros>> getSitiosWebOtros() async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para otros sitios web (DB o respaldo)');
        return await _dataManager.getSitiosWebOtros();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/sitios_web_otros.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => SitioWebOtros.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getSitiosWebOtros: $e');
      return await _dataManager.getSitiosWebOtros();
    }
  }

  // ==================== CORITOS ====================
  
  static Future<List<Corito>> getCoritos() async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para coritos (DB o respaldo)');
        return await _dataManager.getCoritos();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/coritos.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Corito.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getCoritos: $e');
      return await _dataManager.getCoritos();
    }
  }

  // ==================== BIBLIA ====================
  
  static Future<List<Book>> getBooks() async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para libros (DB o respaldo)');
        return await _dataManager.getBooks();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/books.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getBooks: $e');
      return await _dataManager.getBooks();
    }
  }

  static Future<List<Verse>> getVerses(int bookId, int chapter) async {
    try {
      if (await shouldUseLocalDatabase()) {
        Logger.debug('📁 Usando DataManager para versículos (DB o respaldo)');
        final todos = await _dataManager.getVerses();
        return todos.where((v) => v.bookId == bookId && v.chapter == chapter).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/verses.php?book_id=$bookId&chapter=$chapter'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Verse.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getVerses: $e');
      final todos = await _dataManager.getVerses();
      return todos.where((v) => v.bookId == bookId && v.chapter == chapter).toList();
    }
  }

  // ==================== INSTITUCIONES ====================
  
  static Future<List<Institucion>> getInstituciones() async {
    try {
      if (await shouldUseLocalDatabase()) {
        final db = await LocalDatabaseService().database;
        final List<Map<String, dynamic>> maps = await db.query('instituciones');
        return maps.map((map) => Institucion.fromMap(map)).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/instituciones.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Institucion.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getInstituciones: $e');
      return [];
    }
  }

  // ==================== MENSAJES ====================
  
  static Future<List<Mensaje>> getMensajes() async {
    try {
      if (await shouldUseLocalDatabase()) {
        final db = await LocalDatabaseService().database;
        final List<Map<String, dynamic>> maps = await db.query('mensajes');
        return maps.map((map) => Mensaje.fromMap(map)).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/mensajes.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Mensaje.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getMensajes: $e');
      return [];
    }
  }

  // ==================== USUARIOS ====================
  
  static Future<List<Usuario>> getUsuarios() async {
    try {
      if (await shouldUseLocalDatabase()) {
        final db = await LocalDatabaseService().database;
        final List<Map<String, dynamic>> maps = await db.query('usuarios');
        return maps.map((map) => Usuario.fromMap(map)).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/usuarios.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Usuario.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getUsuarios: $e');
      return [];
    }
  }

  // ==================== CATEGORÍAS ====================
  
  static Future<List<CategoriaTabla>> getCategoriasTabla() async {
    try {
      if (await shouldUseLocalDatabase()) {
        final db = await LocalDatabaseService().database;
        final List<Map<String, dynamic>> maps = await db.query('tabla_categorias');
        return maps.map((map) => CategoriaTabla.fromMap(map)).toList();
      }
      
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/controllers/tabla_categorias.php'),
      ).timeout(const Duration(seconds: Config.timeoutSeconds));
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => CategoriaTabla.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      Logger.error('Error en getCategoriasTabla: $e');
      return [];
    }
  }
}