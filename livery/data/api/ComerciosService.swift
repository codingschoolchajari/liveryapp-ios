//
//  ComerciosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ComerciosService {
    
    func buscarComercio(
        token: String,
        dispositivoID: String, 
        idInterno: String,
        datosPrincipales: Bool = false
    ) async throws -> Comercio {

        guard var components = URLComponents(string: "\(comerciosURL)/buscar/\(idInterno)") else { throw URLError(.badURL) }

        components.queryItems = [
            URLQueryItem(name: "datosPrincipales", value: String(datosPrincipales))
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Comercio.self, from: data)
    }

    /*
    func buscarComercioPorProducto(
        perfilUsuarioState: PerfilUsuarioState,
        idInterno: String,
        idProducto: String
    ) async throws -> Comercio {
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
        
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
     */

    func buscarPorCategoria(
        token: String,
        dispositivoID: String, 
        localidad: String,
        categoria: String,
        skip: Int,
        limit: Int
    ) async throws -> [Comercio] {

        guard var components = URLComponents(string: "\(comerciosURL)/buscarPorCategoria/\(categoria)") else { throw URLError(.badURL) }

        components.queryItems = [
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue(localidad, forHTTPHeaderField: "localidad")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Comercio].self, from: data)
    }

    /*
    func buscarDescuentos(
        perfilUsuarioState: PerfilUsuarioState,
        localidad: String,
        skip: Int,
        limit: Int
    ) async throws -> [ComercioDescuentos] {
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
        
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
     */

    /*
    func buscarProductosPorPalabraClave(
        perfilUsuarioState: PerfilUsuarioState,
        localidad: String,
        palabraClave: String,
        skip: Int,
        limit: Int
    ) async throws -> [ComercioProductos] {
        
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
        
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
     */

    /*
    func comercioAbierto(
        perfilUsuarioState: PerfilUsuarioState,
        idInterno: String
    ) async throws -> BooleanResponse {

        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
        
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
     */
}
