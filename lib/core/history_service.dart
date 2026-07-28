import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class HistoryService {
  static Future<void> saveScan({
    required String type,
    required String result,
  }) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous_user';
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('scanHistory')
          .add({
        'type': type,
        'result': result,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to save scan history: $e');
    }
  }
}
