//
//  HistorialPuntosItem.swift
//  livery
//
import Foundation

struct HistorialPuntosItem: Codable, Identifiable {
    var titulo: String = ""
    var logoURL: String = ""
    var puntos: Int = 0
    var fechaCreacion: String = ""

    var id: String { "\(titulo)_\(fechaCreacion)" }
}