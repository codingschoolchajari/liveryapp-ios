//
//  NavigationManager.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI

class NavigationManager: ObservableObject {
    // Definimos las fases principales de la app
    enum AppPhase {
        case loading
        case auth        // Pantalla de Login
        case registration // Datos Personales
        case main        // El TabView (SeccionesView)
    }
    
    @Published var currentPhase: AppPhase = .loading
    @Published var selectedSection: SeccionesView.Section = .home
    
    // Tus paths actuales se mantienen para la navegación interna de cada pestaña
    @Published var homePath = NavigationPath()
    @Published var pedidosPath = NavigationPath()
    @Published var perfilPath = NavigationPath()

    // Función para cambiar de fase (Equivalente a cambiar el Root en Android)
    func replaceRoot(with phase: AppPhase) {
        withAnimation(.easeInOut) {
            self.currentPhase = phase
        }
    }
    
    func select(_ section: SeccionesView.Section) {
        if selectedSection == section {
            resetPath(for: section)
        } else {
            selectedSection = section
        }
    }
    
    private func resetPath(for section: SeccionesView.Section) {
        switch section {
        case .home: homePath = NavigationPath()
        case .pedidos: pedidosPath = NavigationPath()
        case .perfil: perfilPath = NavigationPath()
        default: break
        }
    }
}
