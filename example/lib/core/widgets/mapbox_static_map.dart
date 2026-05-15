import 'package:flutter/material.dart';
import 'dart:io';

class MapboxStaticMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double zoom;
  final int width;
  final int height;
  final String accessToken;
  final List<MapMarker> markers;
  final String style;

  const MapboxStaticMap({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.zoom = 13.0,
    this.width = 600,
    this.height = 400,
    required this.accessToken,
    this.markers = const [],
    this.style = 'streets-v11',
  }) : super(key: key);

  String get _url {
    String markersString = "";
    if (markers.isNotEmpty) {
      markersString = markers.map((m) {
        // format: pin-s+color(lon,lat)
        final color = m.color.value.toRadixString(16).substring(2); // remove alpha
        return "pin-s+${color}(${m.longitude},${m.latitude})";
      }).join(",");
      markersString += "/";
    }

    return "https://api.mapbox.com/styles/v1/mapbox/$style/static/${markersString}$longitude,$latitude,$zoom,0,0/${width}x${height}@2x?access_token=$accessToken";
  }

  @override
  Widget build(BuildContext context) {
    return Image.network(
      _url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[200],
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                SizedBox(height: 8),
                Text("Failed to load map. Check token."),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MapMarker {
  final double latitude;
  final double longitude;
  final Color color;

  MapMarker({
    required this.latitude,
    required this.longitude,
    this.color = Colors.red,
  });
}
