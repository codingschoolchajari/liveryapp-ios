//
//  PedidosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class PedidosService {

    func crearPedido(
        token: String,
        dispositivoID: String,
        pedido: Pedido
    ) async throws {

        guard let url = URL(string: "\(pedidosURL)/crear") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(pedido)

        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func buscarPedidos(
        token: String,
        dispositivoID: String,
        email: String,
        estado: String,
        skip: Int,
        limit: Int
    ) async throws -> [Pedido] {

        var components = URLComponents(string: pedidosURL)!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "estado", value: estado),
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        let url = components.url!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Pedido].self, from: data)
    }

    func buscarPedido(
        token: String,
        dispositivoID: String,
        idPedido: String
    ) async throws -> Pedido {

        let url = URL(string: "\(pedidosURL)/\(idPedido)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Pedido.self, from: data)
    }

    func existenPendientes(
        token: String,
        dispositivoID: String,
        email: String,
        idComercio: String
    ) async throws -> BooleanResponse {
        
        guard let url = URL(string: "\(pedidosURL)/existenPendientes/\(email)/\(idComercio)") else {
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

        return try JSONDecoder().decode(BooleanResponse.self, from: data)
    }

    func eliminarPedido(
        token: String,
        dispositivoID: String,
        email: String,
        idPedido: String
    ) async throws {

        var components = URLComponents(string: pedidosURL)!
        components.queryItems = [
            URLQueryItem(name: "email", value: email),
            URLQueryItem(name: "idPedido", value: idPedido)
        ]

        let url = components.url!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        _ = try await URLSession.shared.data(for: request)
    }

    func cargarComprobante(
        token: String,
        dispositivoID: String,
        email: String,
        idPedido: String,
        comprobante: Comprobante
    ) async throws {

        let boundary = UUID().uuidString
        let url = URL(string: "\(pedidosURL)/comprobante")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let mimeType = StringUtils.inferMimeType(for: comprobante.`extension`)

        var body = Data()

        func append(_ string: String) {
            body.append(string.data(using: .utf8)!)
        }

        append("--\(boundary)\r\n")
        append("Content-Disposition: form-data; name=\"comprobante\"; filename=\"\(comprobante.nombre)\"\r\n")
        append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(comprobante.contenido)
        append("\r\n--\(boundary)--\r\n")

        request.httpBody = body

        _ = try await URLSession.shared.data(for: request)
    }
}
