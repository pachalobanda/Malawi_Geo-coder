import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:postgres/postgres.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _addressController = TextEditingController();
  String _coordinates = '';
  LatLng _center = const LatLng(-13.2543, 34.3015); // Initial center coordinates (for Malawi)
  LatLng? _markerPosition; // Store marker position
  String? _geocodedAddress; // Store geocoded address

  late PostgreSQLConnection _connection;

  Future<void> _connectToPostgres() async {
    _connection = PostgreSQLConnection(
      'localhost',
      5432,
      'geocoderdb',
      username: 'postgres',
      password: 'keston',
    );

    await _connection.open();

    print('Connected to PostgreSQL');
  }

  void _geocodeAddress() async {
    try {
      List<Location> locations = await locationFromAddress(_addressController.text);
      if (locations.isNotEmpty) {
        List<Placemark> placemarks = await placemarkFromCoordinates(locations.first.latitude!, locations.first.longitude!);
        if (placemarks.isNotEmpty) {
          Placemark placemark = placemarks.first;
          setState(() {
            _coordinates = 'Latitude: ${locations.first.latitude}, Longitude: ${locations.first.longitude}';
            _center = LatLng(locations.first.latitude!, locations.first.longitude!); // Update center coordinates
            _markerPosition = LatLng(locations.first.latitude!, locations.first.longitude!); // Update marker position
            _geocodedAddress = placemark.name ?? placemark.street ?? placemark.locality ?? placemark.subAdministrativeArea ?? placemark.administrativeArea ?? placemark.country; // Store geocoded address
          });
        } else {
          setState(() {
            _coordinates = 'No placemarks found for the coordinates';
            _markerPosition = null; // Clear marker position
            _geocodedAddress = null; // Clear geocoded address
          });
        }
      } else {
        setState(() {
          _coordinates = 'No coordinates found for the address';
          _markerPosition = null; // Clear marker position
          _geocodedAddress = null; // Clear geocoded address
        });
      }
    } catch (e) {
      setState(() {
        _coordinates = 'Error: $e';
        _markerPosition = null; // Clear marker position
        _geocodedAddress = null; // Clear geocoded address
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _connectToPostgres();
  }

  @override
  void dispose() {
    _connection.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Enter Address',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _geocodeAddress,
              child: const Text('Geocode'),
            ),
            const SizedBox(height: 20),
            Text(
              'Coordinates:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(_coordinates),
            const SizedBox(height: 20),
            if (_geocodedAddress != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Geocoded Address: $_geocodedAddress',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _center,
                  zoom: 10.0,
                ),
                markers: _markerPosition != null
                    ? {
                  Marker(
                    markerId: const MarkerId('geocoded-location'),
                    position: _markerPosition!,
                    infoWindow: InfoWindow(
                      title: 'Geocoded Location',
                      snippet: _coordinates,
                    ),
                  ),
                }
                    : {},
                onMapCreated: (GoogleMapController controller) {
                  // You can customize the map here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
