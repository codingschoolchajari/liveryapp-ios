//
//  DoubleUtils.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import Foundation

struct DoubleUtils {
    
    static func formatearPrecio(valor: Double) -> String {
        let formatter = NumberFormatter()
        
        formatter.numberStyle = .decimal
        
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        
        // Forzamos a que no muestre decimales (equivalente a "#,###")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        // Convertimos el valor a NSNumber (requerido por el formatter)
        let numero = NSNumber(value: valor)
        
        if let resultado = formatter.string(from: numero) {
            return "$ \(resultado)"
        }
        
        return "$ \(Int(valor))"
    }
    
}
