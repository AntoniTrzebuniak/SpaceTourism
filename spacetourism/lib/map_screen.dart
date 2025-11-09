import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'geotiff_layer.dart';
import 'package:space_tourism/location.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Początkowa pozycja mapy (Warszawa)
  final LatLng _initialPosition = const LatLng(49.2, 19.8);
  
  // Kontroler mapy
  final MapController _mapController = MapController();
  
  // Aktualny zoom
  double _currentZoom = 13.0;
  double _rotation = 0.0;
  
  // Lista markerów - teraz pusta na starcie
  List<Marker> _markers = [];
  
  // Manager warstwy GeoTIFF
  final GeoTiffLayer _geoTiffLayer = GeoTiffLayer();
  
  // Tryb dodawania markera
  bool _isAddingMarker = false;
  
  // Ads
  bool _showAds = true;

  @override
  void initState() {
    super.initState();
    
    _mapController.mapEventStream.listen((event) {
      if (event is MapEventRotate) {
        setState(() {
          _rotation = event.camera.rotation;
        });
      }
    });
  }


  void _toggleGeoTiffLayer() {
    setState(() {
      _geoTiffLayer.toggleVisibility();
    });
  }

  void _showMarkerInfo(String title, LatLng position) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Align(
        alignment: Alignment.centerLeft, // ustawienie po lewej
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: AlertDialog(
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
                  TextButton(
                    onPressed: () => _removeMarker(position),
                    child: const Text('Usuń', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }/*
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
          TextButton(
            onPressed: () => _removeMarker(position),
            child: const Text('Usuń', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }*/

  void _removeMarker(LatLng position) {
    setState(() {
      _markers.removeWhere((marker) => 
        marker.point.latitude == position.latitude && 
        marker.point.longitude == position.longitude
      );
    });
    Navigator.pop(context); // Zamknij dialog
    
    /*ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marker usunięty')),
    );*/
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

  void _startAddingMarker() {
    setState(() {
      _isAddingMarker = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kliknij na mapę, aby dodać marker'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _addMarkerAtPosition(LatLng position) {
    final markerCount = _markers.length + 1;
    
    setState(() {
      _markers.add(
        Marker(
          point: position,
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => _showMarkerInfo('Marker $markerCount', position),
            child: Icon(
              Icons.location_pin,
              color: _getMarkerColor(markerCount),
              size: 40,
            ),
          ),
        ),
      );
      _isAddingMarker = false;
    });
    
    /*ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Dodano marker $markerCount na: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
        duration: const Duration(seconds: 1),
      ),
    );*/
  }

  Color _getMarkerColor(int markerNumber) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.cyan,
    ];
    return colors[(markerNumber - 1) % colors.length];
  }

  void _clearAllMarkers() {
    setState(() {
      _markers.clear();
      _isAddingMarker = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wszystkie markery zostały usunięte')),
    );
  }
//wyszukiwanie

  final TextEditingController _searchController = TextEditingController();
  List<LocationResult> _searchResults = [];
  bool _isSearching = false;
  Marker? _searchMarker;

  void _searchLocation() async {
    if (_searchController.text.isEmpty) return;
    
    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });
    
    try {
      final results = await LocationSearch.search(_searchController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd wyszukiwania: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(LocationResult result) {
    // Przenieś mapę do znalezionej lokalizacji
    _mapController.move(result.latLng, 15.0);
    
    // Dodaj marker
    setState(() {
      _searchMarker = Marker(
        point: result.latLng,
        width: 80,
        height: 80,
        child: GestureDetector(
          onTap: () => _showSearchResultInfo(result),
          child: const Icon(
            Icons.location_pin,
            color: Colors.purple,
            size: 50,
          ),
        ),
      );
    });
    
    // Ukryj wyniki wyszukiwania
    setState(() {
      _searchResults.clear();
    });
    
    // Opcjonalnie: schowaj klawiaturę
    FocusScope.of(context).unfocus();
  }

  void _showSearchResultInfo(LocationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Znaleziona lokalizacja'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.displayName),
            const SizedBox(height: 8),
            Text('Szerokość: ${result.lat.toStringAsFixed(6)}'),
            Text('Długość: ${result.lon.toStringAsFixed(6)}'),
            Text('Typ: ${result.type}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _openInMaps(result.latLng),
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

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResults.clear();
      _searchMarker = null;
    });
    FocusScope.of(context).unfocus();
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
          if (_markers.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearAllMarkers,
              tooltip: 'Usuń wszystkie markery',
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
              enableMultiFingerGestureRace: true,
              onTap: (tapPosition, point) {
                if (_isAddingMarker) {
                  _addMarkerAtPosition(point);
                } else {
                  _clearSearch();
                  print('Kliknięto na: $point');
                }
              },
            ),
            children: [
              // Warstwa kafelków (tiles)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_osm_map',
                subdomains: const ['a', 'b', 'c'],
              ),
              
              // Warstwa GeoTIFF
              _geoTiffLayer.buildLayer(),
              
              // Warstwa markerów
              MarkerLayer(
                markers: [
                  ..._markers,
                  if (_searchMarker != null) _searchMarker!,
                ],),
              
              // Warstwa atrybucji
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap',
                    onTap: null,
                  ),
                ],
              ),
            ],
          ),
          

          // pasek wyszukiwania
          Positioned(
            top: 16,
            left: 80,
            right: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Szukaj lokalizacji...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _searchLocation(),
                        ),
                      ),
                      IconButton(
                        icon: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.search),
                        onPressed: _searchLocation,
                      ),
                    ],
                  ),
                  
                  // Wyniki wyszukiwania
                  if (_searchResults.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on, size: 20),
                            title: Text(
                              result.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectSearchResult(result),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Kontrolki zoomu
          Positioned(
            right: 16,
            bottom: 42,
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
          
          // Przycisk GeoTIFF
          Positioned(
            left: 16,
            top: 16,
            child: FloatingActionButton.small(
              onPressed: _toggleGeoTiffLayer,
              heroTag: 'geoTiffToggle',
              backgroundColor: _geoTiffLayer.isVisible ? Colors.blue : Colors.grey,
              child: Icon(
                _geoTiffLayer.isVisible ? Icons.layers : Icons.layers_outlined,
                color: Colors.white,
              ),
            ),
          ),
          
          // Wyświetlanie współrzędnych i informacji
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
                      Text(
                        'GeoTIFF: ${_geoTiffLayer.isVisible ? 'ON' : 'OFF'}',
                        style: TextStyle(
                          fontSize: 10,
                          color: _geoTiffLayer.isVisible ? Colors.green : Colors.red,
                        ),
                      ),
                      Text(
                        'Markery: ${_markers.length}',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      if (_isAddingMarker)
                        Text(
                          'Tryb dodawania...',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Kompas
          Positioned(
            right: 10,
            bottom: 146,
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
                  turns: _rotation / 360,
                  child: const Icon(
                    Icons.navigation,
                    color: Colors.blue,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
      // dodawanie markerów
      Positioned(
            right: 8,
            bottom: 212,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_markers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: FloatingActionButton(
                      onPressed: _clearAllMarkers,
                      heroTag: 'clearMarkers',
                      mini: true,
                      backgroundColor: Colors.red,
                      child: const Icon(Icons.delete, size: 15),
                    ),
                  ),
                FloatingActionButton(
                  onPressed: _startAddingMarker,
                  heroTag: 'addMarker',
                  backgroundColor: _isAddingMarker ? Colors.orange : Colors.blue,
                  child: Icon(
                    _isAddingMarker ? Icons.add_location_alt : Icons.add_location,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // Przycisk do dodawania markerów
      /*floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_markers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton(
                onPressed: _clearAllMarkers,
                heroTag: 'clearMarkers',
                mini: true,
                backgroundColor: Colors.red,
                child: const Icon(Icons.delete, size: 20),
              ),
            ),
          FloatingActionButton(
            onPressed: _startAddingMarker,
            heroTag: 'addMarker',
            backgroundColor: _isAddingMarker ? Colors.orange : Colors.blue,
            child: Icon(
              _isAddingMarker ? Icons.add_location_alt : Icons.add_location,
            ),
          ),
        ],
      ),*/
    );
  }
}