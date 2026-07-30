import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class HistoryService {
  static Future<void> saveScan({
    required String type,
    required String result,
  }) async {
    try {
      final userId = await AuthService().getEffectiveUserId();
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
