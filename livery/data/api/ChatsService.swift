//
//  ChatsService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ChatsService {

    func obtenerChat(
        token: String,
        dispositivoID: String,
        idPedido: String,
        emailUsuario: String,
        idComercio: String? = nil,
        idRepartidor: String? = nil
    ) async throws -> Chat {

        var components = URLComponents(string: chatsURL + "/obtener")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idPedido", value: idPedido),
            URLQueryItem(name: "emailUsuario", value: emailUsuario)
        ]

        if let idComercio {
            queryItems.append(URLQueryItem(name: "idComercio", value: idComercio))
        }

        if let idRepartidor {
            queryItems.append(URLQueryItem(name: "idRepartidor", value: idRepartidor))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)

        return try JSONDecoder().decode(Chat.self, from: data)
    }

    func obtenerNuevosMensajes(
        token: String,
        dispositivoID: String,
        desde: Int64,
        idPedido: String,
        emailUsuario: String,
        idComercio: String? = nil,
        idRepartidor: String? = nil
    ) async throws -> [Mensaje] {

        var components = URLComponents(string: chatsURL + "/mensajes")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "desde", value: String(describing: desde)),
            URLQueryItem(name: "idPedido", value: idPedido),
            URLQueryItem(name: "emailUsuario", value: emailUsuario)
        ]

        if let idComercio {
            queryItems.append(URLQueryItem(name: "idComercio", value: idComercio))
        }

        if let idRepartidor {
            queryItems.append(URLQueryItem(name: "idRepartidor", value: idRepartidor))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)

        return try JSONDecoder().decode([Mensaje].self, from: data)
    }

    func enviarMensaje(
        token: String,
        dispositivoID: String,
        idPedido: String,
        emailUsuario: String,
        idComercio: String? = nil,
        idRepartidor: String? = nil,
        mensaje: Mensaje
    ) async throws {

        var components = URLComponents(string: chatsURL + "/enviar")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idPedido", value: idPedido),
            URLQueryItem(name: "emailUsuario", value: emailUsuario)
        ]

        if let idComercio {
            queryItems.append(URLQueryItem(name: "idComercio", value: idComercio))
        }

        if let idRepartidor {
            queryItems.append(URLQueryItem(name: "idRepartidor", value: idRepartidor))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            fatalError("URL incorrecta")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(mensaje)

        _ = try await URLSession.shared.data(for: request)
    }
}
