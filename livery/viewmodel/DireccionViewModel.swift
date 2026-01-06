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

    private let usuariosService = UsuariosService()
    private let locationService: LocationServicing

    @Published var permissionState: LocationPermissionState = .checking
    @Published var coordenadas: CLLocationCoordinate2D?
    @Published var permisoConcedido: Bool = false

    @Published var calle: String = ""
    @Published var numero: String = ""
    @Published var departamento: String = ""
    @Published var indicaciones: String = ""

    init(locationService: LocationServicing = LocationService()) {
        self.locationService = locationService

        bindLocationService()
    }
    
    private func bindLocationService() {
        locationService.onAuthorizationChange = { [weak self] status in
            DispatchQueue.main.async {
                self?.handleAuthorization(status)
            }
        }

        locationService.onLocationUpdate = { [weak self] coord in
            DispatchQueue.main.async {
                self?.coordenadas = coord
            }
        }
    }

    func verificarPermisoUbicacion() {
        if locationService.authorizationStatus == .notDetermined {
            locationService.requestPermission()
        }
    }
    
    private func handleAuthorization(_ status: CLAuthorizationStatus) {
            switch status {
            case .notDetermined:
                permissionState = .checking
                locationService.requestPermission()

            case .authorizedWhenInUse, .authorizedAlways:
                permissionState = .granted
                locationService.startUpdatingLocation()

            case .denied:
                permissionState = .denied

            case .restricted:
                permissionState = .restricted

            @unknown default:
                break
            }
        }
    
    func guardarDireccion(
        perfilUsuarioState: PerfilUsuarioState,
        email: String,
        idDireccion: String
    ) async -> Bool {
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        guard let coords = self.coordenadas else {
            print("Error: El objeto coordenadas es nulo")
            return false
        }
        
        do {
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
            
            let usuarioDireccion = UsuarioDireccion(
                id: idDireccion,
                calle: self.calle,
                numero: self.numero,
                departamento: self.departamento,
                indicaciones: self.indicaciones,
                coordenadas: Point(coordinates: [coords.latitude, coords.longitude])
            )

            try await usuariosService.guardarDireccion(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                usuarioDireccion: usuarioDireccion
            )
            
            return true
        } catch {
            print("Error al guardar direccion: \(error.localizedDescription)")
            return false
        }
    }
}


