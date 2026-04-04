import Foundation

struct DireccionReparto: Codable, Equatable {
    var calle: String = ""
    var numero: String = ""
    var departamento: String = ""
    var coordenadas: Point = Point()
}

struct RepartoEstadoData: Codable, Equatable {
    let fechaCreacion: String
    let fechaUltimaActualizacion: String
    var nombre: String = ""
    var extra: String? = ""
}

struct Reparto: Codable, Identifiable, Equatable {
    let idInterno: String
    let tipo: String?
    let idUsuario: String?
    let nombreUsuario: String
    let idComercio: String?
    let nombreComercio: String?
    var logoComercioURL: String?
    let idRepartidor: String?
    let nombreRepartidor: String?
    let direccion: DireccionReparto
    let direccionOrigen: DireccionReparto?
    let localidad: String
    let tarifaServicio: Double
    let envio: Double
    let indicaciones: String?
    let descripcion: String?
    var estado: RepartoEstadoData?

    var id: String {
        idInterno
    }
}
