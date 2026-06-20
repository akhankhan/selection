import 'package:flutter/material.dart';

class LoyaltyCard {
  const LoyaltyCard({
    required this.id,
    required this.merchant,
    required this.cardNumber,
    required this.color1Value,
    required this.color2Value,
    required this.logoLetter,
  });

  final String id;
  final String merchant;
  final String cardNumber;
  final int color1Value;
  final int color2Value;
  final String logoLetter;

  Color get color1 => Color(color1Value);
  Color get color2 => Color(color2Value);

  Map<String, dynamic> toJson() => {
        'id': id,
        'merchant': merchant,
        'cardNumber': cardNumber,
        'color1Value': color1Value,
        'color2Value': color2Value,
        'logoLetter': logoLetter,
      };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    return LoyaltyCard(
      id: (json['id'] as String?) ?? '',
      merchant: (json['merchant'] as String?) ?? '',
      cardNumber: (json['cardNumber'] as String?) ?? '',
      color1Value: (json['color1Value'] as int?) ?? 0xFF0071CE,
      color2Value: (json['color2Value'] as int?) ?? 0xFF00A2E8,
      logoLetter: (json['logoLetter'] as String?) ?? '?',
    );
  }

  Map<String, dynamic> toUiMap() => {
        'id': id,
        'merchant': merchant,
        'cardNumber': cardNumber,
        'color1': color1,
        'color2': color2,
        'logoLetter': logoLetter,
        'textColor': Colors.white,
      };
}
