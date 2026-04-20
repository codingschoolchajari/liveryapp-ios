//
//  GoogleMapView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {

    @Binding var coordenadas: CLLocationCoordinate2D?
    var onMapLoaded: (() -> Void)? = nil

    func makeUIView(context: Context) -> GMSMapView {
        let map = GMSMapView(options: GMSMapViewOptions())
        map.isMyLocationEnabled = true
        map.settings.zoomGestures = true
        map.settings.scrollGestures = true
        map.settings.rotateGestures = true
        map.settings.tiltGestures = true
        map.overrideUserInterfaceStyle = .light
    
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        context.coordinator.parent = self
        guard let coord = coordenadas else { return }

        let camera = GMSCameraPosition(latitude: coord.latitude,
                                       longitude: coord.longitude,
                                       zoom: 17)
        mapView.animate(to: camera)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView

        init(_ parent: GoogleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            parent.coordenadas = position.target
        }

        func mapViewSnapshotReady(_ mapView: GMSMapView) {
            parent.onMapLoaded?()
        }
    }
}
