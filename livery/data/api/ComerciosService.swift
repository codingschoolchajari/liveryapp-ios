//
//  ComerciosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ComerciosService {
    
    private let perfilUsuarioState: PerfilUsuarioState

    init(perfilUsuarioState: PerfilUsuarioState) {
        self.perfilUsuarioState = perfilUsuarioState
    }
    
    func buscarComercio(
        idInterno: String,
        datosPrincipales: Bool = false
    ) async throws -> Comercio {

        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
        
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        var components = URLComponents(string: comerciosURL + "/buscar")!
        components.queryItems = [
            URLQueryItem(name: "idInterno", value: idInterno),
            URLQueryItem(name: "datosPrincipales", value: String(datosPrincipales))
        ]

        let request = buildRequest(url: components.url!, token: accessToken, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Comercio.self, from: data)
    }

    func buscarComercioPorProducto(
        idInterno: String,
        idProducto: String
    ) async throws -> Comercio {
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
        
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        var components = URLComponents(string: comerciosURL + "/buscarPorProducto")!
        components.queryItems = [
            URLQueryItem(name: "idInterno", value: idInterno),
            URLQueryItem(name: "idProducto", value: idProducto)
        ]

        let request = buildRequest(url: components.url!, token: accessToken, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Comercio.self, from: data)
    }

    func buscarPorCategoria(
        localidad: String,
        categoria: String,
        skip: Int,
        limit: Int
    ) async throws -> [Comercio] {

        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
        
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        var components = URLComponents(string: comerciosURL + "/buscarPorCategoria")!
        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "categoria", value: categoria),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = buildRequest(url: components.url!, token: accessToken, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Comercio].self, from: data)
    }

    func buscarDescuentos(
        localidad: String,
        skip: Int,
        limit: Int
    ) async throws -> [ComercioDescuentos] {
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
        
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        var components = URLComponents(string: comerciosURL + "/descuentos")!
        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = buildRequest(url: components.url!, token: accessToken, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ComercioDescuentos].self, from: data)
    }

    func buscarProductosPorPalabraClave(
        localidad: String,
        palabraClave: String,
        skip: Int,
        limit: Int
    ) async throws -> [ComercioProductos] {
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
        
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        var components = URLComponents(string: comerciosURL + "/buscarProductos")!
        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "palabraClave", value: palabraClave),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = buildRequest(url: components.url!, token: accessToken, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ComercioProductos].self, from: data)
    }

    func comercioAbierto(
        idInterno: String
    ) async throws -> BooleanResponse {

        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.DISPOSITIVO_ID_KEY) ?? ""
        
        await TokenRepository.repository.validarToken(perfilUsuarioState: perfilUsuarioState)
        let accessToken = TokenRepository.repository.accessToken ?? ""
        
        var components = URLComponents(string: comerciosURL + "/abierto")!
        components.queryItems = [
            URLQueryItem(name: "idInterno", value: idInterno)
        ]

        let request = buildRequest(url: components.url!, token: accessToken, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(BooleanResponse.self, from: data)
    }

    // Helper
    private func buildRequest(url: URL, token: String, dispositivoID: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        return request
    }
}
