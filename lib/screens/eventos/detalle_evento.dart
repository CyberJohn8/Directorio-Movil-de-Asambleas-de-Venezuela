// Detalle de evento aún no implementado.
// Agregar aquí el diseño y contenido de la pantalla de detalle.



import 'package:flutter/material.dart';

class DetalleEventoScreen extends StatelessWidget {
  final Map<String, dynamic>? evento;
  
  const DetalleEventoScreen({super.key, this.evento});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Evento'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(evento?.toString() ?? 'Evento no encontrado'),
      ),
    );
  }
}