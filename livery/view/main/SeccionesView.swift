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
        VStack(spacing: 0) {
            // Usamos el path del navManager
            Group {
                switch navManager.selectedSection {
                case .home:
                    NavigationStack(path: $navManager.homePath) {
                        HomeView(perfilUsuarioState: perfilUsuarioState)
                            .navigationDestination(for: NavigationManager.HomeDestination.self) { destination in
                                switch destination {
                                case .direccion:
                                    DireccionView()
                                        .navigationBarBackButtonHidden(true)
                                    
                                case .comercio(let idComercio):
                                    ComercioView(
                                        comercioViewModel: ComercioViewModel(
                                            perfilUsuarioState: perfilUsuarioState,
                                            idComercio: idComercio
                                        )
                                    )
                                        .navigationBarBackButtonHidden(true)
                                }
                            }
                    }
                    .safeAreaInset(edge: .top) {
                        Color.verdePrincipal
                            .frame(height: 0)
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
                .background(Color.blanco)
                .shadow(color: Color.negro.opacity(0.1), radius: 5, x: 0, y: -2)
            }
        }
    }
}
