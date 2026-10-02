import 'package:flutter/material.dart';

class LectorPDFScreen extends StatelessWidget {
  final String pdfUrl;
  
  const LectorPDFScreen({
    super.key,
    required this.pdfUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar del lector de PDF
      appBar: AppBar(
        title: const Text('Lector PDF'),
        backgroundColor: const Color(0xFF637983),
        foregroundColor: Colors.white,
      ),
      body: Center(
        // Área de contenido principal del lector de PDF
        child: Text('Leyendo PDF: $pdfUrl'),
      ),
    );
  }
}