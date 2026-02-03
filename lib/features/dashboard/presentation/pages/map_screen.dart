import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smart_waste_app/core/extensions/async_value_extensions.dart';

import '../../../../core/widgets/k_widgets.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../collection_points/presentation/providers/collection_point_providers.dart';
import '../../../collection_points/data/models/collection_point_hive_model.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _defaultZoom = 13.5;
  static const _initialPosition = CameraPosition(
    target: LatLng(27.7172, 85.3240),
    zoom: _defaultZoom,
  );

  GoogleMapController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.session?.role == 'admin_driver';
    final pointsAsync = ref.watch(collectionPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () => _openPointsList(context, pointsAsync.valueOrNull ?? []),
            tooltip: 'View collection points',
          ),
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.add_location_alt_outlined),
              onPressed: () => _showAdminTip(context),
              tooltip: 'Add collection point',
            ),
        ],
      ),
      body: pointsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load points: $e')),
        data: (points) => Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (controller) => _controller = controller,
              markers: _buildMarkers(points),
              myLocationButtonEnabled: true,
              onLongPress: isAdmin ? (pos) => _promptCreate(context, pos) : null,
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: KCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${points.length} collection point${points.length == 1 ? '' : 's'} available',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _openPointsList(context, points),
                      child: const Text('View list'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(List<CollectionPointHiveModel> points) {
    return points
        .map(
          (point) => Marker(
            markerId: MarkerId(point.id),
            position: LatLng(point.latitude, point.longitude),
            infoWindow: InfoWindow(
              title: point.name,
              snippet: 'Tap to focus',
              onTap: () => _focusOn(point),
            ),
          ),
        )
        .toSet();
  }

  Future<void> _focusOn(CollectionPointHiveModel point) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(point.latitude, point.longitude),
          zoom: 16,
        ),
      ),
    );
  }

  Future<void> _promptCreate(BuildContext context, LatLng pos) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add collection point'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Location name',
              hintText: 'e.g. Ward 5 pickup zone',
            ),
            textInputAction: TextInputAction.done,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (result == null || result.trim().isEmpty) return;

    await ref.read(collectionPointsProvider.notifier).create(
          name: result,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
  }

  void _openPointsList(BuildContext context, List<CollectionPointHiveModel> points) {
    final auth = ref.read(authStateProvider).valueOrNull;
    final isAdmin = auth?.session?.role == 'admin_driver';

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (points.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No collection points yet.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: points.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final point = points[index];
            return ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(point.name),
              subtitle: Text(
                '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}',
              ),
              onTap: () {
                Navigator.of(context).pop();
                _focusOn(point);
              },
              trailing: isAdmin
                  ? IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, point),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CollectionPointHiveModel point,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove location?'),
          content: Text('Delete "${point.name}" from the collection map?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted) return;
    if (confirmed != true) return;

    await ref.read(collectionPointsProvider.notifier).delete(point.id);
    if (context.mounted) Navigator.of(context).pop();
  }

  void _showAdminTip(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Long-press on the map to add a collection point.'),
      ),
    );
  }
}
