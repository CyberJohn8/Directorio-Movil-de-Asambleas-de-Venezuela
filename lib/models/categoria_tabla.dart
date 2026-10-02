class CategoriaTabla {
  final String tabla;
  final String categoria;

  CategoriaTabla({
    required this.tabla,
    required this.categoria,
  });

  factory CategoriaTabla.fromJson(Map<String, dynamic> json) {
    return CategoriaTabla(
      tabla: json['tabla'] ?? '',
      categoria: json['categoria'] ?? '',
    );
  }

  // Para SQLite (Map local)
  factory CategoriaTabla.fromMap(Map<String, dynamic> map) => CategoriaTabla.fromJson(map);
}
