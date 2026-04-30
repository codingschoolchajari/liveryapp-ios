//
//  Configuracion.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation

struct ConfiguracionIOS: Codable {
    let formularioDatosPersonalesHabilitado: Bool
}

struct ConfiguracionPlataformas: Codable {
    let versionIOS: String
    let versionAndroid: String
    let linkGooglePlay: String
    let linkAppStore: String
}

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
    let limitePagoEfectivo: Double
    let configuracionIOS: ConfiguracionIOS
    let plataformas: ConfiguracionPlataformas
}
