//
//  ConfiguracionesService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class ConfiguracionesService {

    func buscar(
        token: String,
        dispositivoID: String
    ) async throws -> Configuracion {

        let url = URL(string: configuracionesURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(Configuracion.self, from: data)
    }
}
