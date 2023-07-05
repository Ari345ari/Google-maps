import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ByRoadDistanceCalculator {
  Future<Map<String, dynamic>> getDistance(String apiKey, double startLat, double startLng, double endLat, double endLng) async {
    String apiUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$apiKey";

    var response = await http.get(Uri.parse(apiUrl));
    var jsonResult = json.decode(response.body);

    if (jsonResult["status"] == "OK") {
      var routes = jsonResult["routes"];
      var route = routes[0];
      var legs = route["legs"];
      var leg = legs[0];

      var distance = leg["distance"]["text"];
      var duration = leg["duration"]["text"];

      return {"distance": distance, "duration": duration};
    }

    return {"distance": "", "duration": ""};
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CustomHome(),
    );
  }
}

class CustomHome extends StatefulWidget {
  const CustomHome({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _CustomHomeState createState() => _CustomHomeState();
}

class _CustomHomeState extends State<CustomHome> {
  GoogleMapController? mapController; //controller for Google map
  PolylinePoints polylinePoints = PolylinePoints();

  String googleAPIKey = "AIzaSyDbGELc0IF6zgneIFT9gM9jwthOzMUo6SQ"; //google APIkey
  Set<Marker> markers = {}; //markers for google map
  Map<PolylineId, Polyline> polylines = {}; //polylines to show direction

  LatLng startLocation = const LatLng(48.0041, 106.9246);
  LatLng endLocation = const LatLng(47.90751, 107.02199);

  String distance = "";
  String duration = "";

  @override
  void initState() {
    markers.add(
      Marker(
        //add start location marker
        markerId: const MarkerId("start"),
        position: startLocation, //position of marker
        infoWindow: const InfoWindow(
          //popup info
          title: 'Last delivery',
          snippet: 'Last delivery Marker',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue), //White circle icon for Marker
      ),
    );

    markers.add(
      Marker(
        //add destination location marker
        markerId: const MarkerId("destination"),
        position: endLocation, //position of marker
        infoWindow: const InfoWindow(
          //popup info
          title: 'Destination Point',
          snippet: 'Destination Marker',
        ),
        icon: BitmapDescriptor.defaultMarker, //Icon for Marker
      ),
    );

    getDirections(); //fetch direction polylines from Google API

    super.initState();
  }

  getDirections() async {
    String apiKey = googleAPIKey;
    ByRoadDistanceCalculator distanceCalculator = ByRoadDistanceCalculator();
    var result = await distanceCalculator.getDistance(apiKey, startLocation.latitude, startLocation.longitude, endLocation.latitude, endLocation.longitude);

    setState(() {
      distance = result['distance'];
      duration = result['duration'];
    });

    String apiUrl = "https://maps.googleapis.com/maps/api/directions/json?origin=${startLocation.latitude},${startLocation.longitude}&destination=${endLocation.latitude},${endLocation.longitude}&key=$apiKey";

    var response = await http.get(Uri.parse(apiUrl));
    var jsonResult = json.decode(response.body);

    List<LatLng> polylineCoordinates = [];

    if (jsonResult["status"] == "OK") {
      var routes = jsonResult["routes"];
      var route = routes[0];
      var legs = route["legs"];
      var leg = legs[0];
      var steps = leg["steps"];

      for (var step in steps) {
        var points = step["polyline"]["points"];
        List<PointLatLng> decodedPoints = polylinePoints.decodePolyline(points);
        polylineCoordinates.addAll(decodedPoints.map((point) => LatLng(point.latitude, point.longitude)));
      }

      addPolyLine(polylineCoordinates);
    }
  }

  String formatDuration(String duration) {
  // Split the duration into hours and minutes
  List<String> parts = duration.split(' ');
  int hours = 0;
  int minutes = 0;

  for (int i = 0; i < parts.length; i++) {
    if (parts[i].contains('hour')) {
      hours = int.parse(parts[i - 1]);
    } else if (parts[i].contains('min')) {
      minutes = int.parse(parts[i - 1]);
    }
  }

  // Construct the formatted duration string
  String formattedDuration = '';
  if (hours > 0) {
    formattedDuration += '$hours hour';
    if (hours > 1) formattedDuration += 's';
    formattedDuration += ' ';
  }
  if (minutes > 0) {
    formattedDuration += '$minutes minute';
    if (minutes > 1) formattedDuration += 's';
  }

  return formattedDuration;
}

  void addPolyLine(List<LatLng> polylineCoordinates) {
    PolylineId id = const PolylineId('poly');
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.red,
      points: polylineCoordinates,
      width: 3,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  @override
  Widget build(BuildContext context) {
    String formattedDuration = formatDuration(duration);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Going back to Factory"),
        backgroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          GoogleMap(
            //Map widget from google_maps_flutter package
            zoomGesturesEnabled: true, //enable Zoom in, out on map
            initialCameraPosition: CameraPosition(
              //innital position in map
              target: startLocation, //initial position
              zoom: 14.0, //initial zoom level
            ),
            markers: markers, //markers to show on map
            polylines: Set<Polyline>.of(polylines.values), //polylines
            mapType: MapType.normal, //map type
            onMapCreated: (controller) {
              //method called when map is created
              setState(() {
                mapController = controller;
              });
            },
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Distance",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        distance,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Duration",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formattedDuration,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}