import Foundation

class ChatsRepartosService {

    func obtenerChat(
        token: String,
        dispositivoID: String,
        idReparto: String,
        idComercio: String? = nil,
        idRepartidor: String? = nil
    ) async throws -> Chat {
        var components = URLComponents(string: chatsRepartosURL + "/obtenerChat")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idReparto", value: idReparto)
        ]

        if let idComercio {
            queryItems.append(URLQueryItem(name: "idComercio", value: idComercio))
        }

        if let idRepartidor {
            queryItems.append(URLQueryItem(name: "idRepartidor", value: idRepartidor))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
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
        idReparto: String,
        solicitante: String,
        idComercio: String? = nil,
        idRepartidor: String? = nil
    ) async throws -> [Mensaje] {
        var components = URLComponents(string: chatsRepartosURL + "/obtenerNuevosMensajes")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "desde", value: String(describing: desde)),
            URLQueryItem(name: "idReparto", value: idReparto),
            URLQueryItem(name: "solicitante", value: solicitante)
        ]

        if let idComercio {
            queryItems.append(URLQueryItem(name: "idComercio", value: idComercio))
        }

        if let idRepartidor {
            queryItems.append(URLQueryItem(name: "idRepartidor", value: idRepartidor))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
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
        idReparto: String,
        idComercio: String? = nil,
        idRepartidor: String? = nil,
        mensaje: Mensaje
    ) async throws {
        var components = URLComponents(string: chatsRepartosURL + "/enviarMensaje")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "idReparto", value: idReparto)
        ]

        if let idComercio {
            queryItems.append(URLQueryItem(name: "idComercio", value: idComercio))
        }

        if let idRepartidor {
            queryItems.append(URLQueryItem(name: "idRepartidor", value: idRepartidor))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(mensaje)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}
