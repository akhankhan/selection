import 'package:flutter/material.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const Color _brandBlue = Color(0xFF0071CE);
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

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _faqs.where((faq) {
      final query = _searchQuery.toLowerCase();
      return faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();

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
          'Help & Support',
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section with help message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brandBlue, _brandBlue.withValues(alpha: 0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _brandBlue.withValues(alpha: 0.2),
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

            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for articles, questions...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
                prefixIcon: const Icon(Icons.search, color: _brandBlue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
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
                  borderSide: const BorderSide(color: _brandBlue, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
            const SizedBox(height: 28),

            // FAQ Title
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),

            // FAQs List
            if (filteredFaqs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No FAQs found matching "$_searchQuery"',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(
                        color: Color(0xFFE2E8F0),
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
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      iconColor: _brandBlue,
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedAlignment: Alignment.topLeft,
                      children: [
                        Text(
                          faq['answer']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),

            // Still need help section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 48, color: _brandBlue),
                  const SizedBox(height: 12),
                  const Text(
                    'Still need assistance?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our support agents are here to help you 24/7. Reach out via email or start a chat.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Support ticket created. We will email you shortly!',
                                ),
                                backgroundColor: _brandBlue,
                              ),
                            );
                          },
                          icon: const Icon(Icons.email_outlined, size: 18),
                          label: const Text('Email Us'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _brandBlue,
                            side: const BorderSide(color: _brandBlue),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Connecting to live chat agent...',
                                ),
                                backgroundColor: _brandBlue,
                              ),
                            );
                          },
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
                            backgroundColor: _brandBlue,
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
