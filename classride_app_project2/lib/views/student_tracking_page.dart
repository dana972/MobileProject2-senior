import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class StudentTrackingPage extends StatefulWidget {
  final String tripId;
  const StudentTrackingPage({super.key, required this.tripId});

  @override
  State<StudentTrackingPage> createState() => _StudentTrackingPageState();
}

class _StudentTrackingPageState extends State<StudentTrackingPage> {
  late IO.Socket socket;
  LatLng? busLocation;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    _connectToSocket();
  }

  void _connectToSocket() {
    socket = IO.io('http://10.0.2.2:5000', <String, dynamic>{
      'transports': <String>['websocket'], // ✅ cast to List<String> to avoid error
      'autoConnect': false,
    });

    socket.connect();

    socket.onConnect((_) {
      print('🧑‍🎓 Student connected to Socket.IO');
      socket.emit('join_trip', widget.tripId);
    });

    socket.on('bus_location', (data) {
      print('📍 Received bus location: ${data['lat']}, ${data['lng']}');
      setState(() {
        busLocation = LatLng(data['lat'], data['lng']);
      });
      if (_mapController != null && busLocation != null) {
        _mapController.animateCamera(CameraUpdate.newLatLng(busLocation!));
      }
    });

    socket.onDisconnect((_) {
      print('❌ Student disconnected from Socket.IO');
    });
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Bus Tracking')),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(33.8938, 35.5018), // 📍 Initial position: Beirut
          zoom: 14,
        ),
        markers: busLocation != null
            ? {
          Marker(
            markerId: const MarkerId('bus'),
            position: busLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          )
        }
            : {},
        onMapCreated: (controller) => _mapController = controller,
      ),
    );
  }
}
