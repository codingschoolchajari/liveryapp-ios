//
//  TokenService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class TokenService {
 
    func solicitarToken(
        request: FirebaseTokenRequest,
        dispositivoID: String
    ) async throws -> TokenResponse {

        guard let url = URL(string: "\(tokenURL)/solicitarToken") else {
            throw URLError(.badURL)
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
}
