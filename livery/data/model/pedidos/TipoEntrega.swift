//
//  TipoEntrega.swift
//  livery
//
//  Created by Nicolas Matias Garay on 10/01/2026.
//
enum TipoEntrega: String, CaseIterable {
    case envioPropio = "ENVIO_PROPIO"
    case envioLivery = "ENVIO_LIVERY"
    case retiroEnComercio = "RETIRO_EN_COMERCIO"

    var descripcion: String {
        switch self {
        case .envioPropio:
            return "Envío\nPrioritario"
        case .envioLivery:
            return "Envío\nLivery"
        case .retiroEnComercio:
            return "Retiro\nen Comercio"
        }
    }

    var aclaracion: String {
        switch self {
        case .envioPropio:
            return "Repartidor propio del comercio"
        case .envioLivery:
            return "De acuerdo a la demanda puede llegar a presentar cierta demora"
        case .retiroEnComercio:
            return ""
        }
    }

    static func desdeString(_ valor: String) -> TipoEntrega? {
        return TipoEntrega.allCases.first {
            $0.rawValue.lowercased() == valor.lowercased()
        }
    }
}

