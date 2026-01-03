//
//  RecorridosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation
import CoreLocation

class RecorridosService {
    
    func buscar(
        token: String,
        dispositivoID: String,
        idPedido: String
    ) async throws -> Recorrido? {
        
        do {
            guard let url = URL(string: "\(recorridosURL)/buscar/\(idPedido)") else {
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
            
            return try JSONDecoder().decode(Recorrido.self, from: data)
        } catch {
            return nil
        }
    }
}
