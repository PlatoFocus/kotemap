import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../domain/models/station.dart';
import '../providers/map_provider.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/alert_banner.dart';
import '../widgets/station_marker.dart';
import '../widgets/itinerary_bottom_sheet.dart';
import '../widgets/navigation_overlay.dart';
import '../widgets/destination_stations_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  bool _followCamera = false;

  static const _dangerZone = [
    LatLng(18.5580, -72.3450),
    LatLng(18.5580, -72.3150),
    LatLng(18.5380, -72.3150),
    LatLng(18.5380, -72.3450),
  ];

  @override
  void initState() {
    super.initState();
    _initGpsStream();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // ─── GPS stream setup ──────────────────────────────────────────────────────

  Future<void> _initGpsStream() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!serviceEnabled ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // update every 5 meters
        ),
      ).listen((pos) {
        if (!mounted) return;
        final loc = LatLng(pos.latitude, pos.longitude);
        ref.read(mapProvider.notifier).setUserLocation(loc);

        final navState = ref.read(mapProvider);
        if (navState.isNavigating) {
          ref.read(mapProvider.notifier).updateNavigationProgress(loc);
          if (_followCamera) {
            _mapController.move(loc, 16);
          }
        }
      }, onError: (_) {});
    } catch (_) {
      // GPS unavailable (web without permission, unsupported platform)
    }
  }

  // ─── One-shot GPS re-center ────────────────────────────────────────────────

  Future<void> _onGpsTap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (serviceEnabled && permission != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final loc = LatLng(pos.latitude, pos.longitude);
        ref.read(mapProvider.notifier).setUserLocation(loc);
        _mapController.move(loc, 15);
      }
    } catch (_) {
      const loc = LatLng(18.5474, -72.3380);
      _mapController.move(loc, 14);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapProvider);
    final stations = ref.watch(filteredStationsProvider);

    // React to navigation state transitions
    ref.listen<bool>(
      mapProvider.select((s) => s.isNavigating),
      (prev, navigating) {
        if (navigating) {
          _followCamera = true;
          final userLoc = ref.read(mapProvider).userLocation;
          if (userLoc != null) {
            _mapController.move(userLoc, 16);
          }
        } else {
          _followCamera = false;
        }
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _buildMap(state, stations),

                // Navigation overlay replaces the search bar while navigating
                if (state.isNavigating)
                  const NavigationOverlay()
                else if (state.arrivedAtDestination)
                  const ArrivalCard()
                else
                  _buildTopOverlay(),

                // Zoom controls always visible
                _buildMapControls(),
              ],
            ),
          ),

          // Panneau bas : stations pour la destination OU itinéraires classiques
          if (!state.isNavigating && !state.arrivedAtDestination)
            state.selectedPlace != null
                ? const DestinationStationsSheet()
                : const ItineraryBottomSheet(),
        ],
      ),
    );
  }

  // ─── Map layers ────────────────────────────────────────────────────────────

  Widget _buildMap(MapState state, List<Station> stations) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(18.5474, -72.3200),
        initialZoom: 13.5,
        minZoom: 10,
        maxZoom: 18,
        // Tap on map sets destination only when NOT navigating
        onTap: state.isNavigating
            ? null
            : (tapPosition, point) =>
                ref.read(mapProvider.notifier).setDestination(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.kotemap.app',
          maxNativeZoom: 19,
        ),

        // Danger zone polygon
        PolygonLayer(
          polygons: [
            Polygon(
              points: _dangerZone,
              color: AppColors.dangerZone,
              borderColor: AppColors.dangerZoneBorder,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),

        // Route polyline: solid (OSRM) when navigating, dashed (demo) when planning
        if (state.isNavigating && state.routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: state.routePoints,
                color: AppColors.primary,
                strokeWidth: 4.5,
              ),
            ],
          )
        else if (!state.isNavigating &&
            state.routePoints.isNotEmpty)
          // Show fetched route before starting navigation
          PolylineLayer(
            polylines: [
              Polyline(
                points: state.routePoints,
                color: AppColors.primary.withValues(alpha: 0.6),
                strokeWidth: 3.5,
                pattern: StrokePattern.dashed(segments: [10, 5]),
              ),
            ],
          )
        else if (state.selectedItinerary != null &&
            state.selectedItinerary!.polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: state.selectedItinerary!.polyline,
                color: AppColors.primary,
                strokeWidth: 3.5,
                pattern: StrokePattern.dashed(segments: [12, 6]),
              ),
            ],
          ),

        // Markers
        MarkerLayer(
          markers: [
            // Station markers (hidden during navigation to reduce clutter)
            if (!state.isNavigating)
              ...stations.map(
                (station) => Marker(
                  point: station.position,
                  width: 28,
                  height: 28,
                  child: StationMarkerWidget(
                    station: station,
                    isSelected: false,
                    onTap: () => _onStationTap(station),
                  ),
                ),
              ),

            // User location dot
            if (state.userLocation != null)
              Marker(
                point: state.userLocation!,
                width: 32,
                height: 32,
                child: const UserLocationMarker(),
              ),

            // Explicit origin pin (when user set a custom starting point)
            if (state.origin != null)
              Marker(
                point: state.origin!,
                width: 20,
                height: 36,
                alignment: Alignment.bottomCenter,
                child: const _OriginMarker(),
              ),

            // Destination pin
            if (state.destination != null)
              Marker(
                point: state.destination!,
                width: 20,
                height: 36,
                alignment: Alignment.bottomCenter,
                child: const DestinationMarker(),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Top overlay (search bar + alert) ─────────────────────────────────────

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            MapSearchBar(onGpsTap: _onGpsTap),
            const AlertBanner(),
          ],
        ),
      ),
    );
  }

  // ─── Zoom controls + legend ────────────────────────────────────────────────

  Widget _buildMapControls() {
    return Positioned(
      bottom: 12,
      right: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _MapLegend(),
          const SizedBox(height: 8),
          _ZoomControls(mapController: _mapController),
        ],
      ),
    );
  }

  // ─── Station‑tap sheet ─────────────────────────────────────────────────────

  void _onStationTap(Station station) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _StationSheet(station: station),
    );
  }
}

