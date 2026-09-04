import 'dart:io';

import 'package:flutter/material.dart';

/// Muestra la foto de un carro venga de donde venga.
///
/// Tres origenes: `assets/...` son las ilustraciones de los datos de prueba,
/// `http...` es una URL —lo que devolvera Roble— y cualquier otra cosa es un
/// fichero local recien elegido con el selector de imagenes. Sin foto, se
/// pinta un color de relleno.
class CarPhoto extends StatelessWidget {
  const CarPhoto({super.key, required this.source, this.fit = BoxFit.cover});

  final String? source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final path = source;
    if (path == null || path.isEmpty) return const _Placeholder(seed: '');
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _Placeholder(seed: path),
      );
    }
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (_, _, _) => _Placeholder(seed: path),
      );
    }
    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (_, _, _) => _Placeholder(seed: path),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    // Un degradado estable por publicacion: la misma foto se ve siempre igual.
    final hue = (seed.hashCode.abs() % 360).toDouble();
    final base = HSLColor.fromAHSL(1, hue, 0.32, 0.62).toColor();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, HSLColor.fromAHSL(1, hue, 0.35, 0.38).toColor()],
        ),
      ),
      child: const Center(
        child: Icon(Icons.directions_car, size: 44, color: Colors.white70),
      ),
    );
  }
}
