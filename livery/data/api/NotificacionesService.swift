//
//  NotificacionesService.swift
//  livery
//
//  Created by Nicolas Matias Garay
//
import Foundation

class NotificacionesService {
    
    // Obtiene las notificaciones desde el backend
    func obtenerNotificaciones(
        token: String,
        dispositivoID: String,
        receptor: String,
        tipo: String
    ) async throws -> [Notificaciones] {
        
        guard let url = URL(string: "\(notificacionesURL)/obtenerNotificaciones/\(receptor)/\(tipo)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299 ~= httpResponse.statusCode) {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error al obtener notificaciones (Status: \(httpResponse.statusCode)): \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Notificaciones].self, from: data)
    }
    
    // Marca las notificaciones como leídas
    func marcarLeidas(
        token: String,
        dispositivoID: String,
        request: MarcarNotificacionesLeidasRequest
    ) async throws {
        
        guard let url = URL(string: "\(notificacionesURL)/marcarLeidas") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "PUT"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if !(200...299 ~= httpResponse.statusCode) {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ Error al marcar notificaciones como leídas (Status: \(httpResponse.statusCode)): \(errorString)")
            }
            throw URLError(.badServerResponse)
        }
    }
}
