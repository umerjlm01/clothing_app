import 'dart:async';
import 'dart:developer';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

class MapsHandler {
  final BehaviorSubject<Position> _positionStream = BehaviorSubject<Position>();
  Stream<Position> get positionStream => _positionStream.stream;
  StreamSubscription<Position>? _positionSub;

  final BehaviorSubject<Set<Polyline>> _polylinesStream = BehaviorSubject<Set<Polyline>>.seeded({});
  Stream<Set<Polyline>> get polylinesStream => _polylinesStream.stream;

  GoogleMapController? _googleMapController;
  GoogleMapController? get googleMapController => _googleMapController;

  void setGoogleMapController(GoogleMapController controller) {
    _googleMapController = controller;
  }

  final List<LatLng> _routePoints = [];
  final _polygonPoints = <LatLng>[];
  final polygons = <Polygon>{};

  // ---------------- Directions API ----------------
  final String googleApiKey = dotenv.env['MY_GOOGLE_API_KEY']!;

  Future<void> drawRoute(LatLng origin, LatLng destination) async {
    final url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=$googleApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] != 'OK') {
        log('Directions API error: ${data['status']}');
        return;
      }

      final points = PolylinePoints
          .decodePolyline(data['routes'][0]['overview_polyline']['points'])
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      _routePoints.clear();
      _routePoints.addAll(points);

      _polylinesStream.add({
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints,
          color: Colors.blue,
          width: 5,
        ),
      });

      // Animate camera to show full route
      if (_googleMapController != null && points.isNotEmpty) {
        _googleMapController!.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsFromLatLngList(points), 50),
        );
      }
    } catch (e, t) {
      log('drawRoute error: $e\n$t');
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list[0].latitude;
    double x1 = list[0].latitude;
    double y0 = list[0].longitude;
    double y1 = list[0].longitude;

    for (var latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(
      northeast: LatLng(x1, y1),
      southwest: LatLng(x0, y0),
    );
  }

  // ---------------- Tracking ----------------
  Future<void> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return Future.error('Location services are disabled');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        return Future.error('Location permissions are permanently denied');
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((position) {
        _positionStream.add(position);

        LatLng latLng = LatLng(position.latitude, position.longitude);
        addPointToPolygon(latLng);

        _googleMapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15),
          ),
        );
      });
    } catch (e, t) {
      log('MapsHandler getCurrentLocation error: $e\n$t');
    }
  }

  void addPointToPolygon(LatLng point) {
    _polygonPoints.add(point);
    polygons.clear();
    polygons.add(
      Polygon(
        polygonId: const PolygonId('zone1'),
        points: _polygonPoints,
        strokeColor: Colors.blue,
        strokeWidth: 2,
        fillColor: Colors.blue,
      ),
    );
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  void clear() {
    _positionStream.close();
    _googleMapController?.dispose();
    _routePoints.clear();
    _polylinesStream.close();
  }
}