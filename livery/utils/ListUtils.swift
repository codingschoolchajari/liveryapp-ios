//
//  ListUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 19/12/2025.
//
import Foundation

struct ListUtils {
    
    static let categorias: [Categoria] = [
        Categoria(idInterno: "carnes", nombre: "Carnes", imagenGenerica: "categoria_carnes"),
        Categoria(idInterno: "ensaladas", nombre: "Ensaladas", imagenGenerica: "categoria_ensaladas"),
        Categoria(idInterno: "hamburguesas", nombre: "Hamburguesas", imagenGenerica: "categoria_hamburguesas"),
        Categoria(idInterno: "helados", nombre: "Helados", imagenGenerica: "categoria_helados"),
        Categoria(idInterno: "milanesas", nombre: "Milanesas", imagenGenerica: "categoria_milanesas"),
        Categoria(idInterno: "panificados", nombre: "Panificados", imagenGenerica: "categoria_panificados"),
        Categoria(idInterno: "pastas", nombre: "Pastas", imagenGenerica: "categoria_pastas"),
        Categoria(idInterno: "picadas", nombre: "Picadas", imagenGenerica: "categoria_picadas"),
        Categoria(idInterno: "pizzas", nombre: "Pizzas", imagenGenerica: "categoria_pizzas"),
        Categoria(idInterno: "postres", nombre: "Postres", imagenGenerica: "categoria_postres"),
        Categoria(idInterno: "sandwiches", nombre: "Sándwiches", imagenGenerica: "categoria_sandwiches")
    ]
    
    static let diasSemana = ["Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado"]
}
