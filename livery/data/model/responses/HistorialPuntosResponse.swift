//
//  HistorialPuntosResponse.swift
//  livery
//
import Foundation

struct HistorialPuntosResponse: Codable {
    var items: [HistorialPuntosItem] = []
    var total: Int = 0
    var skip: Int = 0
    var limit: Int = 0
    var hasMore: Bool = false
}