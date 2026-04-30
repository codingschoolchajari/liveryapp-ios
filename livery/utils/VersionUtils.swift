//
//  VersionUtils.swift
//  livery
//
import Foundation

func hayNuevaVersionDisponible(versionApp: String, versionRequerida: String) -> Bool {
    return compararVersiones(versionApp: versionApp, versionRequerida: versionRequerida) < 0
}

func compararVersiones(versionApp: String, versionRequerida: String) -> Int {
    let partsApp = versionApp.split(separator: ".").map { Int($0) ?? 0 }
    let partsReq = versionRequerida.split(separator: ".").map { Int($0) ?? 0 }
    let maxLen = max(partsApp.count, partsReq.count)
    for i in 0..<maxLen {
        let a = i < partsApp.count ? partsApp[i] : 0
        let b = i < partsReq.count ? partsReq[i] : 0
        if a != b { return a - b }
    }
    return 0
}
