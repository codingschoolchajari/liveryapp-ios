//
//  PremiosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class PremiosService {
    func obtenerResultadoGirarRuleta(
        token: String,
        dispositivoID: String,
        ciudad: String,
        email: String
    ) async throws -> Premio? {
        
        guard let url = URL(string: "\(premiosURL)/obtenerResultadoGirarRuleta/\(ciudad)/\(email)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(Premio?.self, from: data)
    }
}
