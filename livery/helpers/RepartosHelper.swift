import SwiftUI

struct RepartosHelper {
    static func obtenerEstadoReparto(estado: String) -> String {
        guard let estadoReparto = EstadoReparto.desdeString(estado) else {
            return ""
        }
        return estadoReparto.descripcion
    }

    static func obtenerColorEstadoReparto(estado: String) -> Color? {
        EstadoReparto.desdeString(estado)?.color
    }

    static func generarURLComprobante(idUsuario: String, idReparto: String) -> String {
        "images/comprobantes/\(idUsuario)/\(idReparto)/comprobante.jpg"
    }
}
