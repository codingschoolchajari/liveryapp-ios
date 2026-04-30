//
//  TokenRepository.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import Foundation
import JWTDecode

// Singleton
class TokenRepository {
    static let repository = TokenRepository()
    
    private let tokenService = TokenService()
    
    var accessToken: String?
    
    func solicitarToken(
        firebaseIdToken: String
    ) async {
        let dispositivoID = UserDefaults.standard.string(forKey: ConfiguracionesUtil.ID_DISPOSITIVO_KEY) ?? ""
        
        do {
            let respuesta = try await tokenService.solicitarToken(
                request: FirebaseTokenRequest(firebaseIdToken: firebaseIdToken),
                dispositivoID: dispositivoID
            )
            
            self.accessToken = respuesta.accessToken
        } catch {
            print("Error solicitando token: \(error)")
        }
    }
    
    func validarToken(perfilUsuarioState: PerfilUsuarioState) async {
        do {
            if !isTokenActive(token: self.accessToken) {
                print("[Token] accessToken inactivo, solicitando nuevo...")
                if let firebaseIdToken = await perfilUsuarioState.obtenerFirebaseIdToken() {
                    print("[Token] Firebase ID Token obtenido, solicitando accessToken...")
                    await solicitarToken(firebaseIdToken: firebaseIdToken)
                    print("[Token] accessToken resultado: \(self.accessToken != nil ? "OK" : "nil")")
                } else {
                    print("[Token] ERROR: No se pudo obtener Firebase ID Token")
                }
            } else {
                print("[Token] accessToken vigente, reutilizando")
            }
        }
    }
}

func isTokenActive(token: String?) -> Bool {
    guard let token = token else {
        return false
    }

    do {
        // Decodifica el token JWT sin verificar la firma
        let jwt = try decode(jwt: token)

        // Obtén la fecha de expiración (exp) del token
        if let expiresAt = jwt.expiresAt {
            // Compara la fecha de expiración con la fecha actual
            return expiresAt > Date()
        } else {
            // Si el token no tiene fecha de expiración, lo consideramos no válido
            return false
        }
    } catch {
        // Si ocurre un error al decodificar, el token no es válido
        return false
    }
}
