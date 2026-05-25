import 'package:flutter/material.dart';

class PrivacyChoicesScreen extends StatefulWidget {
  const PrivacyChoicesScreen({super.key});

  @override
  State<PrivacyChoicesScreen> createState() => _PrivacyChoicesScreenState();
}

class _PrivacyChoicesScreenState extends State<PrivacyChoicesScreen> {
  static const Color _brandBlue = Color(0xFF0071CE);
  static const Color _navyDark = Color(0xFF1E293B);

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  String? _selectedProvince;
  String _selectedRequest =
      'Do not sell my data'; // Default selected radio choice
  bool _isSubmitting = false;

  final List<String> _provinces = [
    'Ontario',
    'Quebec',
    'Nova Scotia',
    'New Brunswick',
    'Manitoba',
    'British Columbia',
    'Prince Edward Island',
    'Saskatchewan',
    'Alberta',
    'Newfoundland and Labrador',
  ];

  void _submitRequest() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProvince == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your resident province')),
        );
        return;
      }

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
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBAE6FD),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.security_outlined,
                    color: _brandBlue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Privacy Request Logged',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _navyDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your request "$_selectedRequest" has been successfully received. We will verify your identity via email within 30 days to complete this request.',
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
                      Navigator.pop(context); // Go back to settings
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Back to Settings',
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
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
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
          'Privacy Choices',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle intro text
                    Text(
                      'You have specific rights with respect to your data in accordance with applicable law. '
                      'Please fill out the fields below and submit if you would like to exercise one of those rights. '
                      'For more information please see our privacy policy.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[850],
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Required text
                    Text(
                      'All fields are required.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // First Name Field
                    _buildTextField(
                      controller: _firstNameController,
                      hintText: 'First name',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Last Name Field
                    _buildTextField(
                      controller: _lastNameController,
                      hintText: 'Last name',
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(val.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Resident Dropdown Header
                    const Text(
                      'I am a resident of:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navyDark,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Resident Dropdown Field
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProvince,
                          hint: Text(
                            'Select Province',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                          ),
                          dropdownColor: Colors.white,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (val) => val == null
                              ? 'Province selection is required'
                              : null,
                          items: _provinces.map((prov) {
                            return DropdownMenuItem<String>(
                              value: prov,
                              child: Text(
                                prov,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedProvince = val;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Data Request Section Header
                    const Text(
                      'Select your data request below',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _navyDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Radio Choices
                    _buildRadioChoice(
                      title: 'Do not sell my data',
                      description:
                          'We will not sell the personal information that you have provided us with, '
                          'or that we have collected about you, to third parties.',
                    ),
                    const SizedBox(height: 16),
                    _buildRadioChoice(
                      title: 'Receive a copy of my data',
                      description:
                          'We will send you a copy of the personal information that you have provided us with, '
                          'or that we have collected about you, based on the identifiers you have given us.',
                    ),
                    const SizedBox(height: 16),
                    _buildRadioChoice(
                      title: 'Permanently delete my data',
                      description:
                          'We will delete, aggregate, or de-identify the personal information that you have provided us with, '
                          'or that we have collected about you, based on the identifiers you have given us.',
                    ),
                    const SizedBox(height: 28),

                    // Fine Prints/Disclaimers
                    _buildDisclaimerText(
                      'If you have any questions or concerns with respect to this form or your rights, '
                      'please review our policy privacy.',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerText(
                      'We are required to verify your identity before responding to any request for information '
                      'or request to delete, and will do so by matching the personal information you provide in '
                      'this form with the information contained in our systems.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerText(
                      'If you would like to know the categories of information Flipp collects with respect to all users, '
                      'please refer to the privacy policy.',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),

          // Submit Button bar at bottom
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brandBlue,
                  disabledBackgroundColor: _brandBlue.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Submit',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Colors.red, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildRadioChoice({
    required String title,
    required String description,
  }) {
    final bool active = _selectedRequest == title;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRequest = title;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: active ? _brandBlue : const Color(0xFF8C96A3),
                  width: active ? 6.5 : 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _navyDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerText(String text, {bool isHighlight = false}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[600],
        height: 1.45,
        fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
