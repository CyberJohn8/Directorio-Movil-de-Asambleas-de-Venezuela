// lib/services/backup_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/iglesia.dart';
import '../models/book.dart';
import '../models/verse.dart';
import '../models/himno.dart';
import '../models/corito.dart';
import '../models/sitio_web.dart';
import '../models/sitio_web_otros.dart';
import '../config/backup_config.dart';

class BackupService {
  static const String backupFolderName = 'backup_data';
  static const String backupDateKey = 'last_backup_date';
  static const String backupVersionKey = 'backup_version';
  
  // Versión actual del respaldo
  static const String currentVersion = '1.0.0';
  
  // ==================== MÉTODOS GENERALES ====================
  
  // Obtener el directorio de respaldo
  static Future<Directory> getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/$backupFolderName');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }
  
  // Guardar cualquier tipo de datos como respaldo
  static Future<void> saveBackupData(String fileName, dynamic data) async {
    try {
      final backupDir = await getBackupDirectory();
      final file = File('${backupDir.path}/$fileName');
      
      String jsonString;
      if (data is List) {
        jsonString = json.encode(data.map((item) => 
          item is Map ? item : item.toJson()
        ).toList());
      } else if (data is Map) {
        jsonString = json.encode(data);
      } else {
        jsonString = json.encode(data);
      }
      
      await file.writeAsString(jsonString);
      
      // Actualizar la fecha del último respaldo
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(backupDateKey, DateTime.now().toIso8601String());
      await prefs.setString(backupVersionKey, currentVersion);
      
      if (kDebugMode) {
        debugPrint('✅ Respaldo guardado: $fileName (${file.path})');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error guardando respaldo $fileName: $e');
      }
      rethrow;
    }
  }
  
