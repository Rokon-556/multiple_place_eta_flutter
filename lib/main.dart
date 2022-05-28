import 'dart:math' show cos, sqrt, asin;

import 'package:flutter/material.dart';
import 'package:flutter_maps_eta/app_constant.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const MaterialApp(home: MyApp()));

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late GoogleMapController mapController;
  late Position _currentPosition;
  String _currentAddress = '';
  String _startAddress = '';
  final CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(0.0, 0.0), //Null Island
  );

  Iterable markers = [];
  Set<Marker> markerSetFinal = <Marker>{};
  Set<Circle> circles = <Circle>{};
  var sort = [];

  PolylinePoints polylinePoints = PolylinePoints();
  Map<PolylineId, Polyline> polyLines = {};
  List<LatLng> polylineCoordinates = [];

  final _markers = Iterable.generate(
    AppConstant.list.length,
    (index) {
      return Marker(
        markerId: MarkerId(AppConstant.list[index]['id']),
        position: LatLng(
          AppConstant.list[index]['lat'],
          AppConstant.list[index]['lon'],
        ),
        infoWindow: InfoWindow(
            title: AppConstant.list[index]["title"],
            snippet: "${AppConstant.list[index]["time"]} minutes"),
      );
    },
  );

  _shortestTime() {
    AppConstant.list.sort((a, b) => a["time"].compareTo(b["time"]));
    //AppConstant.list.firstWhere((element) => element.length,orElse: ()=>null)
    var sortedList = AppConstant.list;
    print("x");
    print('sorted list:$sortedList');
    print(
        "shortest latlong is:${AppConstant.list.first['lat']},${AppConstant.list.first['lon']} ");
    return sortedList;
  }

  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        _currentPosition = position;
        print('CURRENT POS: $_currentPosition');
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              //zoom: 10.0,
            ),
          ),
        );
      });
      await _getAddress();
    }).catchError((e) {
      print(e);
    });
  }

  //Getting place name

  _getAddress() async {
    try {
      List<Placemark> p = await placemarkFromCoordinates(
          _currentPosition.latitude, _currentPosition.longitude);

      Placemark place = p[0];
      print('p[000000000000]');
      print(p[0]);
      setState(() {
        _currentAddress =
            "${place.name}, ${place.locality}, ${place.postalCode}, ${place.country}";

        _startAddress = _currentAddress;
        print('_startAddress505505050505050');
        // print(geoAddress);
      });
      print('place.name');
      print(place.name);
    } catch (e) {
      print(e);
    }
  }

  _getCurrentMarker() async {
    Position curPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    Marker currentMarker = Marker(
      markerId: MarkerId("Current"),
      position: LatLng(curPos.latitude, curPos.longitude),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(title: 'hello', snippet: _startAddress),
      onTap: () async {
        _getAddress();
      },
    );
    markerSetFinal.add(currentMarker);
    Circle _circle = Circle(
      circleId: const CircleId('Current'),
      center: LatLng(curPos.latitude, curPos.longitude),
      radius: 100.0,
      strokeWidth: 10,
      strokeColor: Colors.blue,
      fillColor: Colors.yellow.withOpacity(0.5),
    );
    circles.add(_circle);
    print("curPos1:${curPos.latitude}");
    print("curPos2:${curPos.latitude}");
    print("curPos3:${curPos.latitude}");
    print("curPos4:${curPos.latitude}");
  }

  _addPolyLine() {
    PolylineId id = const PolylineId("poly");
    Polyline polyline = Polyline(
        polylineId: id,
        color: Colors.red,
        width: 3,
        points: polylineCoordinates);
    polyLines[id] = polyline;
    setState(() {});
  }

  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  _moveToMarker() {
    var sort = _shortestTime();
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(sort[0]['lat'], sort[0]['lon']),
        bearing: 45.0,
        tilt: 45.0,
        zoom: 12)));
  }

  void _makeLines() async {
    sort = _shortestTime();
    print('lenght:${sort.length}');

    print('sort:$sort');

    Position curPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    await polylinePoints
        .getRouteBetweenCoordinates(
      AppConstant.googleApiKey,
      PointLatLng(curPos.latitude, curPos.longitude),
      PointLatLng(sort[0]['lat'], sort[0]['lon']),
      travelMode: TravelMode.driving,
    )
        .then((value) {
      value.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }).then((value) {
      _addPolyLine();
    });
  }

  @override
  void initState() {
    setState(() {
      markerSetFinal = _markers.toSet();
    });
    print("current Addreess:$_startAddress");
    _getCurrentMarker();
    _getCurrentLocation();
    _makeLines();
    _shortestTime();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Maps Sample App'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: <Widget>[
          GoogleMap(
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            mapType: MapType.normal,
            initialCameraPosition: _initialLocation,
            // CameraPosition(target: LatLng(23.7985053, 90.3842538), zoom: 13),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            markers: Set<Marker>.from(markerSetFinal),
            polylines: Set<Polyline>.of(polyLines.values),
            circles: circles,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ClipOval(
                    child: Material(
                      color: Colors.blue.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.blue, // inkwell color
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.add),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.zoomIn(),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipOval(
                    child: Material(
                      color: Colors.blue.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.blue, // inkwell color
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.remove),
                        ),
                        onTap: () {
                          mapController.animateCamera(
                            CameraUpdate.zoomOut(),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ClipOval(
                    child: Material(
                      color: Colors.blue.shade100, // button color
                      child: InkWell(
                        splashColor: Colors.blue, // inkwell color
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.done_outline),
                        ),
                        onTap: () {
                          showAlertDialog(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
              child: Padding(
            padding: const EdgeInsets.only(left: 15.0, bottom: 25.0),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: InkWell(
                child: Container(
                  height: 30.0,
                  width: 30.0,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: Colors.redAccent),
                  child: const Icon(
                    Icons.forward,
                    color: Colors.white,
                  ),
                ),
                onTap: _moveToMarker,
              ),
            ),
          )),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                child: ClipOval(
                  child: Material(
                    color: Colors.orange.shade100, // button color
                    child: InkWell(
                      splashColor: Colors.orange, // inkwell color
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Icon(Icons.my_location),
                      ),

                      onTap: () {
                        mapController.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(
                              target: LatLng(
                                _currentPosition.latitude,
                                _currentPosition.longitude,
                              ),
                              zoom: 12.0,
                            ),
                          ),
                        );
                        print("currentPosition");
                        print(_currentPosition.latitude);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showAlertDialog(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("No"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = ElevatedButton(
      child: const Text("Yes"),
      onPressed: () {
        Navigator.of(context).pop();
        print('Yes pressedddddd');

        setState(() {
          polylineCoordinates.clear();
          sort.removeAt(0);

          //_makeLines();
        });
        if(sort.isNotEmpty){
          _makeLines();
        }else{
          print('work finished');
           showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text("Confirmation"),
              content: const Text("You have completed all of your task"),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: const Text("Okay"),
                ),
              ],
            ),
          );
        }
      },
    );

    AlertDialog alert = AlertDialog(
      title: const Text("Destination Confirmation"),
      content: const Text("Have you reached your destination??"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
