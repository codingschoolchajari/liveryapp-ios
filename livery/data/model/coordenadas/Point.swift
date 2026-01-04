//
//  Point.swift
//  livery
//
//  Created by Nicolas Matias Garay on 15/12/2025.
//
import Foundation
import CoreLocation

struct Point: Codable, Equatable {
    var type: String = "Point"
    var coordinates: [Double] = []
    
    func toCoordinate() -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: coordinates[0], longitude: coordinates[1])
    }
}
