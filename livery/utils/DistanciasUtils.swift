//
//  DistanciasUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay
//
import Foundation
import CoreLocation

func calcularDistanciaRedondeada(p1: Point?, p2: Point?) -> Int {
    guard 
        let p1 = p1, 
        p1.coordinates.count >= 2,
        let p2 = p2, 
        p2.coordinates.count >= 2 
    else { return 0 }
    
    let distanciaKm = calcularDistancia(p1: p1, p2: p2)
    let distanciaMetros = distanciaKm * 1000
    
    // Dividimos por 50.0 para obtener un Double,
    // aplicamos ceil() para redondear hacia arriba,
    // y multiplicamos por 50 para volver a la escala.
    return Int(ceil(distanciaMetros / 50.0) * 50)
}

func calcularDistancia(p1: Point, p2: Point) -> Double {
    let lat1 = p1.coordinates[0]
    let lon1 = p1.coordinates[1]
    let lat2 = p2.coordinates[0]
    let lon2 = p2.coordinates[1]
    
    let radioTierra = 6371.0 // Radio en kilómetros
    
    let dLat = (lat2 - lat1) * .pi / 180
    let dLon = (lon2 - lon1) * .pi / 180
    
    let a = sin(dLat / 2) * sin(dLat / 2) +
            cos(lat1 * .pi / 180) * cos(lat2 * .pi / 180) *
            sin(dLon / 2) * sin(dLon / 2)
    
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return radioTierra * c
}
