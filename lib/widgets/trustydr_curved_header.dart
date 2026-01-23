import 'package:flutter/material.dart';

class TrustyDrCurvedHeader extends StatelessWidget {
  final String title;
  final bool showBack;

  const TrustyDrCurvedHeader({
    super.key,
    required this.title,
    this.showBack = true,
  });

 @override
Widget build(BuildContext context) {
  return ClipRRect(
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
    child: Container(
      height: 180,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5CC6BA), Color(0xFF4A90E2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row (back + branding)
              Row(
                children: [
                  if (showBack)
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    )
                  else
                    const SizedBox(width: 48),

                  const Spacer(),

                  Row(
                    children: [
                      Image.asset(
                        'assets/icon.png', // <-- your logo path
                        height: 26,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'TrustyDr',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  const SizedBox(width: 48),
                ],
              ),

              const SizedBox(height: 18),

              // Page title
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}
