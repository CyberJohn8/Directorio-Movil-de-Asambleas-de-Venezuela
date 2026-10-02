import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import '../models/asamblea.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal() {
    // Inicializar sqflite para plataformas no móviles (no ejecutar en web)
    if (!kIsWeb) {
      if (!Platform.isAndroid && !Platform.isIOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }
  }

  static Database? _database;

  // Nombre de la base de datos
  final String dbName = 'directorio.db';
  
  // Nombre de la tabla
  final String tablaAsambleas = 'asambleas';
  
  // Versión de la base de datos (incrementar cuando cambie la estructura)
  final int dbVersion = 1;

  // Getter para la base de datos (inicializa si es necesario)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializar la base de datos
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), dbName);
    
    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Crear tablas cuando se crea la base de datos por primera vez
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tablaAsambleas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        ciudad TEXT NOT NULL,
        estado TEXT NOT NULL,
        pastor TEXT NOT NULL,
        telefono TEXT NOT NULL,
        horario TEXT NOT NULL,
        miembros INTEGER NOT NULL,
        direccion TEXT NOT NULL,
        latitud REAL,
        longitud REAL,
        email TEXT,
        sitioWeb TEXT,
        horariosAdicionales TEXT,
        fechaFundacion TEXT
      )
    ''');
    
    // Insertar datos iniciales
    await _insertarDatosIniciales(db);
  }

  // Actualizar base de datos cuando cambia la versión
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Aquí puedes manejar migraciones si cambia la estructura
    if (oldVersion < 2) {
      // Ejemplo: agregar nueva columna
      // await db.execute('ALTER TABLE $tablaAsambleas ADD COLUMN nuevaColumna TEXT');
    }
  }

  // Insertar datos iniciales de ejemplo
  Future<void> _insertarDatosIniciales(Database db) async {
    final List<Map<String, dynamic>> asambleasIniciales = [
      {
        'nombre': 'Asamblea Cristiana de Caracas',
        'ciudad': 'Caracas',
        'estado': 'Distrito Capital',
        'pastor': 'Juan Pérez',
        'telefono': '0212-1234567',
        'horario': 'Dom 10:00 AM | Mié 7:00 PM',
        'miembros': 250,
        'direccion': 'Av. Principal de Las Mercedes, Edif. Bet-el, Caracas',
        'latitud': 10.4806,
        'longitud': -66.9036,
        'email': 'caracas@asambleacristiana.org',
        'sitioWeb': 'www.asambleacaracas.org',
        'horariosAdicionales': 'Sábados 6:00 PM (Jóvenes)',
        'fechaFundacion': '1985-03-15',
      },
      {
        'nombre': 'Asamblea Cristiana de Maracaibo',
        'ciudad': 'Maracaibo',
        'estado': 'Zulia',
        'pastor': 'María González',
        'telefono': '0261-7654321',
        'horario': 'Dom 9:30 AM | Mar 7:00 PM',
        'miembros': 180,
        'direccion': 'Calle 72 con Av. 3, Sector Bella Vista, Maracaibo',
        'latitud': 10.6553,
        'longitud': -71.6445,
        'email': 'maracaibo@asambleacristiana.org',
        'sitioWeb': 'www.asambleamaracaibo.org',
        'horariosAdicionales': 'Jueves 7:00 PM (Estudio Bíblico)',
        'fechaFundacion': '1990-08-22',
      },
      {
        'nombre': 'Asamblea Cristiana de Valencia',
        'ciudad': 'Valencia',
        'estado': 'Carabobo',
        'pastor': 'Carlos Rodríguez',
        'telefono': '0241-9876543',
        'horario': 'Dom 11:00 AM | Jue 7:00 PM',
        'miembros': 320,
        'direccion': 'Av. Bolívar Norte, Centro Cristiano, Valencia',
        'latitud': 10.1806,
        'longitud': -68.0039,
        'email': 'valencia@asambleacristiana.org',
        'sitioWeb': 'www.asambleavalencia.org',
        'horariosAdicionales': 'Miércoles 7:00 PM (Oración)',
        'fechaFundacion': '1978-11-03',
      },
      {
        'nombre': 'Asamblea Cristiana de Barquisimeto',
        'ciudad': 'Barquisimeto',
        'estado': 'Lara',
        'pastor': 'Ana Martínez',
        'telefono': '0251-4567890',
        'horario': 'Dom 10:30 AM | Mié 7:30 PM',
        'miembros': 195,
        'direccion': 'Carrera 19 entre calles 25 y 26, Barquisimeto',
        'latitud': 10.0731,
        'longitud': -69.3227,
        'email': 'barquisimeto@asambleacristiana.org',
        'sitioWeb': 'www.asambleabarquisimeto.org',
        'horariosAdicionales': 'Viernes 6:30 PM (Escuela de Líderes)',
        'fechaFundacion': '1982-05-19',
      },
      {
        'nombre': 'Asamblea Cristiana de San Cristóbal',
        'ciudad': 'San Cristóbal',
        'estado': 'Táchira',
        'pastor': 'Pedro Sánchez',
        'telefono': '0276-3456789',
        'horario': 'Dom 9:00 AM | Mié 7:00 PM',
        'miembros': 150,
        'direccion': 'Av. Carabobo, Sector La Concordia, San Cristóbal',
        'latitud': 7.7722,
        'longitud': -72.2250,
        'email': 'sancristobal@asambleacristiana.org',
        'sitioWeb': 'www.asambleasancristobal.org',
        'horariosAdicionales': 'Sábados 5:00 PM (Adolescentes)',
        'fechaFundacion': '1995-09-10',
      },
      {
        'nombre': 'Asamblea Cristiana de Puerto La Cruz',
        'ciudad': 'Puerto La Cruz',
        'estado': 'Anzoátegui',
        'pastor': 'Luisa Fernández',
        'telefono': '0281-5678901',
        'horario': 'Dom 10:00 AM | Mar 7:00 PM',
        'miembros': 210,
        'direccion': 'Av. Municipal, Sector Lechería, Puerto La Cruz',
        'latitud': 10.2083,
        'longitud': -64.6325,
        'email': 'puertolacruz@asambleacristiana.org',
        'sitioWeb': 'www.asambleapuertolacruz.org',
        'horariosAdicionales': 'Jueves 7:00 PM (Estudio Bíblico)',
        'fechaFundacion': '1988-12-05',
      },
      {
        'nombre': 'Asamblea Cristiana de Mérida',
        'ciudad': 'Mérida',
        'estado': 'Mérida',
        'pastor': 'José Contreras',
        'telefono': '0274-2345678',
        'horario': 'Dom 9:30 AM | Mié 7:00 PM',
        'miembros': 120,
        'direccion': 'Av. Universidad, Sector Milla, Mérida',
        'latitud': 8.5983,
        'longitud': -71.1447,
        'email': 'merida@asambleacristiana.org',
        'sitioWeb': 'www.asambleamerida.org',
        'horariosAdicionales': 'Viernes 6:00 PM (Jóvenes)',
        'fechaFundacion': '2000-03-25',
      },
      {
        'nombre': 'Asamblea Cristiana de Barcelona',
        'ciudad': 'Barcelona',
        'estado': 'Anzoátegui',
        'pastor': 'Rosa Mendoza',
        'telefono': '0281-6789012',
        'horario': 'Dom 11:00 AM | Jue 7:00 PM',
        'miembros': 165,
        'direccion': 'Av. Principal de Barcelona, Centro, Barcelona',
        'latitud': 10.1363,
        'longitud': -64.6862,
        'email': 'barcelona@asambleacristiana.org',
        'sitioWeb': 'www.asambleabarcelona.org',
        'horariosAdicionales': 'Sábados 6:00 PM (Escuela Bíblica)',
        'fechaFundacion': '1992-07-14',
      },
    ];

    for (var asamblea in asambleasIniciales) {
      await db.insert(tablaAsambleas, asamblea);
    }
  }

  // --- OPERACIONES CRUD ---

  // Obtener todas las asambleas
  Future<List<Asamblea>> obtenerTodasLasAsambleas() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablaAsambleas,
      orderBy: 'nombre ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Asamblea.fromJson(maps[i]);
    });
  }

  // Obtener asambleas con filtros
  Future<List<Asamblea>> obtenerAsambleasFiltradas({
    String? busqueda,
    String? estado,
  }) async {
    Database db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (busqueda != null && busqueda.isNotEmpty) {
      whereClause += 'nombre LIKE ? OR ciudad LIKE ? OR pastor LIKE ?';
      whereArgs.addAll(['%$busqueda%', '%$busqueda%', '%$busqueda%']);
    }

    if (estado != null && estado != 'Todos') {
      if (whereClause.isNotEmpty) {
        whereClause += ' AND ';
      }
      whereClause += 'estado = ?';
      whereArgs.add(estado);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      tablaAsambleas,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'nombre ASC',
    );

    return List.generate(maps.length, (i) {
      return Asamblea.fromJson(maps[i]);
    });
  }

  // Obtener una asamblea por ID
  Future<Asamblea?> obtenerAsambleaPorId(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tablaAsambleas,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Asamblea.fromJson(maps.first);
    }
    return null;
  }

  // Insertar nueva asamblea
  Future<int> insertarAsamblea(Asamblea asamblea) async {
    Database db = await database;
    return await db.insert(tablaAsambleas, asamblea.toJson());
  }

  // Actualizar asamblea existente
  Future<int> actualizarAsamblea(Asamblea asamblea) async {
    Database db = await database;
    return await db.update(
      tablaAsambleas,
      asamblea.toJson(),
      where: 'id = ?',
      whereArgs: [asamblea.id],
    );
  }

  // Eliminar asamblea
  Future<int> eliminarAsamblea(int id) async {
    Database db = await database;
    return await db.delete(
      tablaAsambleas,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Obtener estados únicos para filtros
  Future<List<String>> obtenerEstadosUnicos() async {
    Database db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT DISTINCT estado FROM $tablaAsambleas ORDER BY estado ASC'
    );
    
    return result.map((map) => map['estado'] as String).toList();
  }

  // Contar total de asambleas
  Future<int> contarAsambleas() async {
    Database db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $tablaAsambleas');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Cerrar la base de datos
  Future<void> cerrar() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}