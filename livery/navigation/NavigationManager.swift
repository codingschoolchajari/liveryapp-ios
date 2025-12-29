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
    @Published var descuentosPath = NavigationPath()
    @Published var carritoPath = NavigationPath()
    @Published var pedidosPath = NavigationPath()
    @Published var perfilPath = NavigationPath()
    
    // Función para cambiar de fase (Equivalente a cambiar el Root en Android)
    func replaceRoot(with phase: AppPhase) {
        withAnimation(.easeInOut) {
            self.currentPhase = phase
        }
    }
    
    func select(_ section: SeccionesView.Section) {
        // Si cambiamos de sección (ej. de Home a Descuentos)
        if selectedSection != section {
            resetAllPaths()
        }
        
        // Si ya estamos en la sección y volvemos a presionar,
        // también aseguramos que se limpie
        if selectedSection == section {
            resetPath(for: section)
        }
        
        selectedSection = section
    }
    
    private func resetAllPaths() {
        homePath = NavigationPath()
        descuentosPath = NavigationPath()
        carritoPath = NavigationPath()
        pedidosPath = NavigationPath()
        perfilPath = NavigationPath()
    }
    
    private func resetPath(for section: SeccionesView.Section) {
        switch section {
            case .home: homePath = NavigationPath()
            case .descuentos: descuentosPath = NavigationPath()
            case .carrito: carritoPath = NavigationPath()
            case .pedidos: pedidosPath = NavigationPath()
            case .perfil: perfilPath = NavigationPath()
        }
    }
    
    // Pantallas internas
    enum HomeDestination: Hashable {
        case direccion
        case comercio(idComercio: String)
    }
    
    enum DescuentosDestination: Hashable {
        case comercio(idComercio: String)
    }
    
    enum CarritoDestination: Hashable {
        case comercio(idComercio: String)
    }
    
    enum PedidosDestination: Hashable {
        case pedido
    }
    
    enum PerfilDestination: Hashable {
        case favoritos
        case comercio(idComercio: String)
    }
    
    func irADireccion() {
        homePath.append(HomeDestination.direccion)
    }
}
