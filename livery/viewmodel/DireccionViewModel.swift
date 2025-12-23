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
    
    func guardarDireccion(
        perfilUsuarioState: PerfilUsuarioState,
        email: String,
        idDireccion: String
    ) async {
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        guard let coords = self.coordenadas else {
            print("Error: El objeto coordenadas es nulo")
            return
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

        } catch {
            // En Swift 'error' es una variable implícita en el bloque catch
            print("Error al guardar direccion: \(error.localizedDescription)")
        }
    }
}


