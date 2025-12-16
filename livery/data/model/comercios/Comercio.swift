//
//  Comercio.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ComercioIntervalo: Codable {
    var inicio: String = ""
    var fin: String = ""
}

struct ComercioHorario: Codable {
    var dia: String = ""
    var intervalos: [ComercioIntervalo] = []
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

struct Comercio: Codable {
    var idInterno: String = ""
    var localidad: String = ""
    var nombre: String = ""
    var puntuacion: Double = 0.0
    var direccion: ComercioDireccion = ComercioDireccion()
    var horarios: [ComercioHorario]? = []
    var datosBancarios: ComercioDatosBancarios = ComercioDatosBancarios()
    var imagenURL: String = ""
    var logoURL: String = ""
    var categoriasPrincipales: [String] = []
    var categorias: [Categoria] = []
    var promociones: [Promocion] = []
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
