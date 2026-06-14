import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/map_constants.dart';

class MapState {
  const MapState({
    this.showOverlay = true,
    this.overlayOpacity = MapConstants.defaultOverlayOpacity,
    this.selectedYear = MapConstants.defaultYear,
    this.currentZoom = MapConstants.defaultZoom,
  });

  final bool showOverlay;
  final double overlayOpacity;
  final int selectedYear;
  final double currentZoom;

  MapState copyWith({
    bool? showOverlay,
    double? overlayOpacity,
    int? selectedYear,
    double? currentZoom,
  }) {
    return MapState(
      showOverlay: showOverlay ?? this.showOverlay,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      selectedYear: selectedYear ?? this.selectedYear,
      currentZoom: currentZoom ?? this.currentZoom,
    );
  }
}

class MapNotifier extends StateNotifier<MapState> {
  MapNotifier() : super(const MapState());

  void toggleOverlay() {
    state = state.copyWith(showOverlay: !state.showOverlay);
  }

  void setOverlayOpacity(double opacity) {
    state = state.copyWith(overlayOpacity: opacity);
  }

  void setYear(int year) {
    state = state.copyWith(selectedYear: year);
  }

  void setZoom(double zoom) {
    state = state.copyWith(currentZoom: zoom);
  }
}

final mapProvider = StateNotifierProvider<MapNotifier, MapState>((ref) {
  return MapNotifier();
});