// ─── Origin marker (green pin = starting point) ───────────────────────────────

class _OriginMarker extends StatelessWidget {
  const _OriginMarker();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Color(0x4015803D),
                  blurRadius: 4,
                  offset: Offset(0, 1))
            ],
          ),
        ),
        Container(width: 2, height: 16, color: AppColors.success),
        CustomPaint(
          size: const Size(10, 6),
          painter: _TrianglePainterGreen(),
        ),
      ],
    );
  }
}

class _TrianglePainterGreen extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.success;
    final path = ui.Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Légende ──────────────────────────────────────────────────────────────────

class _MapLegend extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LegendRow(color: AppColors.bus, label: s.legendBus),
          const SizedBox(height: 3),
          _LegendRow(color: AppColors.taptap, label: s.legendTaptap),
          const SizedBox(height: 3),
          _LegendRow(
              color: const Color(0x80EF4444), label: s.legendRisk),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 9, color: Color(0xFF555555))),
      ],
    );
  }
}

// ─── Zoom controls ────────────────────────────────────────────────────────────

class _ZoomControls extends StatelessWidget {
  final MapController mapController;
  const _ZoomControls({required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: Colors.black.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Column(
        children: [
          _ZoomButton(
            icon: Icons.add,
            onTap: () => mapController.move(
              mapController.camera.center,
              mapController.camera.zoom + 1,
            ),
          ),
          Container(
              height: 0.5,
              color: Colors.black.withValues(alpha: 0.08)),
          _ZoomButton(
            icon: Icons.remove,
            onTap: () => mapController.move(
              mapController.camera.center,
              mapController.camera.zoom - 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
          width: 30,
          height: 28,
          child: Icon(icon, size: 18, color: AppColors.primary)),
    );
  }
}

// ─── Fiche station ────────────────────────────────────────────────────────────

class _StationSheet extends ConsumerWidget {
  final Station station;
  const _StationSheet({required this.station});

  Color get _typeColor => switch (station.type) {
        StationType.bus => AppColors.bus,
        StationType.taptap => AppColors.taptap,
        StationType.moto => AppColors.moto,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.tc.surface,
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: _typeColor,
                borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: Text(station.typeInitial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(station.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(station.typeLabel,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary)),
                if (station.fareMin != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      s.tarif(station.fareMin!,
                          station.fareMax ?? station.fareMin!),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(mapProvider.notifier)
                  .setDestination(station.position);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: Text(s.goBtn,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
