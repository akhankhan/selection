import 'package:flutter/material.dart';

class BedThumbnail extends StatelessWidget {
  const BedThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 64,
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF8B7458), Color(0xFF4A3829)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B5239), Color(0xFF2E2317)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 3,
              top: 18,
              child: Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D9BA),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 18,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B5239), Color(0xFF2E2317)],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 3,
              top: 18,
              child: Container(
                width: 12,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8D9BA),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 6,
              right: 18,
              child: Container(
                height: 22,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFE8DAC2), Color(0xFFB8A78A)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 26,
              right: 18,
              child: Container(height: 6, color: const Color(0xFFEEE3D0)),
            ),
            Positioned(
              left: 18,
              top: 32,
              right: 18,
              child: Container(height: 24, color: const Color(0xFF382B1E)),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                color: const Color(0xFFD32F2F),
                child: const Text(
                  'SALE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PackageThumbnail extends StatelessWidget {
  const PackageThumbnail({
    super.key,
    required this.boxColor,
    required this.plateColor,
  });

  final Color boxColor;
  final Color plateColor;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 64,
        height: 56,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      boxColor,
                      Color.lerp(boxColor, Colors.black, 0.25)!,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 3,
              left: 4,
              child: Container(
                width: 14,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(1),
                ),
                child: const Center(
                  child: Text(
                    'PC',
                    style: TextStyle(
                      fontSize: 5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -6,
              bottom: -6,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D2118),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: plateColor,
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 6,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE07A4A),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 6,
                      child: Container(
                        width: 7,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE89A6E),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      bottom: 6,
                      child: Container(
                        width: 9,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD66838),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 16,
              child: Container(
                width: 22,
                height: 3,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 10,
              child: Container(
                width: 16,
                height: 3,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                width: 12,
                height: 2,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GenericThumbnail extends StatelessWidget {
  const GenericThumbnail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFE3E8EE),
        borderRadius: BorderRadius.circular(2),
      ),
      child: const Icon(
        Icons.shopping_bag_outlined,
        color: Colors.black45,
        size: 28,
      ),
    );
  }
}
