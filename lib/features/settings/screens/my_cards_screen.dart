import 'package:flutter/material.dart';

class MyCardsScreen extends StatefulWidget {
  const MyCardsScreen({super.key});

  @override
  State<MyCardsScreen> createState() => _MyCardsScreenState();
}

class _MyCardsScreenState extends State<MyCardsScreen> {
  static const Color _brandBlue = Color(0xFF0071CE);

  // Initial list of loyalty cards
  final List<Map<String, dynamic>> _cards = [
    {
      'id': '1',
      'merchant': 'Scene+',
      'cardNumber': '9802 3421 9887 5612',
      'color1': const Color(0xFF003893),
      'color2': const Color(0xFF0056D6),
      'logoLetter': 'S',
      'textColor': Colors.white,
    },
    {
      'id': '2',
      'merchant': 'PC Optimum',
      'cardNumber': '3084 0938 1209 8452',
      'color1': const Color(0xFFD22630),
      'color2': const Color(0xFFFF5252),
      'logoLetter': 'P',
      'textColor': Colors.white,
    },
  ];

  final List<Map<String, dynamic>> _availableMerchants = [
    {
      'name': 'Walmart Rewards',
      'color1': const Color(0xFF0071CE),
      'color2': const Color(0xFF00A2E8),
      'logoLetter': 'W',
    },
    {
      'name': 'Scene+',
      'color1': const Color(0xFF003893),
      'color2': const Color(0xFF0056D6),
      'logoLetter': 'S',
    },
    {
      'name': 'PC Optimum',
      'color1': const Color(0xFFD22630),
      'color2': const Color(0xFFFF5252),
      'logoLetter': 'P',
    },
    {
      'name': 'Costco Membership',
      'color1': const Color(0xFF1E293B),
      'color2': const Color(0xFF475569),
      'logoLetter': 'C',
    },
    {
      'name': 'Air Miles',
      'color1': const Color(0xFF0A6FBA),
      'color2': const Color(0xFF33A1FD),
      'logoLetter': 'A',
    },
    {
      'name': 'Triangle Rewards',
      'color1': const Color(0xFFE31B23),
      'color2': const Color(0xFFFF5E5E),
      'logoLetter': 'T',
    },
  ];

  void _showCardBarcode(Map<String, dynamic> card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  card['merchant'],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  card['cardNumber'],
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Simulated Barcode
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[200]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 90,
                        width: double.infinity,
                        child: CustomPaint(painter: BarcodePainter()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        card['cardNumber'].replaceAll(' ', ''),
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey[700],
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Scan this barcode at the store checkout counter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Done',
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

  void _addNewCard() {
    Map<String, dynamic>? selectedMerchant = _availableMerchants[0];
    final numberController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Add Loyalty Card',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Merchant Dropdown selector
                    const Text(
                      'Select Store / Program',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButton<Map<String, dynamic>>(
                        value: selectedMerchant,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: _availableMerchants.map((merchant) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: merchant,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: merchant['color1'],
                                  child: Text(
                                    merchant['logoLetter'],
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(merchant['name']),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedMerchant = val;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Card Number Field
                    const Text(
                      'Card Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: numberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter loyalty card number',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (numberController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a card number'),
                              ),
                            );
                            return;
                          }

                          // Format card number with spaces for aesthetics
                          String raw = numberController.text.replaceAll(
                            ' ',
                            '',
                          );
                          String formatted = '';
                          for (int i = 0; i < raw.length; i++) {
                            if (i > 0 && i % 4 == 0) formatted += ' ';
                            formatted += raw[i];
                          }

                          setState(() {
                            _cards.add({
                              'id': DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              'merchant': selectedMerchant!['name'],
                              'cardNumber': formatted,
                              'color1': selectedMerchant!['color1'],
                              'color2': selectedMerchant!['color2'],
                              'logoLetter': selectedMerchant!['logoLetter'],
                              'textColor': Colors.white,
                            });
                          });

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${selectedMerchant!['name']} card added!',
                              ),
                              backgroundColor: _brandBlue,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _brandBlue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Save Card',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteCard(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Remove Card',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove your ${_cards[index]['merchant']} loyalty card?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _cards.removeAt(index);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Card removed successfully')),
                );
              },
              child: const Text(
                'Remove',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Cards',
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
      body: _cards.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.credit_card_off_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Loyalty Cards Added',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your favorite grocery & shopping cards\nso you don\'t miss out on savings.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _addNewCard,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add Loyalty Card',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              itemBuilder: (context, index) {
                final card = _cards[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 3,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () => _showCardBarcode(card),
                      onLongPress: () => _deleteCard(index),
                      child: Container(
                        height: 170,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [card['color1'], card['color2']],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      child: Text(
                                        card['logoLetter'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      card['merchant'],
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                Icon(
                                  Icons.qr_code_scanner,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 24,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'CARD NUMBER',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  card['cardNumber'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: _cards.isNotEmpty
          ? FloatingActionButton(
              onPressed: _addNewCard,
              backgroundColor: _brandBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }
}

// Custom Painter to draw realistic barcode stripes
class BarcodePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Pattern of barcode line weights: width factors
    final List<double> stripeWeights = [
      2,
      1,
      3,
      1,
      4,
      2,
      1,
      3,
      1,
      2,
      2,
      4,
      1,
      2,
      1,
      3,
      1,
      4,
      2,
      1,
      3,
      1,
      2,
      2,
      4,
      1,
      2,
      1,
      3,
      1,
      4,
      2,
      1,
      3,
      1,
      2,
    ];

    double currentX = 0;
    double gap = 2.5;

    for (int i = 0; i < stripeWeights.length; i++) {
      double stripeWidth = stripeWeights[i] * 1.5;

      // Paint black line on even indices, leave gap on odd indices
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(currentX, 0, stripeWidth, size.height),
          paint,
        );
      }
      currentX += stripeWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
