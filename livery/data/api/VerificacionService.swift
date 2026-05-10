import Foundation

class VerificacionService {

    func generarCodigoEfectivo(
        token: String,
        dispositivoID: String
    ) async throws -> String? {
        guard let url = URL(string: "\(verificacionURL)/generarCodigoEfectivo") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            return nil
        }

        let decoded = try JSONDecoder().decode([String: String].self, from: data)
        return decoded["codigo"]
    }

    func estadoCodigoEfectivo(
        token: String,
        dispositivoID: String
    ) async throws -> Bool {
        guard let url = URL(string: "\(verificacionURL)/estadoCodigoEfectivo") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            return false
        }

        let decoded = try JSONDecoder().decode([String: Bool].self, from: data)
        return decoded["validado"] == true
    }

    func enviarCodigo(
        token: String,
        dispositivoID: String,
        telefono: String
    ) async throws -> Bool {
        guard let url = URL(string: "\(verificacionURL)/enviarCodigo") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["telefono": telefono])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            return false
        }

        let decoded = try JSONDecoder().decode([String: Bool].self, from: data)
        return decoded["exito"] == true
    }

    func validarCodigo(
        token: String,
        dispositivoID: String,
        telefono: String,
        codigo: String
    ) async throws -> Bool {
        guard let url = URL(string: "\(verificacionURL)/validarCodigo") else {
            throw URLError(.badURL)
        }

        struct Body: Encodable {
            let telefono: String
            let codigo: String
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Body(telefono: telefono, codigo: codigo))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            return false
        }

        let decoded = try JSONDecoder().decode([String: Bool].self, from: data)
        return decoded["valido"] == true
    }
}
