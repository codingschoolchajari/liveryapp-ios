//
//  API.swift
//  livery
//
//  Created by Nicolas Matias Garay on 16/12/2025.
//
import Foundation

struct API {
    static var baseURL: String {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String else {
            fatalError("API_BASE_URL not set in Info.plist")
        }
        return url
    }
    
    struct Endpoints {
        static let chats = "/chats"
        static let coberturas = "/coberturas"
        static let comentarios = "/comentarios"
        static let comercios = "/comercios"
        static let configuraciones = "/configuraciones"
        static let envios = "/envios"
        static let pedidos = "/pedidos"
        static let premios = "/premios"
        static let productos = "/productos"
        static let recorridos = "/recorridos"
        static let token = "/token"
        static let usuarios = "/usuarios"
    }
}

let chatsURL = API.baseURL + API.Endpoints.chats
let coberturasURL = API.baseURL + API.Endpoints.coberturas
let comentariosURL = API.baseURL + API.Endpoints.comentarios
let comerciosURL = API.baseURL + API.Endpoints.comercios
let configuracionesURL = API.baseURL + API.Endpoints.configuraciones
let enviosURL = API.baseURL + API.Endpoints.envios
let pedidosURL = API.baseURL + API.Endpoints.pedidos
let premiosURL = API.baseURL + API.Endpoints.premios
let productosURL = API.baseURL + API.Endpoints.productos
let recorridosURL = API.baseURL + API.Endpoints.recorridos
let tokenURL = API.baseURL + API.Endpoints.token
let usuariosURL = API.baseURL + API.Endpoints.usuarios
