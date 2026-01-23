import 'package:flutter/material.dart';

class DoctorAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;

  const DoctorAvatar({
    super.key,
    this.imageUrl,
    this.size = 90,
  });

  @override
  Widget build(BuildContext context) {
    const fallback = 'assets/icons/stethoscope.png';

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.asset(
          fallback,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 2).toInt(),
        filterQuality: FilterQuality.low,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            fallback,
            width: size,
            height: size,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}
