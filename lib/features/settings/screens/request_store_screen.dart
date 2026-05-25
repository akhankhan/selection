import 'package:flutter/material.dart';

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
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white,
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
                const Text(
                  'Request Submitted!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thank you for requesting ${_storeNameController.text}. Our curation team will reach out to this merchant to bring their flyers to your area!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Request a Store',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFEEEEEE)),
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
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC2E0FF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.storefront, color: _brandBlue, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Missing your favorite store?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF003893),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Let us know which local retailer flyers you\'d like to see, and we\'ll do our best to onboard them!',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF004CB3),
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
              const Text(
                'Store Name *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
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
                decoration: InputDecoration(
                  hintText: 'e.g. Sobeys, No Frills, FreshCo',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _brandBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location (City & Province/Postal)
              const Text(
                'Store Location / City *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
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
                decoration: InputDecoration(
                  hintText: 'e.g. Toronto, ON or Vancouver, BC',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _brandBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Why do you want this store? (Comments)
              const Text(
                'Any additional comments? (Optional)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentsController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Tell us why you love this store or which items you shop for...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _brandBlue, width: 1.5),
                  ),
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
