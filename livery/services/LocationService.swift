//
//  LocationService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import CoreLocation

protocol LocationServicing: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    func requestPermission()
    func startUpdatingLocation()

    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)? { get set }
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)? { get set }
}

final class LocationService: NSObject, LocationServicing, CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    var onAuthorizationChange: ((CLAuthorizationStatus) -> Void)?
    var onLocationUpdate: ((CLLocationCoordinate2D) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    var authorizationStatus: CLAuthorizationStatus {
        manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onAuthorizationChange?(manager.authorizationStatus)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let coord = locations.last?.coordinate else { return }
        onLocationUpdate?(coord)
    }
    
    func checkPermissionStatus() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .restricted, .denied:
            // Mostrar UI explicando y botón a Ajustes
            print("Permiso denegado")

        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()

        @unknown default:
            break
        }
    }
}
