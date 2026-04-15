//
//  UsuariosService.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

class UsuariosService {

    func actualizarUsuario(token: String, dispositivoID: String, usuario: Usuario) async throws {
        guard let url = URL(string: "\(usuariosURL)/actualizar") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(usuario)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func buscarUsuario(token: String, dispositivoID: String, email: String) async throws -> Usuario {
        
        guard let url = URL(string: "\(usuariosURL)/buscar/\(email)") else {
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

        return try JSONDecoder().decode(Usuario.self, from: data)
    }
    
    func actualizarDatosPersonales(
        token: String,
        dispositivoID: String,
        email: String,
        datosPersonales: UsuarioDatosPersonales
    ) async throws {
        guard let url = URL(string: "\(usuariosURL)/actualizarDatosPersonales") else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue(email, forHTTPHeaderField: "email")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(datosPersonales)

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func guardarDireccion(
        token: String,
        dispositivoID: String,
        email: String,
        usuarioDireccion: UsuarioDireccion
    ) async throws {
        guard let url = URL(string: "\(usuariosURL)/guardarDireccion/\(email)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(usuarioDireccion)

        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }

    func validarDireccion(
        token: String,
        dispositivoID: String,
        calle: String,
        numero: String,
        latitud: Double,
        longitud: Double
    ) async throws -> BooleanResponse {
        var components = URLComponents(string: "\(usuariosURL)/validarDireccion")
        components?.queryItems = [
            URLQueryItem(name: "calle", value: calle),
            URLQueryItem(name: "numero", value: numero),
            URLQueryItem(name: "latitud", value: String(latitud)),
            URLQueryItem(name: "longitud", value: String(longitud))
        ]

        guard let url = components?.url else {
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

    func eliminarDireccion(
        token: String,
        dispositivoID: String,
        email: String,
        idDireccion: String)
    async throws {
        guard let url = URL(string: "\(usuariosURL)/eliminarDireccion/\(email)/\(idDireccion)") else {
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
    
    func agregarFavorito(
        token: String,
        dispositivoID: String,
        email: String,
        usuarioFavorito: UsuarioFavorito
    ) async throws {
        guard let url = URL(string: "\(usuariosURL)/agregarFavorito/\(email)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(usuarioFavorito)

        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
    
    func eliminarFavorito(
        token: String,
        dispositivoID: String,
        email: String,
        idFavorito: String
    ) async throws {
        guard let url = URL(string: "\(usuariosURL)/eliminarFavorito/\(email)/\(idFavorito)") else {
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
    
    func actualizarTokenFCM(
        token: String,
        dispositivoID: String,
        email: String,
        tokenFCM: String
    ) async throws {
        guard let url = URL(string: "\(usuariosURL)/actualizarTokenFCM/\(email)/\(StringUtils.plataforma)") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONEncoder().encode(tokenFCM)

        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
    
    func eliminarUsuario(
        token: String,
        dispositivoID: String,
        email: String
    ) async throws {
        guard let url = URL(string: "\(usuariosURL)/eliminarUsuario/\(email)") else {
            throw URLError(.badURL)
        }

        #if DEBUG
        print("[UsuariosService.eliminarUsuario] URL: \(url.absoluteString)")
        print("[UsuariosService.eliminarUsuario] email: \(email)")
        print("[UsuariosService.eliminarUsuario] dispositivoID: \(dispositivoID)")
        print("[UsuariosService.eliminarUsuario] token vacío: \(token.isEmpty)")
        #endif
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(dispositivoID, forHTTPHeaderField: "dispositivoID")

        let (data, response) = try await URLSession.shared.data(for: request)

        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("[UsuariosService.eliminarUsuario] status: \(httpResponse.statusCode)")
        } else {
            print("[UsuariosService.eliminarUsuario] respuesta no HTTP")
        }
        if let responseText = String(data: data, encoding: .utf8), !responseText.isEmpty {
            print("[UsuariosService.eliminarUsuario] body: \(responseText)")
        }
        #endif
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw URLError(.badServerResponse)
        }
    }
}
