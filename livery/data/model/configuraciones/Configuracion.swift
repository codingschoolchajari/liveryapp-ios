//
//  Configuracion.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ConfiguracionIntervalosTiempo: Codable {
    let intervaloBuscarRecorrido: Int64
    let intervaloBuscarMensajeChat: Int64
}

struct ConfiguracionEnviosPrecios: Codable {
    let minimo: Double
    let maximo: Double
    let incremento: Int
    let distanciaMinima: Int
}

struct Configuracion: Codable {
    let enviosPrecios: ConfiguracionEnviosPrecios
    let intervalosTiempo: ConfiguracionIntervalosTiempo
    var palabrasClave: [String] = []
    let tarifaServicio: Double
}
