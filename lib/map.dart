import 'dart:async';
import 'dart:math';
import 'package:drive_diary/permission.dart';
import 'package:drive_diary/response.dart';
import 'package:logger/logger.dart';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

final logger = Logger();

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Polyline> _polylines = {};

  Future<LatLng> checkPermission(BuildContext context) async {

    final result = await checkLocationSetting();
    if (result != LocationSettingResult.enabled) {
      await recoverLocationSettings(context, result);
    }
    await drawPolyline();

    return await getCurrentLocation();
  }

  Future<void> drawPolyline () async {
    var apiResponse = response["snappedPoints"] as List<Map<String, dynamic>>;
    var coordinates = <LatLng>[];

    for (var i = 0; i < apiResponse.length; i++) {
     coordinates.add(
        LatLng(
            apiResponse[i]["location"]["latitude"] as double,
            apiResponse[i]["location"]["longitude"] as double
        )
      );
    }

    final polyline = <Polyline>{
      Polyline(
        polylineId: const PolylineId('polyline'),
        visible: true,
        points: coordinates,
        color: Colors.blue,
        width: 5,
      ),
    };
    _polylines = polyline;

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    coordinates.forEach((LatLng latLng) {
      minLat = min(minLat, latLng.latitude);
      maxLat = max(maxLat, latLng.latitude);
      minLng = min(minLng, latLng.longitude);
      maxLng = max(maxLng, latLng.longitude);
    });

    LatLngBounds bounds = LatLngBounds(southwest: LatLng(minLat, minLng), northeast: LatLng(maxLat, maxLng));
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 20);
    _controller.future.then((controller) {
      controller.animateCamera(cameraUpdate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: checkPermission(context),
      builder: (BuildContext context, AsyncSnapshot<LatLng> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return GoogleMap(
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
              target: snapshot.data ?? const LatLng(37.43296265331129, -122.08832357078792), zoom: 17.0),
          myLocationEnabled: true,
          onMapCreated: (GoogleMapController controller) {
            _controller.complete(controller);
          },
          polylines: _polylines,
        );
      },
    );
  }
}

Future<LatLng> getCurrentLocation() async {
  final position = await Geolocator.getCurrentPosition();
  return LatLng(position.latitude, position.longitude);
}