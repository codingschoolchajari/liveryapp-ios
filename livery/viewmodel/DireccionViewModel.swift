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
    @Published var celularPais: String = "+54"
    @Published var celularNumero: String = ""
    @Published var modoManual: Bool = false
    @Published var mostrarAdvertencia: Bool = false
    @Published var modoUbicacionActual: Bool = false
    @Published var mostrarAvisoUbicacionActual: Bool = false

    private var yaFijoUbicacionInicial = false
    private var geocodingTask: Task<Void, Never>? = nil
    @Published var coordenadasInicialesGPS: CLLocationCoordinate2D?
    var ciudadSeleccionada: String? = nil

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
        
        // En modo Ubicación Actual saltamos la validación geográfica
        if modoUbicacionActual {
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
                print("Error al guardar dirección (ubicación actual): \(error.localizedDescription)")
                return nil
            }
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
            let nsError = error as NSError
            print("❌ Error al guardar direccion: \(error.localizedDescription) — dominio: \(nsError.domain) código: \(nsError.code)")
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

    func seleccionarModo(manual: Bool) {
        if manual == modoManual && !modoUbicacionActual { return }
        modoUbicacionActual = false
        modoManual = manual
        calle = ""
        numero = ""
        if manual {
            mostrarAdvertencia = true
        }
    }

    func seleccionarModoUbicacionActual() {
        if modoUbicacionActual { return }
        modoManual = false
        modoUbicacionActual = true
        calle = "S/C"
        numero = "S/N"
        mostrarAvisoUbicacionActual = true
        if let gps = coordenadasInicialesGPS {
            coordenadas = gps
        }
    }

    func onCelularPaisChange(_ codigo: String) {
        celularPais = codigo
    }

    func onCelularNumeroChange(_ texto: String) {
        celularNumero = String(texto.filter { $0.isNumber }.prefix(10))
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
        let celular: String? = celularNumero.isEmpty ? nil : "\(celularPais)\(celularNumero.trimmingCharacters(in: .whitespaces))"
        let usuarioDireccion = UsuarioDireccion(
            id: idDireccion,
            calle: self.calle,
            numero: self.numero,
            departamento: self.departamento,
            celular: celular,
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
            // Cancelar el geocoding programado por onNumeroChange: las coordenadas
            // de Google Places son más precisas que las de CLGeocoder con texto libre.
            geocodingTask?.cancel()
        }
    }

    func onCalleChange(_ texto: String) {
        self.calle = normalizarPalabras(texto)
    }

    func onNumeroChange(_ texto: String) {
        self.numero = normalizarPalabras(texto)
        guard !modoManual, !calle.isEmpty, !texto.isEmpty else { return }
        geocodingTask?.cancel()
        geocodingTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            await geocodificarCalleNumero(calle: calle, numero: texto)
        }
    }

    private func geocodificarCalleNumero(calle: String, numero: String) async {
        // Igual que Android: agregar ciudad al query para evitar resultados en otras ciudades
        let ciudadLegible = ciudadSeleccionada
            .map { $0.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "-", with: " ") }
        let query: String
        if let ciudad = ciudadLegible, !ciudad.isEmpty {
            query = "\(calle) \(numero), \(ciudad)"
        } else {
            query = "\(calle) \(numero)"
        }

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("❌ [Geocoding] API key no encontrada")
            return
        }

        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/geocode/json")!
        var queryItems = [
            URLQueryItem(name: "address", value: query),
            URLQueryItem(name: "region", value: "ar"),
            URLQueryItem(name: "key", value: apiKey)
        ]

        if let centro = coordenadasInicialesGPS ?? coordenadas {
            let delta = 0.15
            let sw = "\(centro.latitude - delta),\(centro.longitude - delta)"
            let ne = "\(centro.latitude + delta),\(centro.longitude + delta)"
            queryItems.append(URLQueryItem(name: "bounds", value: "\(sw)|\(ne)"))
        }
        components.queryItems = queryItems

        guard let url = components.url else {
            print("❌ [Geocoding] URL inválida")
            return
        }

        print("🌍 [Geocoding] consultando: \(query)")

        do {
            var request = URLRequest(url: url)
            if let bundleID = Bundle.main.bundleIdentifier {
                request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
            }
            let (data, _) = try await URLSession.shared.data(for: request)
            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("❌ [Geocoding] JSON inválido")
                return
            }
            let status = json["status"] as? String ?? "desconocido"
            guard let results = json["results"] as? [[String: Any]], !results.isEmpty else {
                print("❌ [Geocoding] sin resultados — status: \(status)")
                return
            }
            guard let geometry = results.first?["geometry"] as? [String: Any],
                  let location = geometry["location"] as? [String: Any],
                  let lat = location["lat"] as? Double,
                  let lng = location["lng"] as? Double else {
                print("❌ [Geocoding] no se pudo extraer coordenadas")
                return
            }
            print("✅ [Geocoding] resultado: (\(lat), \(lng))")
            coordenadas = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        } catch {
            print("❌ [Geocoding] error de red: \(error.localizedDescription)")
        }
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


