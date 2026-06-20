import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StoreRequestService {
  StoreRequestService._();

  static final StoreRequestService instance = StoreRequestService._();

  Future<void> submit({
    required String storeName,
    required String location,
    String? comments,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    await FirebaseFirestore.instance.collection('store_requests').add({
      'storeName': storeName.trim(),
      'location': location.trim(),
      'comments': comments?.trim() ?? '',
      'userId': user?.uid,
      'userEmail': user?.email,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
