// lib/services/local_database_service.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;

  // Obtener la base de datos
  Future<Database> get database async {
    final db = _database;
    if (db != null) return db;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos desde el archivo SQL
  Future<Database> _initDatabase() async {
    try {
      // Obtener la ruta de la base de datos
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, 'directorio_local.db');
      
      if (kDebugMode) {
        debugPrint('📁 Ruta de la base de datos local: $path');
      }

      // Verificar si ya existe la base de datos
      bool dbExists = await File(path).exists();
      
      // Abrir la base de datos
      Database db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      
      // Si la base de datos no existía, cargar el archivo SQL
      if (!dbExists) {
        await _loadSqlFile(db);
      } else {
        // Si ya existe, verificar que tenga datos
        await _verificarYDatos(db);
      }

      return db;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al inicializar base de datos local: $e');
      }
      rethrow;
    }
  }

  // Crear la base de datos desde cero
  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      debugPrint('🔄 Creando nueva base de datos local...');
    }
  }

  // Actualizar la base de datos
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      debugPrint('🔄 Actualizando base de datos local de $oldVersion a $newVersion...');
    }
  }

  // Verificar y cargar datos si es necesario
  Future<void> _verificarYDatos(Database db) async {
    try {
      final countResult = await db.query('iglesias');
      // CORREGIDO: Eliminada la comparación innecesaria
      // countResult nunca es null, solo puede estar vacío
      if (countResult.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ La base de datos existe pero no tiene datos. Recargando...');
        }
        await _loadSqlFile(db);
      } else {
        if (kDebugMode) {
          debugPrint('✅ La base de datos ya tiene ${countResult.length} iglesias');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error verificando datos: $e');
      }
    }
  }

  // Cargar el archivo SQL
  Future<void> _loadSqlFile(Database db) async {
    try {
      if (kDebugMode) {
        debugPrint('📄 Cargando archivo SQL...');
      }

      // Leer el archivo SQL desde assets
      String sqlContent = await _readSqlFile();
      
      if (sqlContent.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ El archivo SQL está vacío, usando SQL por defecto');
        }
        sqlContent = _getDefaultSql();
      }

      // Dividir el SQL en statements individuales
      List<String> statements = _splitSqlStatements(sqlContent);
      
      if (kDebugMode) {
        debugPrint('📊 Ejecutando ${statements.length} statements SQL...');
      }

      // Ejecutar cada statement
      for (String statement in statements) {
        if (statement.trim().isNotEmpty) {
          try {
            await db.execute(statement);
          } catch (e) {
            if (kDebugMode) {
              // Solo mostrar error si no es un error de tabla ya existente
              if (!e.toString().contains('already exists')) {
                debugPrint('⚠️ Error ejecutando statement: $e');
              }
            }
          }
        }
      }

      // VERIFICAR QUE LOS DATOS SE CARGARON
      try {
        final countResult = await db.query('iglesias');
        if (kDebugMode) {
          debugPrint('✅ ${countResult.length} iglesias cargadas en la base de datos local');
        }
        
        if (countResult.isEmpty) {
          // Si no hay datos, insertar datos de ejemplo
          await _insertarDatosEjemplo(db);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error verificando datos: $e');
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Base de datos local cargada exitosamente');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error al cargar archivo SQL: $e');
      }
      // Intentar insertar datos de ejemplo como último recurso
      try {
        await _insertarDatosEjemplo(db);
      } catch (e2) {
        if (kDebugMode) {
          debugPrint('❌ Error insertando datos de ejemplo: $e2');
        }
      }
      rethrow;
    }
  }

  // Insertar datos de ejemplo
  Future<void> _insertarDatosEjemplo(Database db) async {
    try {
      if (kDebugMode) {
        debugPrint('📝 Insertando datos de ejemplo en la base de datos local...');
      }
      
      // Primero, asegurar que la tabla existe
      await db.execute('''
        CREATE TABLE IF NOT EXISTS iglesias (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          asamblea TEXT NOT NULL,
          numero TEXT,
          estado TEXT NOT NULL,
          ciudad TEXT NOT NULL,
          direccion TEXT,
          telefono TEXT,
          email TEXT,
          latitud REAL,
          longitud REAL,
          horario TEXT,
          imagen TEXT
        )
      ''');
      
      // Datos de ejemplo
      final iglesiasEjemplo = [
        {
          'id': 1,
          'asamblea': 'Asamblea Cristiana Central',
          'numero': '001',
          'estado': 'Distrito Capital',
          'ciudad': 'Caracas',
          'direccion': 'Av. Principal, Caracas',
          'telefono': '0212-555-0001',
          'email': 'central@asamblea.org',
        },
        {
          'id': 2,
          'asamblea': 'Asamblea Cristiana del Este',
          'numero': '002',
          'estado': 'Miranda',
          'ciudad': 'Petare',
          'direccion': 'Calle 5, Petare',
          'telefono': '0212-555-0002',
          'email': 'este@asamblea.org',
        },
        {
          'id': 3,
          'asamblea': 'Asamblea Cristiana del Oeste',
          'numero': '003',
          'estado': 'Carabobo',
          'ciudad': 'Valencia',
          'direccion': 'Av. Bolívar, Valencia',
          'telefono': '0241-555-0003',
          'email': 'oeste@asamblea.org',
        },
        {
          'id': 4,
          'asamblea': 'Asamblea Cristiana del Sur',
          'numero': '004',
          'estado': 'Bolívar',
          'ciudad': 'Ciudad Bolívar',
          'direccion': 'Calle Real, Ciudad Bolívar',
          'telefono': '0285-555-0004',
          'email': 'sur@asamblea.org',
        },
        {
          'id': 5,
          'asamblea': 'Asamblea Cristiana del Norte',
          'numero': '005',
          'estado': 'Lara',
          'ciudad': 'Barquisimeto',
          'direccion': 'Av. Libertador, Barquisimeto',
          'telefono': '0251-555-0005',
          'email': 'norte@asamblea.org',
        },
      ];
      
      for (var iglesia in iglesiasEjemplo) {
        await db.insert('iglesias', iglesia, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      
      if (kDebugMode) {
        debugPrint('✅ ${iglesiasEjemplo.length} iglesias de ejemplo insertadas');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error insertando datos de ejemplo: $e');
      }
      rethrow;
    }
  }

  // SQL por defecto si no hay archivo
  String _getDefaultSql() {
    return '''
CREATE TABLE IF NOT EXISTS iglesias (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  asamblea TEXT NOT NULL,
  numero TEXT,
  estado TEXT NOT NULL,
  ciudad TEXT NOT NULL,
  direccion TEXT,
  telefono TEXT,
  email TEXT,
  latitud REAL,
  longitud REAL,
  horario TEXT,
  imagen TEXT
);

CREATE TABLE IF NOT EXISTS himnos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  numero INTEGER NOT NULL,
  titulo TEXT NOT NULL,
  contenido TEXT,
  autor TEXT,
  tono TEXT,
  categoria TEXT
);

CREATE TABLE IF NOT EXISTS sitios_web (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  url TEXT NOT NULL,
  descripcion TEXT,
  categoria TEXT,
  imagen TEXT
);

CREATE TABLE IF NOT EXISTS sitios_web_otros (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  url TEXT NOT NULL,
  descripcion TEXT,
  categoria TEXT,
  idioma TEXT
);

CREATE TABLE IF NOT EXISTS coritos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo TEXT NOT NULL,
  contenido TEXT,
  categoria TEXT,
  tonalidad TEXT
);

CREATE TABLE IF NOT EXISTS books (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  abreviatura TEXT,
  testament INTEGER DEFAULT 1,
  chapters INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS verses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  book_id INTEGER NOT NULL,
  chapter INTEGER NOT NULL,
  verse_number INTEGER NOT NULL,
  text TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS instituciones (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  direccion TEXT,
  telefono TEXT,
  email TEXT,
  website TEXT,
  categoria TEXT
);

CREATE TABLE IF NOT EXISTS mensajes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  titulo TEXT NOT NULL,
  contenido TEXT,
  autor TEXT,
  fecha TEXT,
  categoria TEXT,
  imagen TEXT,
  video_url TEXT
);

CREATE TABLE IF NOT EXISTS usuarios (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  telefono TEXT,
  rol TEXT,
  iglesia TEXT,
  foto TEXT
);

CREATE TABLE IF NOT EXISTS tabla_categorias (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  icono TEXT,
  orden INTEGER DEFAULT 0
);
''';
  }

  // Leer el archivo SQL desde assets
  Future<String> _readSqlFile() async {
    try {
      // Leer desde assets usando rootBundle
      String content = await rootBundle.loadString('assets/directorio.sql');
      if (kDebugMode) {
        debugPrint('✅ Archivo SQL leído desde assets (${content.length} caracteres)');
      }
      return content;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Error leyendo desde assets: $e');
      }
      return '';
    }
  }

  // Dividir statements SQL
  List<String> _splitSqlStatements(String sql) {
    List<String> statements = [];
    StringBuffer current = StringBuffer();
    bool inString = false;
    bool inComment = false;
    bool inLineComment = false;
    
    for (int i = 0; i < sql.length; i++) {
      String char = sql[i];
      
      // Manejar comentarios de bloque /* */
      if (char == '/' && i + 1 < sql.length && sql[i + 1] == '*') {
        inComment = true;
        i++;
        continue;
      }
      if (inComment && char == '*' && i + 1 < sql.length && sql[i + 1] == '/') {
        inComment = false;
        i++;
        continue;
      }
      if (inComment) continue;
      
      // Manejar comentarios de línea --
      if (char == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
        inLineComment = true;
        i++;
        continue;
      }
      if (inLineComment && char == '\n') {
        inLineComment = false;
        continue;
      }
      if (inLineComment) continue;
      
      // Manejar strings
      if (char == "'" && (i == 0 || sql[i-1] != '\\')) {
        inString = !inString;
        current.write(char);
        continue;
      }
      
      // Manejar punto y coma
      if (char == ';' && !inString) {
        String statement = current.toString().trim();
        if (statement.isNotEmpty) {
          statements.add(statement);
        }
        current.clear();
        continue;
      }
      
      current.write(char);
    }
    
    String lastStatement = current.toString().trim();
    if (lastStatement.isNotEmpty) {
      statements.add(lastStatement);
    }
    
    return statements;
  }

  // Verificar si la base de datos local está disponible
  static Future<bool> isAvailable() async {
    try {
      final db = await _instance.database;
      return db != null;
    } catch (e) {
      return false;
    }
  }

  // Cerrar la base de datos
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Verificar si una tabla existe
  static Future<bool> tableExists(String tableName) async {
    try {
      final db = await _instance.database;
      final result = await db.query(
        'sqlite_master',
        where: 'type = ? AND name = ?',
        whereArgs: ['table', tableName],
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Obtener el conteo de registros de una tabla
  static Future<int> getTableCount(String tableName) async {
    try {
      final db = await _instance.database;
      final result = await db.query(
        tableName,
        columns: ['COUNT(*) as count'],
      );
      if (result.isNotEmpty) {
        return result.first['count'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}