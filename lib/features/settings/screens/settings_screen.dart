import 'package:flutter/material.dart';
import 'signin_screen.dart';
import 'privacy_choices_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _brandBlue = Color(0xFF0071CE);

  bool _acceptNotifications = true;
  String _selectedTheme = 'System';
  String _autoDeleteOption = 'Never (Default)';

  void _showThemePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Select Theme',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['System', 'Light', 'Dark'].map((theme) {
              return ListTile(
                title: Text(theme),
                leading: Radio<String>(
                  value: theme,
                  groupValue: _selectedTheme,
                  activeColor: _brandBlue,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTheme = value);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  setState(() => _selectedTheme = theme);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showAutoDeletePicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Auto Delete Expired Items',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ['Never (Default)', 'After 7 days', 'After 30 days'].map((
              option,
            ) {
              return ListTile(
                title: Text(option),
                leading: Radio<String>(
                  value: option,
                  groupValue: _autoDeleteOption,
                  activeColor: _brandBlue,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _autoDeleteOption = value);
                      Navigator.pop(context);
                    }
                  },
                ),
                onTap: () {
                  setState(() => _autoDeleteOption = option);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _confirmClear(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title Cleared Successfully!'),
                    backgroundColor: _brandBlue,
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMockPage(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _brandBlue,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This is a placeholder page for the dynamic $title document.\n\n'
                    'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                    'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. '
                    'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. '
                    'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF4F5F7,
      ), // Match the subtle grey background in screenshots
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
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
      body: ListView(
        children: [
          // My Account Section
          _buildCategoryHeader('My Account'),
          _buildTile(
            title: 'Sign In or Create Account',
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SignInScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.0, 1.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        );
                      },
                ),
              );
            },
          ),

          // Preferences Section
          _buildCategoryHeader('Preferences'),
          _buildCheckboxTile(
            title: 'Accept Push Notifications',
            subtitle:
                'Allow Flipp to notify you of the latest deals in your area',
            value: _acceptNotifications,
            onChanged: (val) {
              setState(() => _acceptNotifications = val);
            },
          ),
          _buildDivider(),
          _buildTile(
            title: 'Theme',
            subtitle: _selectedTheme,
            onTap: _showThemePicker,
          ),
          _buildDivider(),
          _buildTile(
            title: 'Clear Search History',
            subtitle: 'Remove all saved search terms',
            onTap: () => _confirmClear(
              'Search History',
              'Are you sure you want to clear your search history?',
            ),
          ),

          // Legal Section
          _buildCategoryHeader('Legal'),
          _buildTile(
            title: 'Terms Of Service',
            onTap: () => _showMockPage('Terms Of Service'),
          ),
          _buildDivider(),
          _buildTile(
            title: 'Enhanced Notice',
            onTap: () => _showMockPage('Enhanced Notice'),
          ),
          _buildDivider(),
          _buildTile(
            title: 'Privacy Policy',
            onTap: () => _showMockPage('Privacy Policy'),
          ),

          // Shopping List Section
          _buildCategoryHeader('Shopping List'),
          _buildTile(
            title: 'Clear Shopping List History',
            subtitle: 'Remove all prior items from recommendations',
            onTap: () => _confirmClear(
              'Shopping List History',
              'Are you sure you want to clear your shopping list history? This action is irreversible.',
            ),
          ),
          _buildDivider(),
          _buildTile(
            title: 'Auto Delete Expired Shopping List Items',
            subtitle: _autoDeleteOption,
            onTap: _showAutoDeletePicker,
          ),

          // Version Section
          _buildCategoryHeader('Version'),
          _buildTile(title: '97.1.0', enabled: false),

          // Contact Us Section
          _buildCategoryHeader('Contact Us'),
          _buildTile(
            title: 'Privacy Choices',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PrivacyChoicesScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildTile(
            title: 'Share your feedback',
            onTap: () => _showMockPage('Share your feedback'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: _brandBlue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFEEEEEE),
      indent: 16,
    );
  }

  Widget _buildTile({
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: enabled ? Colors.black87 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Blue check box to match user's screenshot
              Checkbox(
                value: value,
                onChanged: (val) {
                  if (val != null) onChanged(val);
                },
                activeColor: _brandBlue,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
