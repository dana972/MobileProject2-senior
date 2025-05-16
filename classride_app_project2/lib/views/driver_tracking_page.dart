import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DriverTrackingPage extends StatefulWidget {
  final String tripId;
  const DriverTrackingPage({super.key, required this.tripId});

  @override
  State<DriverTrackingPage> createState() => _DriverTrackingPageState();
}

class _DriverTrackingPageState extends State<DriverTrackingPage> {
  late IO.Socket socket;
  StreamSubscription<Position>? _positionStream;
  String _status = '🔄 Connecting...';

  @override
  void initState() {
    super.initState();
    _initializeSocket();  // Initialize the socket connection
  }

  // Initialize socket connection to the server
  void _initializeSocket() {
    socket = IO.io('http://192.168.0.103:5000', {
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket.connect();
    socket.onConnect((_) {
      print('✅ Driver connected');
    });
  }

  // Request location permission
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      _startLocationUpdates();
    } else {
      _showPermissionError();
    }
  }

  // Start receiving location updates from the driver's phone
  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10))
        .listen((Position position) {
      _sendLocation(position);
    });
  }

  // Send location to the backend via WebSocket
  void _sendLocation(Position position) {
    if (socket.connected) {
      socket.emit('driver_location', {
        'tripId': widget.tripId, // Use actual trip ID
        'lat': position.latitude,
        'lng': position.longitude,
      });
    }
  }

  // Handle button press to start sharing location
  void _startSharingLocation() {
    _requestLocationPermission();  // Request permission and start sharing location
    socket.onConnect((_) {
      print('✅ Driver connected');
      socket.emit('join_trip', widget.tripId); // Safe to emit only after connection
    });
    setState(() {
      _status = '📍 Sharing location...';
    });
  }

  // Handle permission error
  void _showPermissionError() {
    setState(() {
      _status = '❌ Location permission denied';
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Tracking')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startSharingLocation,
              child: Text('Share Live Location'),
            ),
            SizedBox(height: 20),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
