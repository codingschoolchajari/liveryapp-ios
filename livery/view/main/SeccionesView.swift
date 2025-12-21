//
//  SeccionesView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct SeccionesView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var selectedSection: Section
    
    enum Section {
        case home, descuentos, carrito, pedidos, perfil
    }
    
    init(selectedSection: Section = .home) {
        self._selectedSection = State(initialValue: selectedSection)
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
            
            // Renderizar la vista seleccionada
            switch selectedSection {
            case .home:
                HomeView(perfilUsuarioState: perfilUsuarioState)
                    .environmentObject(perfilUsuarioState)
            case .descuentos:
                DescuentosView()
            case .carrito:
                CarritoView()
            case .pedidos:
                PedidosView()
            case .perfil:
                PerfilView()
            }
            
            // Barra de navegación personalizada
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(
                        action: {selectedSection = .home }
                    ) {
                        VStack {
                            Image(systemName: "house.fill")
                                .resizable()
                                .frame(width: 28, height: 22)
                            Text("Inicio")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                        }
                    }
                    .foregroundColor(selectedSection == .home ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        selectedSection = .descuentos
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
                    .foregroundColor(selectedSection == .descuentos ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        selectedSection = .carrito
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
                    .foregroundColor(selectedSection == .carrito ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        selectedSection = .pedidos
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
                    .foregroundColor(selectedSection == .pedidos ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                    Button(action: {
                        selectedSection = .perfil
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
                    .foregroundColor(selectedSection == .perfil ? Color.verdePrincipal : Color.grisSecundario)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
        }
    }
}
