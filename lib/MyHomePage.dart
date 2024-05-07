import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

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
  String? _apiData; // Store data from API

  Future<void> _geocodeAddress() async {
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

          // Call the API to fetch data from PostGIS database
          await _fetchDataFromApi(locations.first.latitude!, locations.first.longitude!);
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

  Future<void> _fetchDataFromApi(double latitude, double longitude) async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/api/data?lat=$latitude&lon=$longitude'));
      if (response.statusCode == 200) {
        // Parse the JSON response
        final data = jsonDecode(response.body);
        // Update the UI with the data
        setState(() {
          _apiData = data['result']; // Assuming your API returns data under 'result' key
        });
      } else {
        throw Exception('Failed to load data from API');
      }
    } catch (e) {
      print('Error fetching data from API: $e');
    }
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
            const SizedBox(height: 20),
            if (_apiData != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Data from API: $_apiData',
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
