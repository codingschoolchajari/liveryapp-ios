//
//  PremiosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class PremiosService {
    func obtenerResultadoGirarRuleta(token: String, dispositivoID: String, ciudad: String, email: String) async throws -> Premio? {
        guard var urlComponents = URLComponents(string: "\(API.baseURL)\(API.Endpoints.premios)/resultadoGirarRuleta") else {
            fatalError("URL incorrecta")
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "dispositivoID", value: dispositivoID),
            URLQueryItem(name: "ciudad", value: ciudad),
            URLQueryItem(name: "email", value: email)
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
            return nil // Permite devolver null si el backend responde con error
        }
        
        let premio = try JSONDecoder().decode(Premio?.self, from: data)
        return premio
    }
}
