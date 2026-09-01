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

    func obtenerPremiosAsignados(
        token: String,
        dispositivoID: String,
        skip: Int
    ) async throws -> [Premio] {
        var components = URLComponents(string: "\(premiosURL)/premiosAsignados")!
        components.queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Premio].self, from: data)
    }

    func obtenerPremiosDisponibles(
        token: String,
        dispositivoID: String,
        localidad: String
    ) async throws -> [PremioDisponible] {
        guard let url = URL(string: "\(premiosURL)/premiosDisponibles") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue(localidad, forHTTPHeaderField: "localidad")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([PremioDisponible].self, from: data)
    }

    func obtenerPremiosCanjeables(
        token: String,
        dispositivoID: String,
        localidad: String
    ) async throws -> [PremioCanjeable] {
        guard let url = URL(string: "\(premiosURL)/premiosCanjeables/\(localidad)") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([PremioCanjeable].self, from: data)
    }

    func canjearProducto(
        token: String,
        dispositivoID: String,
        localidad: String,
        email: String,
        request: CanjearRequest
    ) async throws -> CanjearResponse {
        guard let url = URL(string: "\(premiosURL)/canjear/\(localidad)/\(email)") else { throw URLError(.badURL) }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(CanjearResponse.self, from: data)
    }

    func obtenerPremiosCanjeados(
        token: String,
        dispositivoID: String,
        email: String
    ) async throws -> [PremioCanjeado] {
        guard let url = URL(string: "\(premiosURL)/premiosCanjeados/\(email)") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([PremioCanjeado].self, from: data)
    }
}
