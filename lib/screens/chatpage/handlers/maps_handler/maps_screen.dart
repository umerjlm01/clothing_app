import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../chat_bloc.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key, required this.bloc, this.destination});
  final ChatScreenBloc bloc;
  final LatLng? destination;

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  ChatScreenBloc get _bloc => widget.bloc;

  @override
  void initState() {
    super.initState();
    _bloc.mapsHandler.getCurrentLocation();

    // Once we have the destination, fetch route
    if (widget.destination != null) {
      _bloc.mapsHandler.positionStream.first.then((position) {
        _bloc.mapsHandler.drawRoute(
            LatLng(position.latitude, position.longitude),
            widget.destination!);
      });
    }
  }

  @override
  void dispose() {
    _bloc.mapsHandler.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<Position>(
          stream: _bloc.mapsHandler.positionStream,
          builder: (context, snapshot) {
            Set<Marker> markers = {};
            if (snapshot.hasData) {
              final pos = snapshot.data!;
              markers.add(Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(pos.latitude, pos.longitude),
                infoWindow: const InfoWindow(title: 'You'),
              ));
            }

            if (widget.destination != null) {
              markers.add(Marker(
                markerId: const MarkerId('destination'),
                position: widget.destination!,
                infoWindow: const InfoWindow(title: 'Destination'),
              ));
            }

            return StreamBuilder<Set<Polyline>>(
                stream: _bloc.mapsHandler.polylinesStream,
                builder: (context, polySnapshot) {
                  return GoogleMap(
                    initialCameraPosition: CameraPosition(
                        target: widget.destination ??
                            const LatLng(37.7749, -122.4194),
                        zoom: 15),
                    markers: markers,
                    polylines: polySnapshot.data ?? {},
                    polygons: _bloc.mapsHandler.polygons,
                    onMapCreated: _bloc.mapsHandler.setGoogleMapController,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                  );
                });
          }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final pos = await Geolocator.getCurrentPosition();
          _bloc.mapsHandler.googleMapController?.animateCamera(
              CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)));
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}