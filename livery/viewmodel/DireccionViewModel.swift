//
//  DireccionViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI
import CoreLocation

@MainActor
class DireccionViewModel: ObservableObject {

    private let locationService: LocationServicing

    @Published var coordenadas: CLLocationCoordinate2D?
    @Published var permisoConcedido: Bool = false

    @Published var calle: String = ""
    @Published var numero: String = ""
    @Published var departamento: String = ""
    @Published var indicaciones: String = ""

    init(locationService: LocationServicing = LocationService()) {
        self.locationService = locationService

        self.locationService.onAuthorizationChange = { [weak self] status in
            Task { @MainActor in
                let granted = status == .authorizedWhenInUse || status == .authorizedAlways
                self?.permisoConcedido = granted
                if granted {
                    self?.locationService.startUpdatingLocation()
                }
            }
        }

        self.locationService.onLocationUpdate = { [weak self] coord in
            Task { @MainActor in
                self?.coordenadas = coord
            }
        }
    }

    func verificarPermisoUbicacion() {
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermission()
        }
    }
}


