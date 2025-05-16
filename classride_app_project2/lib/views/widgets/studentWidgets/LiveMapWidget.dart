import 'dart:async';
import 'dart:convert'; // ✅ For jsonDecode
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LiveMapWidget extends StatefulWidget {
  final String tripId;
  const LiveMapWidget({super.key, required this.tripId});

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  late IO.Socket socket;
  LatLng? _driverLocation;
  final Completer<GoogleMapController> _controller = Completer();

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    socket = IO.io('http://192.168.0.105:5000', {
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.connect();

    socket.onConnect((_) {
      print("🧑‍🎓 Student connected to Socket");
      socket.emit('join_trip_room', 'trip_${widget.tripId}');
    });

    socket.on('trip_location_update', (data) async {
      print('📍 Received raw location data: $data');

      try {
        // Handle both string and map formats
        if (data is String) {
          data = jsonDecode(data);
        }

        final lat = data['latitude'];
        final lng = data['longitude'];

        print("✅ Parsed lat: $lat, lng: $lng");

        final newLocation = LatLng(lat, lng);

        setState(() {
          _driverLocation = newLocation;
        });

        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLng(newLocation));
      } catch (e) {
        print("❌ Error processing location update: $e");
      }
    });
  }

  @override
  void dispose() {
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _driverLocation ?? const LatLng(33.8938, 35.5018), // Default: Beirut
          zoom: 15,
        ),
        markers: _driverLocation != null
            ? {
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverLocation!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            infoWindow: const InfoWindow(title: 'Driver Location'),
          ),
        }
            : {},
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}
