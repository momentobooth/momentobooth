import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_shaders/flutter_shaders.dart';

class ShaderViewer extends StatefulWidget {

  final String assetKey;
  final double timeDilation;

  const ShaderViewer({super.key, required this.assetKey, this.timeDilation = 1});

  @override
  State<ShaderViewer> createState() => _ShaderViewerState();

}

class _ShaderViewerState extends State<ShaderViewer> with SingleTickerProviderStateMixin {

  late Ticker _shaderTicket;
  double _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _shaderTicket = createTicker((elapsed) {
      setState(() => _elapsedSeconds = elapsed.inMicroseconds / 1000000 / timeDilation);
    })..start();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderBuilder(
      assetKey: widget.assetKey,
      (context, shader, child) {
        return CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _ShaderPainter(shader, _elapsedSeconds),
        );
      },
    );
  }

  @override
  void dispose() {
    _shaderTicket.dispose();
    super.dispose();
  }

}

class _ShaderPainter extends CustomPainter {

  final FragmentShader shader;
  final double iTime;

  _ShaderPainter(this.shader, this.iTime);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..shader = shader;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, iTime);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;

}
