import Foundation

class RepartosService {

    func crearReparto(
        token: String,
        dispositivoID: String,
        reparto: Reparto
    ) async throws {
        guard let url = URL(string: "\(repartosURL)/crear") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(reparto)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func buscarPorUsuario(
        token: String,
        dispositivoID: String,
        idUsuario: String,
        estado: String,
        skip: Int,
        limit: Int
    ) async throws -> [Reparto] {
        guard var components = URLComponents(string: "\(repartosURL)/buscarPorUsuario/\(idUsuario)/\(estado)") else {
            throw URLError(.badURL)
        }

        components.queryItems = [
            URLQueryItem(name: "skip", value: "\(skip)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Reparto].self, from: data)
    }

    func buscarReparto(
        token: String,
        dispositivoID: String,
        idReparto: String
    ) async throws -> Reparto {
        guard let url = URL(string: "\(repartosURL)/buscarReparto/\(idReparto)") else {
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

        return try JSONDecoder().decode(Reparto.self, from: data)
    }

    func cancelarReparto(
        token: String,
        dispositivoID: String,
        idReparto: String,
        motivoCancelacion: String
    ) async throws {
        var components = URLComponents(string: "\(repartosURL)/cancelarReparto/\(idReparto)")
        components?.queryItems = [
            URLQueryItem(name: "extra", value: motivoCancelacion)
        ]

        guard let url = components?.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func cargarComprobante(
        token: String,
        dispositivoID: String,
        email: String,
        idReparto: String,
        comprobante: Comprobante
    ) async throws {
        let boundary = UUID().uuidString.lowercased()
        guard let url = URL(string: "\(repartosURL)/cargarComprobante/\(email)/\(idReparto)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let mimeType = StringUtils.inferMimeType(for: comprobante.extension)

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

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}
