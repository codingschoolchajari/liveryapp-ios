//
//  DireccionViewModel.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI
import CoreLocation
import GooglePlaces

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
    @Published var mostrarPopupAdvertencia: Bool = false
    
    private var yaFijoUbicacionInicial = false
    @Published var coordenadasInicialesGPS: CLLocationCoordinate2D?

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
                guard let self = self else { return }
                
                // 2. Solo actualizamos si es la primera carga
                if !self.yaFijoUbicacionInicial {
                    self.coordenadas = coord
                    self.coordenadasInicialesGPS = coord
                    self.yaFijoUbicacionInicial = true
                    self.locationService.stopUpdatingLocation()
                }
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
        perfilUsuarioState: PerfilUsuarioState
    ) async -> String? {
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""

        guard let email = perfilUsuarioState.usuario?.email else {
            print("Error: No existe email del usuario")
            return nil
        }
        
        guard let coords = self.coordenadas else {
            print("Error: El objeto coordenadas es nulo")
            return nil
        }
        
        do {
            let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""

            let coincide = await validarDireccion(
                token: accessToken,
                dispositivoID: dispositivoID,
                calle: self.calle,
                numero: self.numero,
                latitud: coords.latitude,
                longitud: coords.longitude
            )

            if !coincide {
                mostrarPopupAdvertencia = true
                return nil
            }

            let idDireccion = UUID().uuidString.lowercased()

            return try await guardarDireccionInterno(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idDireccion: idDireccion,
                coords: coords
            )
        } catch {
            print("Error al guardar direccion: \(error.localizedDescription)")
            return nil
        }
    }

    func confirmarGuardar(perfilUsuarioState: PerfilUsuarioState) async -> String? {
        mostrarPopupAdvertencia = false

        guard let email = perfilUsuarioState.usuario?.email else {
            print("Error: No existe email del usuario")
            return nil
        }

        guard let coords = self.coordenadas else {
            print("Error: El objeto coordenadas es nulo")
            return nil
        }

        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
        let idDireccion = UUID().uuidString.lowercased()

        do {
            return try await guardarDireccionInterno(
                token: accessToken,
                dispositivoID: dispositivoID,
                email: email,
                idDireccion: idDireccion,
                coords: coords
            )
        } catch {
            print("Error al confirmar guardado de direccion: \(error.localizedDescription)")
            return nil
        }
    }

    func ocultarPopupAdvertencia() {
        mostrarPopupAdvertencia = false
    }

    private func validarDireccion(
        token: String,
        dispositivoID: String,
        calle: String,
        numero: String,
        latitud: Double,
        longitud: Double
    ) async -> Bool {
        do {
            let respuesta = try await usuariosService.validarDireccion(
                token: token,
                dispositivoID: dispositivoID,
                calle: calle,
                numero: numero,
                latitud: latitud,
                longitud: longitud
            )
            return respuesta.valor
        } catch {
            // Si falla la validación remota, no bloqueamos el guardado.
            return true
        }
    }

    private func guardarDireccionInterno(
        token: String,
        dispositivoID: String,
        email: String,
        idDireccion: String,
        coords: CLLocationCoordinate2D
    ) async throws -> String {
        let usuarioDireccion = UsuarioDireccion(
            id: idDireccion,
            calle: self.calle,
            numero: self.numero,
            departamento: self.departamento,
            indicaciones: self.indicaciones,
            coordenadas: Point(coordinates: [coords.latitude, coords.longitude])
        )

        try await usuariosService.guardarDireccion(
            token: token,
            dispositivoID: dispositivoID,
            email: email,
            usuarioDireccion: usuarioDireccion
        )

        return idDireccion
    }
    
    func actualizarDesdePlace(_ place: GMSPlace) {
        var calle = ""
        var numero = ""

        place.addressComponents?.forEach { component in
            if component.types.contains("route") {
                calle = component.name
            }
            if component.types.contains("street_number") {
                numero = component.name
            }
        }

        onCalleChange(calle)
        onNumeroChange(numero)
        
        if let coords = place.coordinate.latitude != 0 ? place.coordinate : nil {
            self.coordenadas = coords
        }
    }

    func onCalleChange(_ texto: String) {
        self.calle = normalizarPalabras(texto)
    }

    func onNumeroChange(_ texto: String) {
        self.numero = normalizarPalabras(texto)
    }

    private func normalizarPalabras(_ texto: String) -> String {
        texto
            .split(separator: " ")
            .map { palabra in
                let minuscula = palabra.lowercased()
                guard let primera = minuscula.first else { return "" }
                return String(primera).uppercased() + String(minuscula.dropFirst())
            }
            .joined(separator: " ")
    }
}


