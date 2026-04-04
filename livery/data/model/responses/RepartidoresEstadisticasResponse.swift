import Foundation

struct RepartidoresEstadisticasResponse: Codable {
    let localidad: String
    let repartidoresLibres: Int
    let repartidoresOcupados: Int
    let pedidosEnTransito: Int
    let pedidosEnEspera: Int
    let tiempoPromedioEspera: Int
    let demanda: String
    let timestampActualizacion: Int64
}
