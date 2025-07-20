import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MapStyle {
  normal,
  dark,
  silver,
  retro,
  night,
  aubergine,
}

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  LatLng? _currentPosition;
  LatLng? _lastPosition;
  bool _isUserMoving = false;
  StreamSubscription<Position>? _positionStream;
  bool _isLoadingLocation = true;
  String? _errorMessage;
  final Map<String, Marker> _allMarkers = {};
  final User? user = FirebaseAuth.instance.currentUser;
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _determineAndTrackPosition();
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    final brightness = MediaQuery.of(context).platformBrightness;
    await _applyMapStyle(
      brightness == Brightness.dark ? MapStyle.dark : MapStyle.normal,
    );
  }

  Future<void> _applyMapStyle(MapStyle style) async {
    if (mapController == null) return;

    String? styleJson;

    switch (style) {
      case MapStyle.normal:
        styleJson = null;
        break;
      case MapStyle.dark:
        styleJson = await rootBundle.loadString('assets/map_dark.json');
        break;
      case MapStyle.silver:
        styleJson = await rootBundle.loadString('assets/map_silver.json');
        break;
      case MapStyle.retro:
        styleJson = await rootBundle.loadString('assets/map_retro.json');
        break;
      case MapStyle.night:
        styleJson = await rootBundle.loadString('assets/map_night.json');
        break;
      case MapStyle.aubergine:
        styleJson = await rootBundle.loadString('assets/map_aubergine.json');
        break;
    }

    await mapController?.setMapStyle(styleJson);
  }

  Future<void> _showLoadingDialog(Future<void> Function() action) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    await Future.delayed(const Duration(milliseconds: 300));
    await action();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _determineAndTrackPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied.');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied.');
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final LatLng latLng = LatLng(position.latitude, position.longitude);
      _lastPosition = latLng;

      final BitmapDescriptor icon = await _getProfileMarkerIcon(
        user?.photoURL,
        isMoving: false,
      );

      if (!mounted) return;

      setState(() {
        _currentPosition = latLng;
        _isLoadingLocation = false;

        if (user != null) {
          _allMarkers[user!.uid] = Marker(
            markerId: MarkerId(user!.uid),
            position: latLng,
            icon: icon,
            infoWindow: InfoWindow(
              title: user?.displayName ?? 'You',
              snippet: user?.email ?? '',
            ),
          );
        }
      });

      mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
      _listenToOtherUsers();

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).listen((Position pos) async {
        final LatLng updatedLatLng = LatLng(pos.latitude, pos.longitude);

        bool isMoving = false;
        if (_lastPosition != null) {
          double distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            updatedLatLng.latitude,
            updatedLatLng.longitude,
          );
          isMoving = distance > 2.0;
        }

        _lastPosition = updatedLatLng;
        _isUserMoving = isMoving;

        final icon = await _getProfileMarkerIcon(
          user?.photoURL,
          isMoving: isMoving,
        );

        if (user != null) {
          FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
            'location': {
              'latitude': pos.latitude,
              'longitude': pos.longitude,
            },
            'name': user!.displayName,
            'email': user!.email,
            'photoURL': user!.photoURL,
          }, SetOptions(merge: true));

          if (!mounted) return;

          setState(() {
            _currentPosition = updatedLatLng;
            _allMarkers[user!.uid] = Marker(
              markerId: MarkerId(user!.uid),
              position: updatedLatLng,
              icon: icon,
              infoWindow: InfoWindow(
                title: user?.displayName ?? 'You',
                snippet: user?.email ?? '',
              ),
            );
          });
        }
      });
    } catch (e) {
      _showError('Error getting location: $e');
    }
  }

  void _listenToOtherUsers() {
    FirebaseFirestore.instance.collection('users').snapshots().listen(
      (snapshot) async {
        final updatedMarkers = Map<String, Marker>.from(_allMarkers);

        for (var doc in snapshot.docs) {
          if (doc.id == user?.uid) continue;

          final data = doc.data();
          if (data.containsKey('location') && data['location'] != null) {
            final lat = data['location']['latitude'];
            final lng = data['location']['longitude'];
            final LatLng latLng = LatLng(lat, lng);

            final String photoURL = data['photoURL'] ?? '';
            final String displayName = data['name'] ?? 'Other User';
            final String email = data['email'] ?? '';
            final String bio = data['bio'] ?? 'No bio provided';

            final BitmapDescriptor icon =
                await _getProfileMarkerIcon(photoURL, isMoving: false);

            updatedMarkers[doc.id] = Marker(
              markerId: MarkerId(doc.id),
              position: latLng,
              icon: icon,
              infoWindow: InfoWindow(
                title: displayName,
                snippet: '$email\n$bio',
              ),
            );
          } else {
            updatedMarkers.remove(doc.id);
          }
        }

        if (mounted) {
          setState(() {
            _allMarkers.clear();
            _allMarkers.addAll(updatedMarkers);
          });
        }
      },
      onError: (error) {
        _showError("Failed to load other users' locations.");
      },
    );
  }

  Future<BitmapDescriptor> _getProfileMarkerIcon(
    String? photoUrl, {
    bool isMoving = false,
  }) async {
    try {
      Uint8List imageData;

      if (photoUrl != null && photoUrl.isNotEmpty) {
        final networkImage = NetworkImage(photoUrl);
        final completer = Completer<ImageInfo>();
        networkImage.resolve(const ImageConfiguration()).addListener(
          ImageStreamListener((info, _) => completer.complete(info)),
        );
        final imageInfo = await completer.future;
        final byteData =
            await imageInfo.image.toByteData(format: ui.ImageByteFormat.png);
        imageData = byteData!.buffer.asUint8List();
      } else {
        final byteData = await rootBundle.load('assets/user.png');
        imageData = byteData.buffer.asUint8List();
      }

      final circularImage =
          await _createCircularImage(imageData, isMoving: isMoving);
      return BitmapDescriptor.fromBytes(circularImage);
    } catch (e) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  Future<Uint8List> _createCircularImage(
    Uint8List data, {
    int size = 120,
    bool isMoving = false,
  }) async {
    final borderWidth = 6;
    final borderSize = size + 2 * borderWidth;

    final codec = await ui.instantiateImageCodec(
      data,
      targetWidth: size,
      targetHeight: size,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final Paint borderPaint = Paint()
      ..color = isMoving ? Colors.greenAccent : Colors.blue
      ..style = PaintingStyle.fill;

    final Paint imagePaint = Paint();

    final center = Offset(borderSize / 2, borderSize / 2);
    final radius = borderSize / 2;

    // Draw border circle
    canvas.drawCircle(center, radius, borderPaint);

    final innerRadius = size / 2;
    final innerOffset = Offset(borderWidth.toDouble(), borderWidth.toDouble());

    canvas.save();
    canvas.translate(innerOffset.dx, innerOffset.dy);
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: Offset(size / 2, size / 2), radius: innerRadius)),
    );

    // Draw image inside circle
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
      imagePaint,
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(borderSize, borderSize);
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoadingLocation = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToCurrentLocation() {
    if (mapController == null || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Map or location not ready')),
      );
      return;
    }

    mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: _currentPosition!, zoom: 17, tilt: 60),
      ),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isLoadingLocation)
            const Center(child: CircularProgressIndicator())
          else if (_errorMessage != null)
            Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          else
            GoogleMap(
              onMapCreated: _onMapCreated,
              mapType: _currentMapType,
              initialCameraPosition: CameraPosition(
                target: _currentPosition ?? const LatLng(33.5936, 130.4077),
                zoom: 16,
              ),
              markers: Set<Marker>.of(_allMarkers.values),
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoom_in',
            mini: true,
            onPressed: () => mapController?.animateCamera(CameraUpdate.zoomIn()),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'zoom_out',
            mini: true,
            onPressed: () => mapController?.animateCamera(CameraUpdate.zoomOut()),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'go_to_user',
            onPressed: _goToCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'style_switcher',
            onPressed: () {
              if (_currentMapType != MapType.normal) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom styles only work with normal map')),
                );
                return;
              }

              showModalBottomSheet(
                context: context,
                builder: (context) => ListView(
                  shrinkWrap: true,
                  children: MapStyle.values.map((style) {
                    return ListTile(
                      title: Text(style.toString().split('.').last),
                      onTap: () async {
                        Navigator.pop(context);
                        await _showLoadingDialog(() async => await _applyMapStyle(style));
                      },
                    );
                  }).toList(),
                ),
              );
            },
            child: const Icon(Icons.style),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'map_type_switcher',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => ListView(
                  shrinkWrap: true,
                  children: MapType.values.map((type) {
                    return ListTile(
                      title: Text(type.toString().split('.').last),
                      onTap: () async {
                        Navigator.pop(context);
                        await _showLoadingDialog(() async => setState(() {
                              _currentMapType = type;
                            }));
                      },
                    );
                  }).toList(),
                ),
              );
            },
            child: const Icon(Icons.layers),
          ),
        ],
      ),
    );
  }
}