import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';

class RequestStoreScreen extends StatefulWidget {
  const RequestStoreScreen({super.key});

  @override
  State<RequestStoreScreen> createState() => _RequestStoreScreenState();
}

class _RequestStoreScreenState extends State<RequestStoreScreen> {
  static const Color _brandBlue = Color(0xFF0071CE);

  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _commentsController = TextEditingController();

  bool _isSubmitting = false;

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      // Simulate network request
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final appTheme = dialogContext.appTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: appTheme.cardSurface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated-like checkmark circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFC8E6C9),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF2E7D32),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Request Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appTheme.navyText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thank you for requesting ${_storeNameController.text}. Our curation team will reach out to this merchant to bring their flyers to your area!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: appTheme.subtitle,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back to settings/browse
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back to App',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _locationController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;
    final appBarTheme = Theme.of(context).appBarTheme;
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarTheme.backgroundColor,
        foregroundColor: appBarTheme.foregroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Request a Store',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: Theme.of(context).dividerColor),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? _brandBlue.withValues(alpha: 0.12)
                      : const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? _brandBlue.withValues(alpha: 0.35)
                        : const Color(0xFFC2E0FF),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront, color: _brandBlue, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Missing your favorite store?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark
                                  ? appTheme.navyText
                                  : const Color(0xFF003893),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Let us know which local retailer flyers you\'d like to see, and we\'ll do our best to onboard them!',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? appTheme.subtitle
                                  : const Color(0xFF004CB3),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Store Name
              Text(
                'Store Name *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: appTheme.navyText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _storeNameController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the store name';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Sobeys, No Frills, FreshCo',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Store Location / City *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: appTheme.navyText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _locationController,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter store location or city';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Toronto, ON or Vancouver, BC',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Any additional comments? (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: appTheme.navyText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentsController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText:
                      'Tell us why you love this store or which items you shop for...',
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 36),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _brandBlue.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Submit Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
