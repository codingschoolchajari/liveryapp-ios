//
//  EnviosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class EnviosService {

    func calcularCosto(
        token: String,
        dispositivoID: String,
        latitudOrigen: Double,
        longitudOrigen: Double,
        latitudDestino: Double,
        longitudDestino: Double
    ) async throws -> EnvioResponse {

        var components = URLComponents(string: enviosURL + "/calcular")!

        components.queryItems = [
            URLQueryItem(name: "latitudOrigen", value: String(latitudOrigen)),
            URLQueryItem(name: "longitudOrigen", value: String(longitudOrigen)),
            URLQueryItem(name: "latitudDestino", value: String(latitudDestino)),
            URLQueryItem(name: "longitudDestino", value: String(longitudDestino))
        ]

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)

        return try JSONDecoder().decode(EnvioResponse.self, from: data)
    }
}
