//
//  ProductosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ProductosService {
    func calcularPrecioMasCaro(token: String, dispositivoID: String, idComercio: String, productos: String) async throws -> PrecioResponse {
        
        guard var components = URLComponents(string: "\(productosURL)/calcularPrecioMasCaro/\(idComercio)") else { throw URLError(.badURL) }

        components.queryItems = [
            URLQueryItem(name: "productos", value: productos)
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(PrecioResponse.self, from: data)
    }
}
