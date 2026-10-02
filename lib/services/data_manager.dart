// lib/services/data_manager.dart
import 'package:flutter/foundation.dart';
import 'backup_service.dart';
import 'local_database_service.dart';
import '../models/iglesia.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../models/himno.dart';
import '../models/corito.dart';
import '../models/sitio_web.dart';
import '../models/sitio_web_otros.dart';

class DataManager {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();
  
  // Estados de conexión
  bool _dbAvailable = true;
  bool get dbAvailable => _dbAvailable;
  
  // Cache para datos
  List<Iglesia>? _cachedIglesias;
  List<Book>? _cachedBooks;
  List<Verse>? _cachedVerses;
  List<Himno>? _cachedHimnos;
  List<Corito>? _cachedCoritos;
  List<SitioWeb>? _cachedSitiosWeb;
  List<SitioWebOtros>? _cachedSitiosWebOtros; // 👈 Tipo correcto
  
  // Tiempos de expiración del cache (5 minutos)
  static const Duration cacheExpiration = Duration(minutes: 5);
  DateTime? _cacheTime;
  
  // ==================== INICIALIZACIÓN ====================
  
  Future<void> initialize() async {
    try {
      _dbAvailable = await checkDatabaseAvailability();
      await BackupService.initializeBackups();
      
      if (kDebugMode) {
        debugPrint('✅ DataManager inicializado. DB disponible: $_dbAvailable');
        final backupInfo = await BackupService.getBackupInfo();
        debugPrint('📦 Info respaldo: $backupInfo');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando DataManager: $e');
      }
      _dbAvailable = false;
    }
  }
  
  // ==================== VERIFICACIÓN ====================
  
