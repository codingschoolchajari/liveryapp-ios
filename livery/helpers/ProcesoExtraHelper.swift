//
//  ProcesoExtraHelper.swift
//  livery
//
import Foundation

struct ProcesoExtraHelper {

    // MARK: - 50% OFF Segunda Unidad

    static func calcularPrecio50OffSegundaUnidad(
        seleccionadosMultiples: [String: Int],
        comercio: Comercio,
        cantidadMinima: Int?
    ) -> Double? {
        guard let preciosSeleccionados = obtenerPreciosSeleccionados(
            seleccionadosMultiples: seleccionadosMultiples,
            comercio: comercio,
            cantidadMinima: cantidadMinima
        ) else { return nil }

        let precioCaro = preciosSeleccionados.first!
        let precioBarato = preciosSeleccionados.last!
        return precioCaro + (precioBarato * 0.5)
    }

    // MARK: - Dos por Uno

    static func calcularPrecioDosPorUno(
        seleccionadosMultiples: [String: Int],
        comercio: Comercio,
        cantidadMinima: Int?
    ) -> Double? {
        guard let preciosSeleccionados = obtenerPreciosSeleccionados(
            seleccionadosMultiples: seleccionadosMultiples,
            comercio: comercio,
            cantidadMinima: cantidadMinima
        ) else { return nil }

        return preciosSeleccionados.first!
    }

    // MARK: - Privado

    private static func obtenerPreciosSeleccionados(
        seleccionadosMultiples: [String: Int],
        comercio: Comercio,
        cantidadMinima: Int?
    ) -> [Double]? {
        guard let minima = cantidadMinima, minima > 0 else { return nil }

        let seleccionadosConCantidad = seleccionadosMultiples.filter { $0.value > 0 }
        let cantidadTotalSeleccionados = seleccionadosConCantidad.values.reduce(0, +)
        guard cantidadTotalSeleccionados == minima else { return nil }

        var preciosSeleccionados: [Double] = []
        for (idSeleccionable, cantidad) in seleccionadosConCantidad {
            guard let precio = obtenerPrecioSeleccionable(comercio: comercio, idSeleccionable: idSeleccionable) else {
                return nil
            }
            preciosSeleccionados.append(contentsOf: Array(repeating: precio, count: cantidad))
        }

        guard preciosSeleccionados.count == minima else { return nil }

        return preciosSeleccionados.sorted(by: >)
    }

    private static func obtenerPrecioSeleccionable(comercio: Comercio, idSeleccionable: String) -> Double? {
        return comercio.categorias
            .flatMap { $0.productos }
            .first { producto in
                producto.idInterno == idSeleccionable ||
                (producto.personalizables?.contains { personalizable in
                    personalizable.opciones?.contains { $0.idInterno == idSeleccionable } == true
                } == true)
            }
            .map { $0.precio }
    }
}