  // ==================== CARGAR DATOS DE RESPALDO ====================
  static Future<dynamic> loadBackupData(String fileName) async {
    try {
      final backupDir = await getBackupDirectory();
      final file = File('${backupDir.path}/$fileName');
      
      // Intentar cargar desde documentos
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Respaldo cargado: $fileName (desde documentos, ${content.length} bytes)');
          }
          final decoded = json.decode(content);
          // Si es un objeto único, lo convertimos a lista para uniformidad
          if (decoded is Map<String, dynamic>) {
            return [decoded];
          }
          return decoded;
        }
      }
      
      // Si no existe en documentos o está vacío, cargar desde assets
      final assetPath = '${BackupConfig.backupDirectory}/$fileName';
      try {
        final content = await rootBundle.loadString(assetPath);
        if (content.isNotEmpty) {
          if (kDebugMode) {
            debugPrint('✅ Respaldo cargado: $fileName (desde assets, ${content.length} bytes)');
          }
          // Guardar una copia en documentos para futuros usos
          try {
            await file.writeAsString(content);
          } catch (e) {
            // Ignorar errores al guardar (permisos, etc.)
            if (kDebugMode) {
              debugPrint('⚠️ No se pudo guardar copia local de $fileName: $e');
            }
          }
          final decoded = json.decode(content);
          // Si es un objeto único, lo convertimos a lista para uniformidad
          if (decoded is Map<String, dynamic>) {
            return [decoded];
          }
          return decoded;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ No se encontró $fileName en assets: $e');
        }
      }
      
      // Si no hay datos, retornar una lista vacía
      if (kDebugMode) {
        debugPrint('⚠️ No se encontraron datos en $fileName');
      }
      return [];
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando respaldo $fileName: $e');
      }
      return [];
    }
  }
  
  // Verificar si existe respaldo para un archivo específico
  static Future<bool> hasBackupData(String fileName) async {
    try {
      final backupDir = await getBackupDirectory();
      final file = File('${backupDir.path}/$fileName');
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  // Verificar si hay respaldos disponibles
  static Future<bool> hasAnyBackup() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = await backupDir.list().toList();
      return files.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  // ==================== MÉTODOS ESPECÍFICOS ====================
  
  // Cargar iglesias de respaldo
  static Future<List<Iglesia>> loadIglesiasBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.iglesiasFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => Iglesia.fromJson(json)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de iglesias en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando iglesias de respaldo: $e');
      }
      return [];
    }
  }
  
  // Guardar iglesias como respaldo
  static Future<void> saveIglesiasBackup(List<Iglesia> iglesias) async {
    await saveBackupData(BackupConfig.iglesiasFile, iglesias);
  }
  
  // Cargar libros de respaldo
  static Future<List<Book>> loadBooksBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.booksFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => Book.fromJson(json)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de libros en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando libros de respaldo: $e');
      }
      return [];
    }
  }
  
  // Cargar versículos de respaldo
  static Future<List<Verse>> loadVersesBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.versesFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => Verse.fromJson(json)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de versículos en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando versículos de respaldo: $e');
      }
      return [];
    }
  }
  
  // Cargar himnos de respaldo
  static Future<List<Himno>> loadHimnosBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.himnosFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => Himno.fromJson(json)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de himnos en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando himnos de respaldo: $e');
      }
      return [];
    }
  }
  
  // Cargar coritos de respaldo
  static Future<List<Corito>> loadCoritosBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.coritosFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => Corito.fromJson(json)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de coritos en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando coritos de respaldo: $e');
      }
      return [];
    }
  }
  
  // Cargar sitios web de respaldo
  static Future<List<SitioWeb>> loadSitiosWebBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.sitiosWebFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => SitioWeb.fromJson(json)).toList();
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de sitios web en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando sitios web de respaldo: $e');
      }
      return [];
    }
  }
  
  // ==================== CORREGIDO: Cargar sitios web otros de respaldo ====================
  static Future<List<SitioWebOtros>> loadSitiosWebOtrosBackup() async {
    try {
      final data = await loadBackupData(BackupConfig.sitiosWebOtrosFile);
      if (data is List && data.isNotEmpty) {
        return data.map((json) => SitioWebOtros.fromJson(json)).toList(); // 👈 CORREGIDO
      }
      if (kDebugMode) {
        debugPrint('⚠️ No hay datos de otros sitios web en el respaldo');
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error cargando otros sitios web de respaldo: $e');
      }
      return [];
    }
  }
  
  // ==================== INICIALIZACIÓN ====================
  
  // Inicializar respaldos desde assets
  static Future<void> initializeBackups() async {
    try {
      final backupDir = await getBackupDirectory();
      final files = await backupDir.list().toList();
      
      // Si no hay respaldos, crear desde assets
      if (files.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔄 Creando respaldos iniciales desde assets...');
        }
        
        for (var type in BackupConfig.dataTypes) {
          try {
            final fileName = BackupConfig.getDataTypeToFileMap()[type];
            if (fileName != null) {
              final data = await loadBackupData(fileName);
              // Solo guardar si hay datos
              if (data is List && data.isNotEmpty) {
                await saveBackupData(fileName, data);
                if (kDebugMode) {
                  debugPrint('✅ Respaldo creado para: $fileName (${data.length} registros)');
                }
              } else if (data is Map && data.isNotEmpty) {
                await saveBackupData(fileName, [data]);
                if (kDebugMode) {
                  debugPrint('✅ Respaldo creado para: $fileName (1 registro)');
                }
              } else {
                if (kDebugMode) {
                  debugPrint('⚠️ No hay datos para crear respaldo de: $fileName');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ No se pudo crear respaldo para $type: $e');
            }
          }
        }
        
        // Guardar fecha de inicialización
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(backupDateKey, DateTime.now().toIso8601String());
        await prefs.setString(backupVersionKey, currentVersion);
        
        if (kDebugMode) {
          debugPrint('✅ Respaldo inicial completado');
        }
      } else {
        if (kDebugMode) {
          debugPrint('📦 Respaldo existente encontrado (${files.length} archivos)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error inicializando respaldos: $e');
      }
    }
  }
  
  // ==================== UTILIDADES ====================
  
  // Obtener información del respaldo
  static Future<Map<String, dynamic>> getBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupDir = await getBackupDirectory();
      final files = await backupDir.list().toList();
      
      final lastBackupDate = prefs.getString(backupDateKey);
      final version = prefs.getString(backupVersionKey);
      
      // Obtener tamaño de cada archivo
      Map<String, int> fileSizes = {};
      for (var file in files) {
        try {
          final stat = await file.stat();
          fileSizes[file.path.split('/').last] = stat.size;
        } catch (e) {
          // Ignorar errores al obtener tamaño
        }
      }
      
      return {
        'exists': files.isNotEmpty,
        'fileCount': files.length,
        'fileSizes': fileSizes,
        'lastBackupDate': lastBackupDate != null 
            ? DateTime.parse(lastBackupDate) 
            : null,
        'version': version ?? 'unknown',
        'files': files.map((f) => f.path.split('/').last).toList(),
      };
    } catch (e) {
      return {
        'exists': false,
        'error': e.toString(),
      };
    }
  }
  
  // Verificar la integridad de los respaldos
  static Future<Map<String, bool>> verifyBackups() async {
    final result = <String, bool>{};
    const types = BackupConfig.dataTypes;
    
    for (var type in types) {
      final fileName = BackupConfig.getDataTypeToFileMap()[type];
      if (fileName != null) {
        try {
          final data = await loadBackupData(fileName);
          final isValid = data is List && data.isNotEmpty;
          result[fileName] = isValid;
          if (kDebugMode) {
            debugPrint('📋 Verificación $fileName: ${isValid ? "✅ OK" : "❌ Vacío"}');
          }
        } catch (e) {
          result[fileName] = false;
          if (kDebugMode) {
            debugPrint('📋 Verificación $fileName: ❌ Error - $e');
          }
        }
      }
    }
    
    return result;
  }
  
  // Recargar respaldos desde assets (sobrescribe los locales)
  static Future<void> reloadFromAssets() async {
    try {
      if (kDebugMode) {
        debugPrint('🔄 Recargando respaldos desde assets...');
      }
      
      for (var type in BackupConfig.dataTypes) {
        try {
          final fileName = BackupConfig.getDataTypeToFileMap()[type];
          if (fileName != null) {
            final backupDir = await getBackupDirectory();
            final file = File('${backupDir.path}/$fileName');
            
            // Cargar desde assets
            final assetPath = '${BackupConfig.backupDirectory}/$fileName';
            final content = await rootBundle.loadString(assetPath);
            
            if (content.isNotEmpty) {
              await file.writeAsString(content);
              if (kDebugMode) {
                debugPrint('✅ Respaldo recargado: $fileName');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('⚠️ No se pudo recargar $type: $e');
          }
        }
      }
      
      // Actualizar fecha
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(backupDateKey, DateTime.now().toIso8601String());
      
      if (kDebugMode) {
        debugPrint('✅ Respaldos recargados completamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error recargando respaldos: $e');
      }
    }
  }
}