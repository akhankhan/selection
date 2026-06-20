import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_extension.dart';

class PrivacyChoicesScreen extends StatefulWidget {
  const PrivacyChoicesScreen({super.key});

  @override
  State<PrivacyChoicesScreen> createState() => _PrivacyChoicesScreenState();
}

class _PrivacyChoicesScreenState extends State<PrivacyChoicesScreen> {
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
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        final appTheme = dialogContext.appTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: dialogContext.brandBlue.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dialogContext.brandBlue.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.security_outlined,
                    color: dialogContext.brandBlue,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Privacy Request Logged',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: appTheme.navyText,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your request "$_selectedRequest" has been successfully received. We will verify your identity via email within 30 days to complete this request.',
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
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dialogContext.brandBlue,
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
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: appTheme.headerSurface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Choices',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: appTheme.border),
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
                    Text(
                      'You have specific rights with respect to your data in accordance with applicable law. '
                      'Please fill out the fields below and submit if you would like to exercise one of those rights. '
                      'For more information please see our privacy policy.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'All fields are required.',
                      style: TextStyle(
                        fontSize: 13,
                        color: appTheme.subtitle,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      context,
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
                    _buildTextField(
                      context,
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
                    _buildTextField(
                      context,
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
                    Text(
                      'I am a resident of:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: appTheme.border,
                          width: 1.2,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedProvince,
                          hint: Text(
                            'Select Province',
                            style: TextStyle(
                              color: appTheme.subtitle,
                              fontSize: 15,
                            ),
                          ),
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: appTheme.subtitle,
                          ),
                          dropdownColor: colorScheme.surface,
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
                                style: TextStyle(
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
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
                    Text(
                      'Select your data request below',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: appTheme.navyText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildRadioChoice(
                      context,
                      title: 'Do not sell my data',
                      description:
                          'We will not sell the personal information that you have provided us with, '
                          'or that we have collected about you, to third parties.',
                    ),
                    const SizedBox(height: 16),
                    _buildRadioChoice(
                      context,
                      title: 'Receive a copy of my data',
                      description:
                          'We will send you a copy of the personal information that you have provided us with, '
                          'or that we have collected about you, based on the identifiers you have given us.',
                    ),
                    const SizedBox(height: 16),
                    _buildRadioChoice(
                      context,
                      title: 'Permanently delete my data',
                      description:
                          'We will delete, aggregate, or de-identify the personal information that you have provided us with, '
                          'or that we have collected about you, based on the identifiers you have given us.',
                    ),
                    const SizedBox(height: 28),
                    _buildDisclaimerText(
                      context,
                      'If you have any questions or concerns with respect to this form or your rights, '
                      'please review our policy privacy.',
                      isHighlight: true,
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerText(
                      context,
                      'We are required to verify your identity before responding to any request for information '
                      'or request to delete, and will do so by matching the personal information you provide in '
                      'this form with the information contained in our systems.',
                    ),
                    const SizedBox(height: 16),
                    _buildDisclaimerText(
                      context,
                      'If you would like to know the categories of information Flipp collects with respect to all users, '
                      'please refer to the privacy policy.',
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(color: appTheme.border, width: 1),
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.brandBlue,
                  disabledBackgroundColor:
                      context.brandBlue.withValues(alpha: 0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: colorScheme.onPrimary,
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

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    required FormFieldValidator<String> validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: appTheme.subtitle, fontSize: 15),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: appTheme.border, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: appTheme.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: context.brandBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildRadioChoice(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    final appTheme = context.appTheme;
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
                  color: active ? context.brandBlue : appTheme.subtitle,
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: appTheme.navyText,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: appTheme.subtitle,
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

  Widget _buildDisclaimerText(
    BuildContext context,
    String text, {
    bool isHighlight = false,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: context.appTheme.subtitle,
        height: 1.45,
        fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
