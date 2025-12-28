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

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if !(200...299 ~= httpResponse.statusCode) {
            // 1. Imprime el código de estado (401, 404, 500, etc.)
            print("❌ ERROR HTTP: \(httpResponse.statusCode)")
            
            // 2. Intenta leer el mensaje de error que envía el Backend (FastAPI suele enviar un JSON)
            if let errorString = String(data: data, encoding: .utf8) {
                print("📝 DETALLE DEL SERVIDOR: \(errorString)")
            }
            
            // 3. Opcional: Ver los Headers (útil para problemas de Token/Auth)
            // print("Headers: \(httpResponse.allHeaderFields)")
            
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode(TokenResponse.self, from: data)
    }
}
