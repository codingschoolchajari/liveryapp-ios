import Foundation

class RepartidoresService {
    func obtenerEstadisticas(
        token: String,
        dispositivoID: String,
        localidad: String
    ) async throws -> RepartidoresEstadisticasResponse {
        guard let url = URL(string: "\(repartidoresURL)/estadisticas/\(localidad)") else {
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

        return try JSONDecoder().decode(RepartidoresEstadisticasResponse.self, from: data)
    }
}