  Future<bool> checkDatabaseAvailability() async {
    try {
      final db = await LocalDatabaseService().database;
      await db.execute('SELECT 1');
      return true;
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Base de datos no disponible: $e');
      }
      return false;
    }
  }
  
  // CORREGIDO: Eliminada la comparación innecesaria
  bool isCacheValid() {
    if (_cacheTime == null) return false;
    final difference = DateTime.now().difference(_cacheTime!);
    return difference < cacheExpiration;
  }
  
  void invalidateCache() {
    _cachedIglesias = null;
    _cachedBooks = null;
    _cachedVerses = null;
    _cachedHimnos = null;
    _cachedCoritos = null;
    _cachedSitiosWeb = null;
    _cachedSitiosWebOtros = null;
    _cacheTime = null;
  }
  
  // ==================== OBTENER DATOS ====================
  
  // OBTENER IGLESIAS
  Future<List<Iglesia>> getIglesias({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedIglesias != null && isCacheValid()) {
        if (kDebugMode) {
          debugPrint('📦 Usando cache de iglesias (${_cachedIglesias!.length})');
        }
        return _cachedIglesias!;
      }
      
      List<Iglesia> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('iglesias');
          result = data.map((row) => Iglesia.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            if (kDebugMode) {
              debugPrint('✅ Iglesias cargadas desde DB (${result.length})');
            }
            _cachedIglesias = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ Error cargando iglesias desde DB: $e');
          }
          _dbAvailable = false;
        }
      }
      
      if (kDebugMode) {
        debugPrint('🔄 Usando respaldo para iglesias');
      }
      result = await BackupService.loadIglesiasBackup();
      
      if (result.isNotEmpty) {
        _cachedIglesias = result;
        _cacheTime = DateTime.now();
        if (kDebugMode) {
          debugPrint('✅ Iglesias cargadas desde respaldo (${result.length})');
        }
        return result;
      }
      
      if (kDebugMode) {
        debugPrint('⚠️ No se encontraron datos de iglesias');
      }
      return [];
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error obteniendo iglesias: $e');
      }
      return [];
    }
  }
  
  // OBTENER LIBROS
  Future<List<Book>> getBooks({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedBooks != null && isCacheValid()) {
        return _cachedBooks!;
      }
      
      List<Book> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('books');
          result = data.map((row) => Book.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            _cachedBooks = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          _dbAvailable = false;
        }
      }
      
      result = await BackupService.loadBooksBackup();
      if (result.isNotEmpty) {
        _cachedBooks = result;
        _cacheTime = DateTime.now();
        return result;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // OBTENER VERSÍCULOS
  Future<List<Verse>> getVerses({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedVerses != null && isCacheValid()) {
        return _cachedVerses!;
      }
      
      List<Verse> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('verses');
          result = data.map((row) => Verse.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            _cachedVerses = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          _dbAvailable = false;
        }
      }
      
      result = await BackupService.loadVersesBackup();
      if (result.isNotEmpty) {
        _cachedVerses = result;
        _cacheTime = DateTime.now();
        return result;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // OBTENER HIMNOS
  Future<List<Himno>> getHimnos({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedHimnos != null && isCacheValid()) {
        return _cachedHimnos!;
      }
      
      List<Himno> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('himnos');
          result = data.map((row) => Himno.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            _cachedHimnos = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          _dbAvailable = false;
        }
      }
      
      result = await BackupService.loadHimnosBackup();
      if (result.isNotEmpty) {
        _cachedHimnos = result;
        _cacheTime = DateTime.now();
        return result;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // OBTENER CORITOS
  Future<List<Corito>> getCoritos({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedCoritos != null && isCacheValid()) {
        return _cachedCoritos!;
      }
      
      List<Corito> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('coritos');
          result = data.map((row) => Corito.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            _cachedCoritos = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          _dbAvailable = false;
        }
      }
      
      result = await BackupService.loadCoritosBackup();
      if (result.isNotEmpty) {
        _cachedCoritos = result;
        _cacheTime = DateTime.now();
        return result;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // OBTENER SITIOS WEB
  Future<List<SitioWeb>> getSitiosWeb({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedSitiosWeb != null && isCacheValid()) {
        return _cachedSitiosWeb!;
      }
      
      List<SitioWeb> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('sitios_web');
          result = data.map((row) => SitioWeb.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            _cachedSitiosWeb = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          _dbAvailable = false;
        }
      }
      
      result = await BackupService.loadSitiosWebBackup();
      if (result.isNotEmpty) {
        _cachedSitiosWeb = result;
        _cacheTime = DateTime.now();
        return result;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // OBTENER SITIOS WEB OTROS - CORREGIDO
  Future<List<SitioWebOtros>> getSitiosWebOtros({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _cachedSitiosWebOtros != null && isCacheValid()) {
        return _cachedSitiosWebOtros!;
      }
      
      List<SitioWebOtros> result = [];
      
      if (_dbAvailable) {
        try {
          final db = await LocalDatabaseService().database;
          final data = await db.query('sitios_web_otros');
          result = data.map((row) => SitioWebOtros.fromMap(row)).toList();
          
          if (result.isNotEmpty) {
            _cachedSitiosWebOtros = result;
            _cacheTime = DateTime.now();
            return result;
          }
        } catch (e) {
          _dbAvailable = false;
        }
      }
      
      // CORREGIDO: Usar el método correcto de BackupService
      result = await BackupService.loadSitiosWebOtrosBackup();
      if (result.isNotEmpty) {
        _cachedSitiosWebOtros = result;
        _cacheTime = DateTime.now();
        return result;
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }
  
  // ==================== MÉTODOS DE UTILIDAD ====================
  
  Future<void> checkDbConnection() async {
    _dbAvailable = await checkDatabaseAvailability();
    if (!_dbAvailable) {
      if (kDebugMode) {
        debugPrint('⚠️ Base de datos no disponible, usando respaldos');
      }
    }
  }
  
  Future<void> refreshAllData() async {
    invalidateCache();
    await checkDbConnection();
    await getIglesias(forceRefresh: true);
    await getBooks(forceRefresh: true);
    await getVerses(forceRefresh: true);
    await getHimnos(forceRefresh: true);
    await getCoritos(forceRefresh: true);
    await getSitiosWeb(forceRefresh: true);
    await getSitiosWebOtros(forceRefresh: true);
  }
}