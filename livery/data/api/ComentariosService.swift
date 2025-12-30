//
//  ComentariosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ComentariosService {

    func enviarComentario(
        token: String,
        dispositivoID: String,
        email: String,
        idPedido: String,
        comentario: Comentario
    ) async throws {

        let url = URL(string: comentariosURL + "/enviar")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(comentario)

        _ = try await URLSession.shared.data(for: request)
    }

    func buscar(
        token: String,
        dispositivoID: String,
        idComercio: String,
        skip: Int,
        limit: Int
    ) async throws -> [PedidoComentario] {

        var components = URLComponents(string: comentariosURL + "/buscar/\(idComercio)")!

        components.queryItems = [
            URLQueryItem(name: "skip", value: String(skip)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)

        return try JSONDecoder().decode([PedidoComentario].self, from: data)
    }
}
