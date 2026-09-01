//
//  ConfiguracionSistemaPuntos.swift
//  livery
//
import Foundation

struct ConfiguracionSistemaPuntos: Codable {
    var concepto: String = ""
    var titulo: String = ""
    var descripcion: String = ""
    var imagenURL: String = ""
    var puntos: Int = 0
    var mostrarEnListaPuntos: Bool = true
}