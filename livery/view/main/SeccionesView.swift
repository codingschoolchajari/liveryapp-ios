//
//  SeccionesView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct SeccionesView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @EnvironmentObject var navManager: NavigationManager
    
    enum Section {
        case home, descuentos, carrito, pedidos, perfil
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            
            // Fondo azul para el área segura superior
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Color.verdePrincipal
                        .frame(height: geometry.safeAreaInsets.top) // Altura del área segura superior
                        .ignoresSafeArea(edges: .top)
                    
                    Spacer() // El contenido principal de la vista va debajo del área segura
                }
            }
            
            // Usamos el path del navManager
            Group {
                switch navManager.selectedSection {
                case .home:
                    NavigationStack(path: $navManager.homePath) {
                        HomeView(perfilUsuarioState: perfilUsuarioState)
                            .environmentObject(perfilUsuarioState)
                            .navigationDestination(for: String.self) { view in
                                if view == "DireccionView" {
                                    DireccionView()
                                        .navigationBarBackButtonHidden(true)
                                }
                            }
                    }
                case .descuentos:
                    DescuentosView()
                case .carrito:
                    CarritoView()
                case .pedidos:
                    NavigationStack(path: $navManager.pedidosPath) {
                        PedidosView()
                            .navigationDestination(for: String.self) { view in
                                // Destinos específicos de pedidos
                            }
                    }
                case .perfil:
                    NavigationStack(path: $navManager.perfilPath) {
                        PerfilView()
                            .navigationDestination(for: String.self) { view in
                                // Destinos específicos de pedidos
                            }
                    }
                }
            }
            
            // Barra de navegación personalizada
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        navManager.select(.home)
                    }) {
                        VStack {
                            Image(systemName: "house.fill")
                                .resizable()
                                .frame(width: 28, height: 22)
                            Text("Inicio")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                        }
                    }
                    .foregroundColor(navManager.selectedSection == .home ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        navManager.select(.descuentos)
                    }) {
                        VStack {
                            Image(systemName: "tag.fill")
                                .resizable()
                                .frame(width: 26, height: 22)
                            Text("Ofertas")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                        }
                    }
                    .foregroundColor(navManager.selectedSection == .descuentos ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        navManager.select(.carrito)
                    }) {
                        VStack {
                            Image(systemName: "cart.fill")
                                .resizable()
                                .frame(width: 30, height: 22)
                            Text("Carrito")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                        }
                    }
                    .foregroundColor(navManager.selectedSection == .carrito ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        navManager.select(.pedidos)
                    }) {
                        VStack {
                            Image(systemName: "text.badge.checkmark")
                                .resizable()
                                .frame(width: 26, height: 22)
                            Text("Pedidos")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                        }
                    }
                    .foregroundColor(navManager.selectedSection == .pedidos ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        navManager.select(.perfil)
                    }) {
                        VStack {
                            Image(systemName: "person.fill")
                                .resizable()
                                .frame(width: 24, height: 22)
                            Text("Perfil")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                        }
                    }
                    .foregroundColor(navManager.selectedSection == .perfil ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
    }
}
