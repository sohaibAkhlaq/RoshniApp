import 'dart:io';

/// A generic, reusable service that answers "is there a usable internet
/// connection right now?" before any API call is attempted (per BR-4).
class ConnectivityService {
  /// Returns `true` if a simple DNS lookup succeeds.
  Future<bool> hasInternet() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
