import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PermissionService {
  static const String _prefsKey = 'roshni_permissions_granted';

  /// Returns true ONLY if BOTH the saved flag exists AND actual OS permissions are still granted.
  /// If the flag says granted but OS revoked (e.g., "Only this time" auto-revoke,
  /// or user revoked from Settings), the flag is reset and false is returned.
  Future<bool> areAllGranted() async {
    final prefs = await SharedPreferences.getInstance();
    final flag = prefs.getBool(_prefsKey) ?? false;
    if (!flag) return false;

    final actuallyGranted = await _checkActualPermissions();
    if (!actuallyGranted) {
      await _reset();
    }
    return actuallyGranted;
  }

  Future<bool> _checkActualPermissions() async {
    for (final perm in [Permission.camera, Permission.microphone]) {
      final status = await perm.status;
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        return false;
      }
    }
    return true;
  }

  Future<void> markGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  Future<void> _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  Future<Map<Permission, PermissionStatus>> requestAll() async {
    final results = <Permission, PermissionStatus>{};
    for (final perm in [Permission.camera, Permission.microphone]) {
      final status = await _requestSingle(perm);
      results[perm] = status;
    }

    final allActuallyGranted = results.values
        .every((s) => s == PermissionStatus.granted || s == PermissionStatus.limited);
    if (allActuallyGranted) {
      await markGranted();
    }

    return results;
  }

  Future<PermissionStatus> _requestSingle(Permission permission) async {
    final status = await permission.status;
    if (status == PermissionStatus.granted || status == PermissionStatus.permanentlyDenied) {
      return status;
    }
    final result = await permission.request();
    return result;
  }

  Future<bool> isPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.permanentlyDenied;
  }

  Future<bool> hasPermanentlyDenied() async {
    final cameraDenied = await isPermanentlyDenied(Permission.camera);
    final micDenied = await isPermanentlyDenied(Permission.microphone);
    return cameraDenied || micDenied;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<int> getDeniedCount() async {
    int count = 0;
    for (final perm in [Permission.camera, Permission.microphone]) {
      final status = await perm.status;
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        count++;
      }
    }
    return count;
  }
}
