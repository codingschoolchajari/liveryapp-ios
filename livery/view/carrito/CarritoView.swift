//
//  CarritoView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI

struct CarritoView: View {
    @EnvironmentObject var navManager: NavigationManager
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            Group {
                if  ( perfilUsuarioState.ciudadSeleccionada != nil
                      && perfilUsuarioState.ciudadSeleccionada == StringUtils.sinCobertura
                    ) || (
                        perfilUsuarioState.usuario != nil
                        && perfilUsuarioState.usuario!.direcciones?.isEmpty ?? true
                    )
                {
                    DireccionFueraDeCobertura()
                } else if !carritoViewModel.itemsProductos.isEmpty || !carritoViewModel.itemsPromociones.isEmpty {
                    
                    VStack(spacing: 8) {
                        
                        TituloComercio(comercio: carritoViewModel.comercio!)
                            .onTapGesture {
                                navManager.carritoPath.append(NavigationManager.CarritoDestination.comercio(idComercio: carritoViewModel.comercio!.idInterno))
                            }
                        
                        ItemsPedidoView()
                            .frame(height: UIScreen.main.bounds.height * 0.4)
                        
                        // Notas
                        NotasView()
                            .padding(.horizontal, 16)
                        
                        // Tipo de Entrega
                        TipoEntregaView()
                        
                        // Resumen de costos
                        ResumenView()
                            .padding(.horizontal, 16)
                        
                    }
                    
                    Spacer()
                    
                    // Botón de confirmación al final
                    ConfirmacionView()
                        .padding(.horizontal, 60)
                        .padding(.bottom, 10)
                        
                } else {
                    CarritoVacioView()
                }
            }
        }
        .background(.blanco)
    }
}

struct CarritoVacioView: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 100)
            Image("personaje")
                .resizable()
                .scaledToFit()
                .frame(width: 300)
            
            Spacer().frame(height: 16)
            
            Text("No hay productos agregados al carrito")
                .font(.custom("Barlow", size: 18))
                .bold()
                .foregroundColor(.negro)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ItemsPedidoView: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {
                
                // Sección Promociones
                ForEach(carritoViewModel.itemsPromociones) { item in
                    ItemPromocionRow(itemPromocion: item)
                }
                
                // Sección Productos
                ForEach(carritoViewModel.itemsProductos) { item in
                    ItemProductoRow(itemProducto: item)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

struct ItemPromocionRow: View {
    let itemPromocion: ItemPromocion
    
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: API.baseURL + "/" + itemPromocion.imagenPromocionURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.grisSurface
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ItemPromocionDescripcion(
                carritoViewModel: carritoViewModel,
                itemPromocion: itemPromocion,
                eliminable: true
            )
        }
        .padding(12)
        .background(Color.grisSurface)
        .cornerRadius(12)
    }
}

struct ItemProductoRow: View {
    let itemProducto: ItemProducto
    
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: API.baseURL + "/" + itemProducto.imagenProductoURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.grisSurface
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ItemProductoDescripcion(
                carritoViewModel: carritoViewModel,
                itemProducto: itemProducto,
                eliminable: true
            )
        }
        .padding(12)
        .background(Color.grisSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(itemProducto.esPremio ? Color.oroPremio : Color.clear, lineWidth: 3)
        )
    }
}

struct NotasView: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    var body: some View {
        
        Text("Notas para el Comercio")
            .foregroundColor(.grisSecundario)
            .font(.custom("Barlow", size: 14))
            .bold()
            .frame(maxWidth: .infinity, alignment: .leading)
        
        TextEditor(text: $carritoViewModel.notas)
            .tint(.verdePrincipal)
            .font(.custom("Barlow", size: 16))
            .bold()
            .frame(minHeight: 50, maxHeight: 50)
            .padding(4)
            .background(Color.blanco)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            .onChange(of: carritoViewModel.notas) { oldValue, newValue in
                if newValue.count > 100 {
                    carritoViewModel.notas = String(newValue.prefix(100))
                }
            }
    }
}

struct TipoEntregaView: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var body: some View {
        HStack(spacing: 0) {
            // Botón Envío
            opcionBoton(
                titulo: "Envío a Domicilio",
                esSeleccionado: !carritoViewModel.retiroEnComercio,
                radius: .init(topLeading: 20, bottomLeading: 20, bottomTrailing: 0, topTrailing: 0)
            ) {
                carritoViewModel.retiroEnComercio = false
            }
            
            // Botón Retiro
            opcionBoton(
                titulo: "Retiro en Comercio",
                esSeleccionado: carritoViewModel.retiroEnComercio,
                radius: .init(topLeading: 0, bottomLeading: 0, bottomTrailing: 20, topTrailing: 20)
            ) {
                carritoViewModel.retiroEnComercio = true
            }
        }
        .padding(.horizontal, 40)
        .onChange(of: carritoViewModel.retiroEnComercio) { _, newValue in
            carritoViewModel.onRetiroEnComercioChange(
                perfilUsuarioState: perfilUsuarioState,
                valor: newValue,
                usuarioDireccion: perfilUsuarioState.obtenerUsuarioDireccion()
            )
        }
    }
}

