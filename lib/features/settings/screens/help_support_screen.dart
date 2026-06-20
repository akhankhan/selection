import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/legal_documents_service.dart';
import '../../../core/theme/app_theme_extension.dart';
import '../widgets/sign_in_required_gate.dart';
import 'live_chat_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I add flyers to my list?',
      'answer':
          'Tap on any item in a flyer and select the pin or clip option to add it to your Shopping List. You can access all clipped items in the "Lists" tab.',
    },
    {
      'question': 'How does location detection work?',
      'answer':
          'We use your device\'s GPS location to find the best local flyers. You can also manually enter any postal code or zip code using the "Change Location" option from the main menu.',
    },
    {
      'question': 'Can I share my shopping list?',
      'answer':
          'Yes! Tap the "Lists" tab in the bottom navigation bar, then click the user icon at the top right to share your list via messaging apps, email, or a unique link.',
    },
    {
      'question': 'What are digital loyalty cards?',
      'answer':
          'The "My Cards" feature allows you to digitize and save your physical loyalty cards. Simply add the store name and enter or scan the barcode so you can scan it directly from the app at checkout.',
    },
    {
      'question': 'Why are some flyers missing in my area?',
      'answer':
          'Flyers are published based on the agreements and schedules of local retailers. If a store is missing, you can request it through our "Request a Store" form.',
    },
  ];

  Future<void> _emailSupport() async {
    final docs = await LegalDocumentsService.instance.load();
    final uri = Uri(
      scheme: 'mailto',
      path: docs.supportEmail,
      queryParameters: {
        'subject': 'MENU2GO Support',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email us at ${docs.supportEmail}'),
        backgroundColor: context.brandBlue,
      ),
    );
  }

  Future<void> _openLiveChat() async {
    final signedIn = await ensureSignedIn(context);
    if (!signedIn || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const LiveChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;

    final filteredFaqs = _faqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.brandBlue,
                    context.brandBlue.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: context.brandBlue.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help you?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search our FAQs or get in touch with our customer service team.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for articles, questions...',
                hintStyle: TextStyle(color: appTheme.subtitle, fontSize: 15),
                prefixIcon: Icon(Icons.search, color: context.brandBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: appTheme.subtitle),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: appTheme.searchFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: context.brandBlue,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
            const SizedBox(height: 28),

            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: appTheme.navyText,
              ),
            ),
            const SizedBox(height: 12),

            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 48,
                        color: appTheme.subtitle,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No FAQs found matching "$_searchQuery"',
                        style: TextStyle(
                          color: appTheme.subtitle,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFaqs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  return Card(
                    color: colorScheme.surface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: appTheme.listSectionBorder,
                        width: 1,
                      ),
                    ),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        side: BorderSide.none,
                      ),
                      title: Text(
                        faq['question']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: appTheme.navyText,
                        ),
                      ),
                      iconColor: context.brandBlue,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.topLeft,
                      children: [
                        Text(
                          faq['answer']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: appTheme.subtitle,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: appTheme.sectionBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: appTheme.listSectionBorder),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent, size: 48, color: context.brandBlue),
                  const SizedBox(height: 12),
                  Text(
                    'Still need assistance?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: appTheme.navyText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our support agents are here to help you 24/7. Reach out via email or start a chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: appTheme.subtitle,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _emailSupport,
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Email Us'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.brandBlue,
                            side: BorderSide(color: context.brandBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _openLiveChat,
                          icon: const Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Live Chat',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.brandBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
