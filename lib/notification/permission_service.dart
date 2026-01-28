import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestNotificationPermission() async {
    // Untuk Android 13+ dan iOS
    var status = await Permission.notification.status;
    
    if (status.isDenied) {
      status = await Permission.notification.request();
    }
    
    return status.isGranted;
  }
  
  static Future<bool> requestLocationPermission() async {
    var status = await Permission.location.status;
    
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    
    return status.isGranted;
  }
}