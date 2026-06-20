import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/support_message.dart';

class SupportChatService {
  SupportChatService._();

  static final SupportChatService instance = SupportChatService._();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _conversationRef(String userId) =>
      _db.collection('support_conversations').doc(userId);

  CollectionReference<Map<String, dynamic>> _messagesRef(String userId) =>
      _conversationRef(userId).collection('messages');

  Future<void> _refreshAuth(User user) async {
    await user.getIdToken(true);
  }

  Stream<List<SupportMessage>> watchMessages(String userId) {
    return _messagesRef(userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map(SupportMessage.fromDoc).toList(),
        );
  }

  Future<void> ensureConversation(User user) async {
    await _refreshAuth(user);

    final ref = _conversationRef(user.uid);
    final snap = await ref.get();
    if (snap.exists) {
      await ref.set({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await ref.set({
      'userId': user.uid,
      'userEmail': user.email,
      'userName': user.displayName,
      'status': 'open',
      'subject': 'General support',
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSenderRole': 'user',
      'unreadByAdmin': 0,
      'unreadByUser': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendUserMessage({
    required User user,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    await _refreshAuth(user);
    await ensureConversation(user);

    final messageRef = _messagesRef(user.uid).doc();
    final conversationRef = _conversationRef(user.uid);

    try {
      await messageRef.set({
        'text': trimmed,
        'senderId': user.uid,
        'senderRole': 'user',
        'senderName': user.displayName ?? user.email ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stack) {
      debugPrint('[SupportChat] message write failed: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }

    try {
      await conversationRef.set({
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName,
        'lastMessage': trimmed,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderRole': 'user',
        'status': 'open',
        'unreadByAdmin': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, stack) {
      debugPrint('[SupportChat] conversation update failed: $e');
      debugPrintStack(stackTrace: stack);
      rethrow;
    }
  }

  Future<void> markReadByUser(String userId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await _refreshAuth(user);

    final ref = _conversationRef(userId);
    final snap = await ref.get();
    if (!snap.exists) return;
    final unread = (snap.data()?['unreadByUser'] as num?)?.toInt() ?? 0;
    if (unread == 0) return;
    await ref.set({'unreadByUser': 0}, SetOptions(merge: true));
  }
}
