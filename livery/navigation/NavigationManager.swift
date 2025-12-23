//
//  NavigationManager.swift
//  livery
//
//  Created by Nicolas Matias Garay on 22/12/2025.
//
import SwiftUI

class NavigationManager: ObservableObject {
    @Published var selectedSection: SeccionesView.Section = .home
    
    @Published var homePath = NavigationPath()
    @Published var pedidosPath = NavigationPath()
    @Published var perfilPath = NavigationPath()

    func select(_ section: SeccionesView.Section) {
        if selectedSection == section {
            // POP TO ROOT: Limpia el path de la sección actual
            resetPath(for: section)
        } else {
            // CAMBIO DE PESTAÑA
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
