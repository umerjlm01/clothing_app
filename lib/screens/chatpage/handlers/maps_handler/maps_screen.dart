import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../chat_bloc.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key, required this.bloc, this.destination, this.isLive = false});
  final ChatScreenBloc bloc;
  final LatLng? destination;
  final bool isLive;


  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  ChatScreenBloc get _bloc => widget.bloc;
  BitmapDescriptor customIcon = BitmapDescriptor.defaultMarker;
  

  @override
  void initState() {
    super.initState();
    getCustomIcon();
    if(widget.isLive){
      _bloc.mapsHandler.getLiveLocation();
    } else{
      _bloc.mapsHandler.getCurrentLocation();
    }

    // Once we have the destination, fetch route
    if (widget.destination != null) {
      _bloc.mapsHandler.positionStream.first.then((position) {
        _bloc.mapsHandler.drawRoute(
            LatLng(position.latitude, position.longitude),
            widget.destination!);
      });
    }
  }
  void getCustomIcon() async {
    BitmapDescriptor.asset(ImageConfiguration(size: Size(35, 35)), 'assets/images/location.png').then((d) => customIcon = d);
  }

  @override
  void dispose() {
    if(widget.isLive){
    _bloc.mapsHandler.stopTracking();}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      centerTitle: true,
      title: Text(widget.isLive ? "Live Location" : "Current Location",
),
      iconTheme: const IconThemeData(color: Colors.black87),
    ),
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
                icon: customIcon,
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