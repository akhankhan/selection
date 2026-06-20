import 'package:cloud_firestore/cloud_firestore.dart';

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.text,
    required this.senderId,
    required this.senderRole,
    this.senderName,
    this.createdAt,
  });

  final String id;
  final String text;
  final String senderId;
  final String senderRole;
  final String? senderName;
  final DateTime? createdAt;

  bool get isFromUser => senderRole == 'user';
  bool get isFromAdmin => senderRole == 'admin';

  factory SupportMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    final createdAt = data['createdAt'];
    return SupportMessage(
      id: doc.id,
      text: (data['text'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      senderRole: (data['senderRole'] as String?) ?? 'user',
      senderName: data['senderName'] as String?,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
