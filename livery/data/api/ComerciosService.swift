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
        datosPrincipales: Bool
    ) async throws -> Comercio {

        var components = URLComponents(string: comerciosURL + "/buscar")!
        components.queryItems = [
            URLQueryItem(name: "idInterno", value: idInterno),
            URLQueryItem(name: "datosPrincipales", value: String(datosPrincipales))
        ]

        let request = buildRequest(url: components.url!, token: token, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Comercio.self, from: data)
    }

    func buscarComercioPorProducto(
        token: String,
        dispositivoID: String,
        idInterno: String,
        idProducto: String
    ) async throws -> Comercio {

        var components = URLComponents(string: comerciosURL + "/buscarPorProducto")!
        components.queryItems = [
            URLQueryItem(name: "idInterno", value: idInterno),
            URLQueryItem(name: "idProducto", value: idProducto)
        ]

        let request = buildRequest(url: components.url!, token: token, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Comercio.self, from: data)
    }

    func buscarPorCategoria(
        token: String,
        dispositivoID: String,
        localidad: String,
        categoria: String,
        skip: Int,
        limit: Int
    ) async throws -> [Comercio] {

        var components = URLComponents(string: comerciosURL + "/buscarPorCategoria")!
        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "categoria", value: categoria),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = buildRequest(url: components.url!, token: token, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Comercio].self, from: data)
    }

    func buscarDescuentos(
        token: String,
        dispositivoID: String,
        localidad: String,
        skip: Int,
        limit: Int
    ) async throws -> [ComercioDescuentos] {

        var components = URLComponents(string: comerciosURL + "/descuentos")!
        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = buildRequest(url: components.url!, token: token, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ComercioDescuentos].self, from: data)
    }

    func buscarProductosPorPalabraClave(
        token: String,
        dispositivoID: String,
        localidad: String,
        palabraClave: String,
        skip: Int,
        limit: Int
    ) async throws -> [ComercioProductos] {

        var components = URLComponents(string: comerciosURL + "/buscarProductos")!
        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "palabraClave", value: palabraClave),
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        let request = buildRequest(url: components.url!, token: token, dispositivoID: dispositivoID)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([ComercioProductos].self, from: data)
    }

    func comercioAbierto(
        token: String,
        dispositivoID: String,
        idInterno: String
    ) async throws -> BooleanResponse {

        var components = URLComponents(string: comerciosURL + "/abierto")!
        components.queryItems = [
            URLQueryItem(name: "idInterno", value: idInterno)
        ]

        let request = buildRequest(url: components.url!, token: token, dispositivoID: dispositivoID)

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