struct ResumenView: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var body: some View {
        let tarifaServicio = carritoViewModel.aplicaTarifaServicio ?
        (perfilUsuarioState.configuracion?.tarifaServicio ?? StringUtils.tarifaServicioDefault) : 0.0
        
        let subtotal = carritoViewModel.precioTotal + tarifaServicio
        
        VStack(alignment: .leading, spacing: 2) {
            Text("Resumen")
                .font(.custom("Barlow", size: 18))
                .bold()
                .foregroundColor(.negro)
            
            HStack {
                Text("Productos")
                Spacer()
                Text(DoubleUtils.formatearPrecio(valor: carritoViewModel.precioTotal))
            }
            .font(.custom("Barlow", size: 16))
            .foregroundColor(.negro)
            
            HStack {
                Text("Tarifa de Servicio")
                Spacer()
                Text(DoubleUtils.formatearPrecio(valor: tarifaServicio))
            }
            .font(.custom("Barlow", size: 16))
            .foregroundColor(.negro)
            
            HStack {
                Text("Subtotal")
                Spacer()
                Text(DoubleUtils.formatearPrecio(valor: subtotal))
            }
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            
            if !carritoViewModel.retiroEnComercio {
                Divider().padding(.vertical, 4)
                
                HStack {
                    Text("Dirección")
                    Spacer()
                    Text(perfilUsuarioState.obtenerDireccionSeleccionada())
                        .fontWeight(.bold)
                        .lineLimit(1)
                }
                .font(.custom("Barlow", size: 16))
                .foregroundColor(.negro)
                
                HStack {
                    Text("Envío")
                    Spacer()
                    if carritoViewModel.envio > 0 {
                        Text(DoubleUtils.formatearPrecio(valor: carritoViewModel.envio))
                            .fontWeight(.bold)
                    }
                }
                .font(.custom("Barlow", size: 16))
                .foregroundColor(.negro)
            }
        }
    }
}

struct ConfirmacionView: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var navManager: NavigationManager
    
    @State private var mostrarAlerta = false
    @State private var tituloError = ""
    @State private var textoError = ""
    
    var body: some View {
        Button {
            Task {
                await procesarConfirmacion()
            }
        } label: {
            Text("Confirmar Pedido")
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.blanco)
                .frame(maxWidth: .infinity)
                .frame(height: 35)
                .background(perfilUsuarioState.obtenerUsuarioDireccion() != nil ? Color.verdePrincipal : Color.grisSecundario)
                .cornerRadius(24)
        }
        .disabled(perfilUsuarioState.obtenerUsuarioDireccion() == nil)
        .alert(tituloError, isPresented: $mostrarAlerta) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(textoError)
        }
    }
    
    func procesarConfirmacion() async {
        guard let usuario = perfilUsuarioState.usuario,
              let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else { return }
        
        if await !carritoViewModel.validacionComercioAbierto(
            perfilUsuarioState: perfilUsuarioState
        ) {
            tituloError = StringUtils.tituloComercioCerrado
            textoError = StringUtils.textoComercioCerrado
            mostrarAlerta = true
        } else if await carritoViewModel.validacionPendientes(
            perfilUsuarioState: perfilUsuarioState,
            email: usuario.email
        ) {
            tituloError = StringUtils.tituloPedidoPendiente
            textoError = StringUtils.textoPedidoPendiente
            mostrarAlerta = true
        } else {
            let tarifaServicio = carritoViewModel.aplicaTarifaServicio ?
            (perfilUsuarioState.configuracion?.tarifaServicio ?? StringUtils.tarifaServicioDefault) : 0.0
            
            // Lógica de creación exitosa
            await carritoViewModel.crearPedido(
                perfilUsuarioState: perfilUsuarioState,
                email: usuario.email,
                nombreUsuario: usuario.obtenerNombreCompleto(),
                direccion: direccion,
                tarifaServicio: tarifaServicio
            )
            carritoViewModel.onPedidoConfirmado()
            navManager.select(.pedidos) // Navegación en tu NavigationManager
        }
    }
}
