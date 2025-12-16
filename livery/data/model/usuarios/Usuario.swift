//
//  Usuario.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct UsuarioPremios: Codable {
    var girosRestantes: Int = 0
    var historialPremios: [Premio] = []
}

struct UsuarioDatosPersonales: Codable {
    var nombre: String = ""
    var apellido: String = ""
    var dni: Int = 0
}

struct UsuarioFavorito: Codable {
    var id: String = ""
    var idComercio: String = ""
    let nombreComercio: String
    var logoComercioURL: String = ""
    let idProducto: String?
    let idPromocion: String?
    var nombre: String = ""
    var imagenURL: String? = ""
}

struct UsuarioDireccion: Codable {
    var id: String = ""
    var calle: String = ""
    var numero: String = ""
    var departamento: String = ""
    var indicaciones: String = ""
    var coordenadas: Point = Point()
}

struct Usuario: Codable {
    var email: String = ""
    var nombre: String = ""
    var tokenFCM: String = ""
    var datosPersonales: UsuarioDatosPersonales? = UsuarioDatosPersonales()
    var direcciones: [UsuarioDireccion] = []
    var favoritos: [UsuarioFavorito]? = []
    var premios: UsuarioPremios? = UsuarioPremios()
}

extension Usuario {

    func obtenerNombreCompleto() -> String {
        let nombre = datosPersonales?.nombre ?? ""
        let apellido = datosPersonales?.apellido ?? ""
        return "\(nombre) \(apellido)".trimmingCharacters(in: .whitespaces)
    }

    func obtenerIdProductoFavorito(
        idComercio: String?,
        idProducto: String?
    ) -> String? {

        guard
            let idComercio,
            let idProducto,
            let favoritos
        else { return nil }

        return favoritos.first {
            $0.idComercio == idComercio && $0.idProducto == idProducto
        }?.id
    }

    func obtenerIdPromocionFavorita(
        idComercio: String?,
        idPromocion: String?
    ) -> String? {

        guard
            let idComercio,
            let idPromocion,
            let favoritos
        else { return nil }

        return favoritos.first {
            $0.idComercio == idComercio && $0.idPromocion == idPromocion
        }?.id
    }
}
