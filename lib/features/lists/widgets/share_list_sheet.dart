import 'package:flutter/material.dart';

class ShareListSheet extends StatelessWidget {
  const ShareListSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const ShareListSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Sign in to share your list',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Combine your list with a friend and\ncollaborate on a single shopping list.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F6368),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 24),
              _HandsIllustration(),
              const SizedBox(height: 18),
              InkWell(
                onTap: () {},
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Learn more about how sharing works',
                      style: TextStyle(
                        color: Color(0xFF0071CE),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, size: 14, color: Color(0xFF0071CE)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'To combine lists, connect with',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              _SocialButton(
                label: 'Continue with Facebook',
                icon: _FacebookIcon(),
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _SocialButton(
                label: 'Continue with Google',
                icon: _GoogleIcon(),
                onTap: () {},
              ),
              const SizedBox(height: 10),
              _SocialButton(
                label: 'Continue with email',
                icon: const Icon(
                  Icons.mail_outline,
                  color: Colors.black87,
                  size: 22,
                ),
                onTap: () {},
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'No thanks',
                  style: TextStyle(
                    color: Color(0xFF0071CE),
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _TermsText(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            SizedBox(width: 24, height: 24, child: Center(child: icon)),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 40),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
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

class _FacebookIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335);
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853);
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    
    final double sw = size.width * 0.22; // Stroke width
    
    // Red Arc (top segment)
    canvas.drawArc(
      rect.deflate(sw / 2),
      -2.4, // angle start
      1.3, // sweep
      false,
      redPaint..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.square,
    );
    
    // Green Arc (bottom segment)
    canvas.drawArc(
      rect.deflate(sw / 2),
      0.6,
      1.3,
      false,
      greenPaint..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.square,
    );
    
    // Yellow Arc (left segment)
    canvas.drawArc(
      rect.deflate(sw / 2),
      1.9,
      1.2,
      false,
      yellowPaint..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.square,
    );
    
    // Blue Arc + Bar (right segment and center bar)
    canvas.drawArc(
      rect.deflate(sw / 2),
      -1.1,
      1.7,
      false,
      bluePaint..style = PaintingStyle.stroke..strokeWidth = sw..strokeCap = StrokeCap.square,
    );
    
    // Center horizontal bar for "G"
    final Paint blueFill = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(r, r - sw / 2, r * 0.9, sw),
      blueFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HandsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: CustomPaint(
        size: const Size(200, 140),
        painter: _HandsIllustrationPainter(),
      ),
    );
  }
}

class _HandsIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    
    // 1. Draw soft blue oval background
    final Paint bgPaint = Paint()
      ..color = const Color(0xFFF0F5FA)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(0, 0, w, h), bgPaint);
    
    // 2. Draw shopping list sheet (tilted white card in the center)
    final Paint cardPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final Paint cardShadow = Paint()
      ..color = const Color(0x10000000)
      ..style = PaintingStyle.fill;
    
    // Shadow rect
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.23, h * 0.16, w * 0.54, h * 0.70), const Radius.circular(8)),
      cardShadow,
    );
    // Real sheet rect
    final RRect sheetRRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.25, h * 0.14, w * 0.50, h * 0.68),
      const Radius.circular(8),
    );
    canvas.drawRRect(sheetRRect, cardPaint);
    
    // Draw thin blue border around the sheet
    final Paint borderPaint = Paint()
      ..color = const Color(0xFFD8E5F3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(sheetRRect, borderPaint);
    
    // 3. Draw lines and checkboxes on the sheet
    final Paint linePaint = Paint()
      ..color = const Color(0xFFE6EFF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    final Paint checkPaint = Paint()
      ..color = const Color(0xFF4FA0F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    final Paint checkedBg = Paint()
      ..color = const Color(0xFFE8F1FC)
      ..style = PaintingStyle.fill;

    // Checkbox 1 (Checked)
    final double cb1Top = h * 0.24;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, cb1Top, 15, 11), const Radius.circular(2)),
      checkedBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, cb1Top, 15, 11), const Radius.circular(2)),
      checkPaint,
    );
    // Draw check mark
    final Path checkPath = Path()
      ..moveTo(w * 0.32 + 3, cb1Top + 5)
      ..lineTo(w * 0.32 + 6, cb1Top + 8)
      ..lineTo(w * 0.32 + 11, cb1Top + 3);
    canvas.drawPath(checkPath, Paint()
      ..color = const Color(0xFF0071CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);

    // Lines for item 1
    canvas.drawLine(Offset(w * 0.44, cb1Top + 5), Offset(w * 0.68, cb1Top + 5), linePaint);
    
    // Checkbox 2 (Checked)
    final double cb2Top = h * 0.42;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, cb2Top, 15, 11), const Radius.circular(2)),
      checkedBg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, cb2Top, 15, 11), const Radius.circular(2)),
      checkPaint,
    );
    // Draw check mark
    final Path checkPath2 = Path()
      ..moveTo(w * 0.32 + 3, cb2Top + 5)
      ..lineTo(w * 0.32 + 6, cb2Top + 8)
      ..lineTo(w * 0.32 + 11, cb2Top + 3);
    canvas.drawPath(checkPath2, Paint()
      ..color = const Color(0xFF0071CE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);
    // Lines for item 2
    canvas.drawLine(Offset(w * 0.44, cb2Top + 5), Offset(w * 0.62, cb2Top + 5), linePaint);
    
    // Checkbox 3 (Unchecked)
    final double cb3Top = h * 0.60;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, cb3Top, 15, 11), const Radius.circular(2)),
      checkPaint,
    );
    // Lines for item 3
    canvas.drawLine(Offset(w * 0.44, cb3Top + 5), Offset(w * 0.58, cb3Top + 5), linePaint);
    
    // 4. Draw Left Hand (Sleeve, Watch, Hand pointing to Checkbox 1)
    final Paint skinPaint = Paint()..color = const Color(0xFFFCBEA1);
    final Paint watchPaint = Paint()..color = const Color(0xFF6B7A82);
    final Paint sleevePaint1 = Paint()..color = const Color(0xFFED836F); // Peach-red sleeve

    // Left Arm/Sleeve
    final Path sleevePath1 = Path()
      ..moveTo(0, h * 0.38)
      ..lineTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.22, h * 0.48)
      ..lineTo(w * 0.05, h * 0.56)
      ..close();
    canvas.drawPath(sleevePath1, sleevePaint1);
    
    // Watch
    canvas.drawOval(Rect.fromLTWH(w * 0.13, h * 0.38, 10, 8), watchPaint);
    
    // Left Hand pointing finger
    final Path handPath1 = Path()
      ..moveTo(w * 0.16, h * 0.38)
      ..quadraticBezierTo(w * 0.22, h * 0.40, w * 0.32, h * 0.46) // Pointing finger
      ..lineTo(w * 0.34, h * 0.48)
      ..quadraticBezierTo(w * 0.36, h * 0.50, w * 0.34, h * 0.52)
      ..lineTo(w * 0.24, h * 0.54)
      ..lineTo(w * 0.18, h * 0.46)
      ..close();
    canvas.drawPath(handPath1, skinPaint);
    
    // 5. Draw Right Hand (pointing to Checkbox 2)
    final Paint sleevePaint2 = Paint()..color = const Color(0xFFED836F); // Reddish sleeve
    
    // Right Arm/Sleeve
    final Path sleevePath2 = Path()
      ..moveTo(w, h * 0.48)
      ..lineTo(w * 0.84, h * 0.42)
      ..lineTo(w * 0.78, h * 0.60)
      ..lineTo(w * 0.94, h * 0.66)
      ..close();
    canvas.drawPath(sleevePath2, sleevePaint2);
    
    // Right Hand pointing finger
    final Path handPath2 = Path()
      ..moveTo(w * 0.84, h * 0.50)
      ..quadraticBezierTo(w * 0.78, h * 0.52, w * 0.68, h * 0.58) // Pointing finger
      ..lineTo(w * 0.66, h * 0.60)
      ..quadraticBezierTo(w * 0.64, h * 0.62, w * 0.66, h * 0.64)
      ..lineTo(w * 0.74, h * 0.66)
      ..lineTo(w * 0.80, h * 0.58)
      ..close();
    canvas.drawPath(handPath2, skinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TermsText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const link = TextStyle(
      fontSize: 12,
      color: Color(0xFF0071CE),
      fontWeight: FontWeight.w600,
    );
    const normal = TextStyle(
      fontSize: 12,
      color: Colors.black54,
      height: 1.4,
    );
    return Text.rich(
      const TextSpan(
        children: [
          TextSpan(text: 'By continuing, you agree to our ', style: normal),
          TextSpan(text: 'Terms of Use', style: link),
          TextSpan(text: ' and the collection and use of your data as described in our ', style: normal),
          TextSpan(text: 'Privacy\nPolicy', style: link),
          TextSpan(
            text: '. If you\'d like to opt out or learn more about your data options, please review our ',
            style: normal,
          ),
          TextSpan(text: 'Privacy Policy', style: link),
          TextSpan(text: '.', style: normal),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
