import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order.dart';
import 'web_launcher_stub.dart'
    if (dart.library.html) 'web_launcher_web.dart';

class MapService {
  /// Opens Google Maps with driving directions to the order's delivery location
  /// starting from the user's current GPS location.
  static Future<void> openDirections(BuildContext context, Order order) async {
    final address = order.deliveryAddress.trim();
    final bool hasValidAddress =
        address.isNotEmpty && address != '-' && address.toLowerCase() != 'delivery address';

    final String destination;
    if (order.latitude != null && order.longitude != null) {
      destination = '${order.latitude},${order.longitude}';
    } else if (hasValidAddress) {
      destination = Uri.encodeComponent(address);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid delivery location found for this order.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Google Maps universal turn-by-turn directions URL
    // When origin is omitted, Google Maps automatically uses the device's current location
    final String urlString =
        'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving';

    // 1. If running on Web, use native browser window.open directly
    if (kIsWeb) {
      final success = launchWebUrl(urlString);
      if (success) return;
    }

    // 2. On Mobile / Desktop, use url_launcher
    try {
      final Uri googleMapsUrl = Uri.parse(urlString);
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await launchUrl(googleMapsUrl);
      }
    } catch (e) {
      if (context.mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('MissingPluginException')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please restart the app (stop and run "flutter run") to register newly added plugins.',
              ),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open Google Maps: $errorMsg'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }
}
