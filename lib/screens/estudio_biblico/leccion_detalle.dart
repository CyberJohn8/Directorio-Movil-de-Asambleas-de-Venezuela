import 'package:flutter/material.dart';

class LeccionDetalleScreen extends StatelessWidget {
  final int leccionId;
  
  const LeccionDetalleScreen({
    super.key,
    required this.leccionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar de detalle de lección
      appBar: AppBar(
        title: Text('Lección $leccionId'),
        backgroundColor: const Color(0xFF637983),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text('Detalle de la lección $leccionId'),
      ),
    );
  }
}