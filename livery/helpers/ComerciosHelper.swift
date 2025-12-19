//
//  ComerciosHelper.swift
//  livery
//
//  Created by Nicolas Matias Garay on 19/12/2025.
//
enum ComerciosHelper {

    static func obtenerProducto(
        comercio: Comercio,
        idProducto: String
    ) -> Producto? {

        comercio.categorias
            .flatMap { $0.productos }
            .first { $0.idInterno == idProducto }
    }

    static func obtenerCategoria(
        comercio: Comercio,
        idProducto: String
    ) -> Categoria? {

        comercio.categorias.first { categoria in
            categoria.productos.contains { $0.idInterno == idProducto }
        }
    }

    static func obtenerPromocion(
        comercio: Comercio,
        idPromocion: String
    ) -> Promocion? {

        comercio.promociones.first { $0.idInterno == idPromocion }
    }
}
