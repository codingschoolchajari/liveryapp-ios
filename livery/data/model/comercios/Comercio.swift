//
//  Comercio.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation
import CoreLocation

struct ComercioIntervalo: Codable {
    var inicio: String = ""
    var fin: String = ""
}

struct ComercioHorario: Codable {
    var dia: String = ""
    var intervalos: [ComercioIntervalo] = []
}

struct ComercioPrecioEnvioPropio: Codable {
    var hasta: Int = 0
    var precio: Int = 0
}

struct ComercioEnvios: Codable {
    var envioPropio: Bool = false
    var preciosEnvioPropio: [ComercioPrecioEnvioPropio] = []
    var envioLivery: Bool = false

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        envioPropio = try container.decodeIfPresent(Bool.self, forKey: .envioPropio) ?? false
        preciosEnvioPropio = try container.decodeIfPresent([ComercioPrecioEnvioPropio].self, forKey: .preciosEnvioPropio) ?? []
        envioLivery = try container.decodeIfPresent(Bool.self, forKey: .envioLivery) ?? false
    }
}

struct ComercioDatosBancarios: Codable {
    var alias: String = ""
    var cbu: String = ""
    var titular: String = ""
}

struct ComercioDireccion: Codable {
    var calle: String = ""
    var numero: String = ""
    var departamento: String = ""
    var coordenadas: Point = Point()
}

struct Comercio: Codable, Identifiable {
    var idInterno: String = ""
    var localidad: String = ""
    var nombre: String = ""
    var puntuacion: Double = 0.0
    var direccion: ComercioDireccion = ComercioDireccion()
    var envios: ComercioEnvios = ComercioEnvios()
    var horarios: [ComercioHorario]? = []
    var datosBancarios: ComercioDatosBancarios = ComercioDatosBancarios()
    var imagenURL: String = ""
    var logoURL: String = ""
    var categoriasPrincipales: [String] = []
    var categorias: [Categoria] = []
    var promociones: [Promocion] = []
    var distanciaUsuario: Int? = nil
    
    var id: String {
        idInterno
    }
}

extension Comercio {
    func categoriasPrincipalesToString() -> String {
        categoriasPrincipales
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map {
                $0.lowercased().prefix(1).uppercased() + $0.lowercased().dropFirst()
            }
            .joined(separator: " - ")
    }
}

extension Comercio {
    func direccionToString() -> String {
        "\(direccion.calle) \(direccion.numero)".trimmingCharacters(in: .whitespaces)
    }
}

extension Comercio {
    func hayPromocionesDisponibles() -> Bool {
        promociones.contains { $0.disponible }
    }
}
