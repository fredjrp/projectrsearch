import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

class DriverNavigationScreen extends StatefulWidget {
  const DriverNavigationScreen({Key? key}) : super(key: key);

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  MapBoxNavigationViewController? _controller;
  bool _isNavigating = false;
  late MapBoxOptions _navigationOption;

  @override
  void initState() {
    super.initState();
    _navigationOption = MapBoxNavigation.instance.getDefaultOptions();
    _navigationOption.simulateRoute = true;
    _navigationOption.language = "en";
  }

  void _onRouteEvent(e) {
    if (e.eventType == MapBoxEvent.progress_change) {
      // var progressEvent = e.data as RouteProgressEvent;
    } else if (e.eventType == MapBoxEvent.route_built) {
      setState(() {
        _isNavigating = true;
      });
      _controller?.startNavigation();
    } else if (e.eventType == MapBoxEvent.on_arrival) {
      // Arrived at destination
      _controller?.finishNavigation();
      Navigator.pop(context); // Go back to dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapBoxNavigationView(
        options: _navigationOption,
        onRouteEvent: _onRouteEvent,
        onCreated: (MapBoxNavigationViewController controller) async {
          _controller = controller;
          controller.initialize();
          
          // Build mock route to student
          final origin = WayPoint(name: "Origin", latitude: -1.2921, longitude: 36.8219, isSilent: false);
          final dest = WayPoint(name: "Student", latitude: -1.3000, longitude: 36.8100, isSilent: false);
          await controller.buildRoute(wayPoints: [origin, dest]);
        },
      ),
    );
  }
}
