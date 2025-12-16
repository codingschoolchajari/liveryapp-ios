//
//  ProductosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ProductosService {
    func calcularPrecioMasCaro(token: String, dispositivoID: String, idComercio: String, productos: String) async throws -> PrecioResponse {
        guard var urlComponents = URLComponents(string: "\(API.baseURL)\(API.Endpoints.productos)/precioMasCaro") else {
            fatalError("URL incorrecta")
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "dispositivoID", value: dispositivoID),
            URLQueryItem(name: "idComercio", value: idComercio),
            URLQueryItem(name: "productos", value: productos)
        ]
        
        guard let url = urlComponents.url else {
            fatalError("No se pudo construir la URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(PrecioResponse.self, from: data)
    }
}
