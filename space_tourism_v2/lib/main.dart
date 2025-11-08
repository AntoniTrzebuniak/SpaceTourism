import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenStreetMap w Flutter',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Początkowa pozycja mapy (Warszawa)
  final LatLng _initialPosition = const LatLng(52.2297, 21.0122);
  
  // Kontroler mapy
  final MapController _mapController = MapController();
  
  // Aktualny zoom
  double _currentZoom = 13.0;
  double _rotation = 0.0; // Aktualny obrót mapy w stopniach 
  // Lista markerów - teraz inicjalizowana w konstruktorze
  late List<Marker> _markers;

  @override
  void initState() {
    super.initState();
    _initializeMarkers();
    // Nasłuchiwanie zmian w mapie (w tym obrotu)
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate) { // ← Tylko event obrotu!
        setState(() {
          _rotation = event.camera.rotation;
        });
      }
    });
  }

  void _initializeMarkers() {
    _markers = [
      Marker(
        point: const LatLng(52.2297, 21.0122),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerInfo('Pałac Kultury i Nauki', const LatLng(52.2297, 21.0122)),
          child: const Icon(
            Icons.location_pin,
            color: Colors.red,
            size: 40,
          ),
        ),
      ),
      Marker(
        point: const LatLng(52.2370, 21.0175),
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showMarkerInfo('Stare Miasto', const LatLng(52.2370, 21.0175)),
          child: const Icon(
            Icons.location_pin,
            color: Colors.blue,
            size: 40,
          ),
        ),
      ),
    ];
  }

  void _showMarkerInfo(String title, LatLng position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text('Szerokość: ${position.latitude}\nDługość: ${position.longitude}'),
        actions: [
          TextButton(
            onPressed: () => _openInMaps(position),
            child: const Text('Otwórz w mapach'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zamknij'),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(LatLng position) async {
    final url = 'https://www.openstreetmap.org/?mlat=${position.latitude}&mlon=${position.longitude}#map=17/${position.latitude}/${position.longitude}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nie można otworzyć mapy')),
        );
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_mapController.center, _currentZoom);
    });
  }

  void _resetView() {
    setState(() {
      _currentZoom = 13.0;
      _mapController.move(_initialPosition, _currentZoom);
    });
  }
  
  void _resetToNorth() {
    setState(() {
      _rotation = 0.0;
      _mapController.rotate(0.0);
    });
  }

  void _addMarker() {
    final center = _mapController.center;
    setState(() {
      _markers.add(
        Marker(
          point: center,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showMarkerInfo('Nowy marker', center),
            child: const Icon(
              Icons.location_pin,
              color: Colors.green,
              size: 40,
            ),
          ),
        ),
      );
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dodano marker na: ${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenStreetMap w Flutter'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _resetView,
            tooltip: 'Resetuj widok',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: _initialPosition,
              zoom: _currentZoom,
              rotation: _rotation,
              maxZoom: 18.0,
              minZoom: 3.0,
              enableMultiFingerGestureRace: true, // Pozwala na jednoczesne gesty
              onTap: (tapPosition, point) {
                // Możesz dodać tutaj funkcjonalność dodawania nowych markerów
                print('Kliknięto na: $point');
              },
            ),
            children: [
              // Warstwa kafelków (tiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_osm_map',
                subdomains: const ['a', 'b', 'c'],
              ),
              
              // Warstwa markerów
              MarkerLayer(markers: _markers),
              
              // Warstwa atrybucji
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap',
                    onTap: null, // Możesz dodać obsługę kliknięcia później
                  ),
                ],
              ),
            ],
          ),
          
          // Kontrolki zoomu
          Positioned(
            right: 16,
            bottom: 96,
            child: Column(
              children: [
                FloatingActionButton.small(
                  onPressed: _zoomIn,
                  heroTag: 'zoomIn',
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  onPressed: _zoomOut,
                  heroTag: 'zoomOut',
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
          
          // Wyświetlanie współrzędnych
          Positioned(
            left: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white70,
                borderRadius: BorderRadius.circular(8),
              ),
              child: StreamBuilder<MapEvent>(
                stream: _mapController.mapEventStream,
                builder: (context, snapshot) {
                  final center = _mapController.center;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${center.latitude.toStringAsFixed(4)}, ${center.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Obrót: ${_rotation.toStringAsFixed(1)}°',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          Positioned(
            right: 10,
            bottom: 200, // Ustawione nad przyciskami zoomu
            child: GestureDetector(
              onTap: _resetToNorth,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: _rotation / 360, // Konwersja stopni na obroty
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      
      // Przycisk do dodawania markerów
      floatingActionButton: FloatingActionButton(
        onPressed: _addMarker,
        tooltip: 'Dodaj marker',
        child: const Icon(Icons.add_location),
      ),
    );
  }
}