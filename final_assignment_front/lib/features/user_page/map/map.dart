import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  _LocationScreenState createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final WebSocketChannel _channel = WebSocketChannel.connect(Uri.parse('ws://your-backend-url/ws'));
  final AMapFlutterLocation _locationPlugin = AMapFlutterLocation();
  double _latitude = 0.0;
  double _longitude = 0.0;
  String _address = '';

  @override
  void initState() {
    super.initState();

    // Initialize location plugin
    _locationPlugin.setLocationOption(AMapLocationOption(
      onceLocation: false,
      needAddress: true,
    ));

    // Listen to location updates
    _locationPlugin.onLocationChanged().listen((Map<String, Object> location) {
      final latitude = location['latitude'] as double?;
      final longitude = location['longitude'] as double?;
      if (latitude != null && longitude != null) {
        setState(() {
          _latitude = latitude;
          _longitude = longitude;
        });
        _sendLocation(_latitude, _longitude);
      }
    });

    // Listen to WebSocket messages
    _channel.stream.listen((message) {
      setState(() {
        _address = json.decode(message)['formattedAddress'];
      });
    });

    // Start location updates
    _locationPlugin.startLocation();
  }

  void _sendLocation(double latitude, double longitude) {
    _channel.sink.add(json.encode({
      'type': 'get_address',
      'latitude': latitude,
      'longitude': longitude,
    }));
  }

  @override
  void dispose() {
    _channel.sink.close();
    _locationPlugin.stopLocation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location and Map Example'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AMapWidget(
              apiKey: AMapApiKey(
                androidKey: 'YOUR_ANDROID_KEY',
                iosKey: 'YOUR_IOS_KEY',
              ),
              onMapCreated: (AMapController controller) {
                // Map created callback, can be used to add additional map layers or controls
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('Latitude: $_latitude'),
                Text('Longitude: $_longitude'),
                Text('Address: $_address'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AMapApiKey({required String androidKey, required String iosKey}) {}
}
