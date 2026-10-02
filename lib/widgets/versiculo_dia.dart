import 'package:flutter/material.dart';

class VersiculoDelDia extends StatelessWidget {
  const VersiculoDelDia({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2), // CORREGIDO
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3), // CORREGIDO
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            '"Porque donde están dos o tres congregados en mi nombre, allí estoy yo en medio de ellos."',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Mateo 18:20',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9), // CORREGIDO
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}