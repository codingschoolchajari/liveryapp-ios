//
//  CoberturasService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class CoberturasService {

    func buscarCiudadPorUbicacion(
        token: String,
        dispositivoID: String,
        latitud: Double,
        longitud: Double
    ) async throws -> CiudadResponse {

        var components = URLComponents(string: coberturasURL + "/buscarCiudadPorUbicacion")!
  
        components.queryItems = [
            URLQueryItem(name: "latitud", value: String(latitud)),
            URLQueryItem(name: "longitud", value: String(longitud))
        ]

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)

        return try JSONDecoder().decode(CiudadResponse.self, from: data)
    }

    func comprobarUbicacionEnBarrioPrivado(
        token: String,
        dispositivoID: String,
        localidad: String,
        latitud: Double,
        longitud: Double
    ) async throws -> BooleanResponse {

        var components = URLComponents(string: coberturasURL + "/comprobarUbicacionEnBarrioPrivado")!

        components.queryItems = [
            URLQueryItem(name: "localidad", value: localidad),
            URLQueryItem(name: "latitud", value: String(latitud)),
            URLQueryItem(name: "longitud", value: String(longitud))
        ]

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)

        return try JSONDecoder().decode(BooleanResponse.self, from: data)
    }
}
