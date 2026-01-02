//
//  SeccionesView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct SeccionesView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
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
                    NavigationStack(path: $navManager.descuentosPath) {
                        DescuentosView(perfilUsuarioState: perfilUsuarioState)
                            .navigationDestination(for: NavigationManager.DescuentosDestination.self) { destination in
                                switch destination {
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
                case .carrito:
                    NavigationStack(path: $navManager.carritoPath) {
                        CarritoView()
                            .navigationDestination(for: NavigationManager.CarritoDestination.self) { destination in
                                switch destination {
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
                case .pedidos:
                    //NavigationStack(path: $navManager.pedidosPath) {
                        PedidosView(perfilUsuarioState: perfilUsuarioState)
                            
                    //}
                case .perfil:
                    NavigationStack(path: $navManager.perfilPath) {
                        PerfilView()
                            .navigationDestination(for: String.self) { view in
                                FavoritosView()
                                    .navigationBarBackButtonHidden(true)
                            }
                        
                            .navigationDestination(for: NavigationManager.PerfilDestination.self) { destination in
                                switch destination {
                                case .favoritos:
                                    FavoritosView()
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
                }
            }
            
            // Barra de navegación personalizada
            VStack(spacing: 0) {
                // Usamos GeometryReader para obtener el ancho total disponible
                GeometryReader { geometry in
                    let anchoItem = geometry.size.width / 5
                    
                    HStack(spacing: 0) {
                        // Botón Inicio
                        BotonNavPersonalizado(
                            titulo: "Inicio",
                            icono: "icono_home",
                            ancho: anchoItem,
                            altoIcono: 28,
                            anchoIcono: 28,
                            seccion: .home,
                            selectedSection: navManager.selectedSection,
                            badgeCount: 0
                        ) {
                            navManager.select(.home)
                        }
                        
                        // Botón Descuentos
                        BotonNavPersonalizado(
                            titulo: "Descuentos",
                            icono: "icono_descuentos",
                            ancho: anchoItem,
                            altoIcono: 28,
                            anchoIcono: 28,
                            seccion: .descuentos,
                            selectedSection: navManager.selectedSection,
                            badgeCount: 0
                        ) {
                            navManager.select(.descuentos)
                        }
                        
                        let totalItems = carritoViewModel.itemsProductos.count + carritoViewModel.itemsPromociones.count
                        
                        // Botón Carrito
                        BotonNavPersonalizado(
                            titulo: "Carrito",
                            icono: "icono_carrito",
                            ancho: anchoItem,
                            altoIcono: 28,
                            anchoIcono: 28,
                            seccion: .carrito,
                            selectedSection: navManager.selectedSection,
                            badgeCount: totalItems
                        ) {
                            navManager.select(.carrito)
                        }
                        
                        // Botón Pedidos
                        BotonNavPersonalizado(
                            titulo: "Pedidos",
                            icono: "icono_pedidos",
                            ancho: anchoItem,
                            altoIcono: 28,
                            anchoIcono: 28,
                            seccion: .pedidos,
                            selectedSection: navManager.selectedSection,
                            badgeCount: 0
                        ) {
                            navManager.select(.pedidos)
                        }
                        
                        // Botón Perfil
                        BotonNavPersonalizado(
                            titulo: "Perfil",
                            icono: "icono_perfil",
                            ancho: anchoItem,
                            altoIcono: 28,
                            anchoIcono: 32,
                            seccion: .perfil,
                            selectedSection: navManager.selectedSection,
                            badgeCount: 0
                        ) {
                            navManager.select(.perfil)
                        }
                    }
                }
                .frame(height: 40)
                .padding(.vertical, 10)
                .background(Color.blanco)
                .shadow(color: Color.negro.opacity(0.1), radius: 5, x: 0, y: -2)
            }
        }
    }
    
    struct BotonNavPersonalizado: View {
        let titulo: String
        let icono: String
        let ancho: CGFloat
        let altoIcono: CGFloat
        let anchoIcono: CGFloat
        let seccion: Section
        let selectedSection: Section
        let badgeCount: Int
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 4) {
                    Image(icono)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: anchoIcono, height: altoIcono)
                        .overlay(alignment: .topTrailing) {
                            if seccion == .carrito && badgeCount > 0 {
                                Text("\(badgeCount)")
                                    .font(.custom("Barlow", size: 12))
                                    .bold()
                                    .foregroundColor(.blanco)
                                    .frame(width: 22, height: 22)
                                    .background(Color.red)
                                    .clipShape(Circle())
                                    .offset(x: 10, y: -8)
                            }
                        }
                    
                    Text(titulo)
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .lineLimit(1)
                }
                .frame(width: ancho) // Aquí aplicamos el 1/5 del ancho
            }
            .foregroundColor(selectedSection == seccion ? Color.verdePrincipal : Color.grisSecundario)
        }
    }
}

