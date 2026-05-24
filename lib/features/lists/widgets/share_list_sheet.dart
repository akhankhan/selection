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
              const SizedBox(height: 8),
              const Text(
                'Sign in to share your list',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Combine your list with a friend and\ncollaborate on a single shopping list.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
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
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
        height: 1,
      ),
    );
  }
}

class _HandsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 160,
            height: 110,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FB),
              borderRadius: BorderRadius.circular(80),
            ),
          ),
          Positioned(
            left: 60,
            top: 20,
            child: Transform.rotate(
              angle: -0.3,
              child: const Icon(
                Icons.back_hand_outlined,
                size: 56,
                color: Color(0xFFE6A98C),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: 20,
            child: Transform.rotate(
              angle: 2.8,
              child: const Icon(
                Icons.back_hand_outlined,
                size: 56,
                color: Color(0xFFE6A98C),
              ),
            ),
          ),
          Container(
            width: 36,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF0071CE), width: 1.5),
            ),
            child: const Icon(Icons.check, size: 18, color: Color(0xFF0071CE)),
          ),
        ],
      ),
    );
  }
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
