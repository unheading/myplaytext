import 'package:flutter/material.dart';

class LoadingGif extends StatelessWidget {
  final double size;

  const LoadingGif({super.key, this.size = 46});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/assets/loading.gif',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.low,
    );
  }
}

