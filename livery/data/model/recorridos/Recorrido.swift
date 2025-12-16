//
//  Recorrido.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation
import CoreLocation

struct RecorridoCoordenada: Codable {
    let latitud: Double
    let longitud: Double
    let timestamp: Int64?

    func toCoordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitud, longitude: longitud)
    }
}

struct Recorrido: Codable {
    let idPedido: String
    let emailUsuario: String
    let idComercio: String
    let idRepartidor: String
    var coordenadas: [RecorridoCoordenada] = []

    func coordenadasToCoordinateList() -> [CLLocationCoordinate2D] {
        coordenadas.map {
            CLLocationCoordinate2D(latitude: $0.latitud, longitude: $0.longitud)
        }
    }
}
