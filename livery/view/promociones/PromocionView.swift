//
//  PromocionView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct PromocionTitulo: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    let promocion: Promocion
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var mostrarBottomSheet = false
    @State private var esFavorito: Bool = false
    
    var body: some View {
        let comercio = comercioViewModel.comercio
        let idFavorito = perfilUsuarioState.usuario?.obtenerIdPromocionFavorita(
            idComercio: comercio?.idInterno,
            idPromocion: promocion.idInterno
        )
        
        ZStack {
            HStack(spacing: 8) {
                PromocionDescripcion(promocion: promocion)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .topTrailing) {
                    AsyncImage(url: URL(string: API.baseURL + "/" + promocion.imagenURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Color.grisSurface
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    // Botón de Favorito
                    Button(action: {
                        toggleFavorito(comercio: comercio, idFavorito: idFavorito)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 25, height: 25)
                            
                            Image(esFavorito ? "icono_favoritos_relleno" : "icono_favoritos_vacio")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(esFavorito ? .verdePrincipal : .negro)
                        }
                    }
                    .padding(6)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(.blanco)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.grisSecundario, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                mostrarBottomSheet = true
            }
        }
        .onAppear {
            esFavorito = (idFavorito != nil)
        }
        .sheet(isPresented: $mostrarBottomSheet) {
            if (comercio != nil) {
                BottomSheetSeleccionPromocion(promocion: promocion, comercio: comercio!)
            }
        }
    }
    
    // Lógica para agregar/eliminar favorito
    private func toggleFavorito(comercio: Comercio?, idFavorito: String?) {
        esFavorito.toggle()
        
        Task {
            if esFavorito, let com = comercio {
                /*
                perfilUsuarioState.agregarFavorito(
                    id: UUID().uuidString,
                    idComercio: com.idInterno,
                    nombreComercio: com.nombre,
                    logoComercio: com.logoURL,
                    idProducto: nil,
                    idPromocion: promocion.idInterno,
                    nombrePromocion: promocion.nombre,
                    imagenPromocion: promocion.imagenURL
                )
                 */
            } else if let idFav = idFavorito {
                //perfilUsuarioState.eliminarFavorito(id: idFav)
            }
        }
    }
}

struct PromocionDescripcion: View {
    let promocion: Promocion
    
    var fontSizeNombre: CGFloat = 16
    var fontSizePrecio: CGFloat = 18
    var fontSizeDescripcion: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(promocion.nombre)
                .font(.custom("Barlow", size: fontSizeNombre))
                .bold()
                .foregroundColor(.negro)

            if !promocion.descripcion.isEmpty {
                Text(promocion.descripcion)
                    .font(.custom("Barlow", size: fontSizeDescripcion))
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            Text(DoubleUtils.formatearPrecio(valor: promocion.precio))
                .font(.custom("Barlow", size: fontSizePrecio))
                .bold()
                .foregroundColor(.negro)
        }
    }
}

struct BottomSheetSeleccionPromocion: View {
    let promocion: Promocion
    let comercio: Comercio
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    //@EnvironmentObject var carritoViewModel: CarritoViewModel
    
    @StateObject private var itemPromocionViewModel = ItemPromocionViewModel()
    
    @State private var mostrarDialogoConflicto = false
    @State private var mensajeToast: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            PortadaPromocion(promocion: promocion)
            
            VStack(alignment: .leading, spacing: 12) {
                // Descripción de la promoción
                PromocionDescripcion(
                    promocion: promocion,
                    fontSizeNombre: 20,
                    fontSizePrecio: 22,
                    fontSizeDescripcion: 18
                )
                
                // Tabs/Lista de productos seleccionables
                ProductosSeleccionablesTabs(
                    comercio: comercio,
                    productosSeleccionables: itemPromocionViewModel.productosSeleccionablesState,
                    viewModel: itemPromocionViewModel
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            VStack(spacing: 4) {
                CantidadUnidadesYPrecio(
                    cambioUnidadesHabilitado: itemPromocionViewModel.productosSeleccionablesState.isEmpty,
                    cantidad: itemPromocionViewModel.cantidad,
                    precio: itemPromocionViewModel.itemPromocion?.precio,
                    onAumentarCantidad: { itemPromocionViewModel.aumentarCantidad() },
                    onDisminuirCantidad: { itemPromocionViewModel.disminuirCantidad() }
                )
                
                AgregarCarrito(
                    enabled: itemPromocionViewModel.cantidadSeleccionablesValida,
                    mostrarDialogoConflicto: $mostrarDialogoConflicto,
                    onConfirmar: {
                        ejecutarLogicaAgregar()
                    },
                    onConfirmarConflicto: {
                        confirmarLimpiezaYAgregar()
                    }
                )
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blanco)
        .onAppear {
            itemPromocionViewModel.inicializar(promocion: promocion, comercio: comercio)
        }
        .overlay(ToastView(mensaje: $mensajeToast))
    }
    
    // --- Lógica de negocio extraída ---
    
    private func ejecutarLogicaAgregar() {
        guard let item = itemPromocionViewModel.itemPromocion else { return }
        let direccion = perfilUsuarioState.obtenerUsuarioDireccion()
        let ciudad = perfilUsuarioState.ciudadSeleccionada
        
        if direccion != nil && ciudad != nil && !ciudad!.isEmpty {
            /*
            if carritoViewModel.validacionComercio(comercio: comercio) {
                carritoViewModel.agregarItemPromocion(item: item, direccion: direccion!)
                onDismiss(false)
            } else {
                mostrarDialogoConflicto = true
            }
             */
        } else {
            mensajeToast = "Es necesario una dirección válida"
        }
    }
    
    private func confirmarLimpiezaYAgregar() {
        guard let item = itemPromocionViewModel.itemPromocion,
              let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else { return }
        
        //carritoViewModel.limpiarYAgregarItemPromocion(item: item, comercio: comercio, direccion: direccion)
        mostrarDialogoConflicto = false
    }
}

struct PortadaPromocion: View {
    let promocion: Promocion
    
    var body: some View {
        let altoDeseado = UIScreen.main.bounds.width * (3/4)
        
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: API.baseURL + "/" + promocion.imagenURL)) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill) // Rellena el frame
                } else {
                    Color.blanco
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: altoDeseado)
            .clipped()
            .clipShape(
                RoundedCorners(radius: 32, corners: [.bottomLeft, .bottomRight])
            )
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct ProductosSeleccionablesTabs: View {
    let comercio: Comercio
    let productosSeleccionables: [String: ProductoSeleccionableState]
    @ObservedObject var viewModel: ItemPromocionViewModel
    
    @State private var selectedTabIndex = 0
    
    var body: some View {
        // Convertimos el diccionario a una lista para manejar índices en los Tabs
        let productosList = productosSeleccionables.sorted(by: { $0.key < $1.key })
        
        if !productosList.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                
                // 🔹 TABS: Fila de pestañas seleccionables
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(0..<productosList.count, id: \.self) { index in
                            let esSeleccionado = selectedTabIndex == index
                            let tabName = "Seleccionables" + (productosList.count > 1 ? " \(index + 1)" : "")
                            
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedTabIndex = index
                                }
                            }) {
                                Text(tabName)
                                    .font(.custom("Barlow", size: 16))
                                    .bold()
                                    .foregroundColor(esSeleccionado ? .verdePrincipal : .grisSecundario)
                            }
                        }
                    }
                }
                Spacer().frame(height: 8)
                
                let (idProducto, state) = productosList[selectedTabIndex]
                
                if let producto = ComerciosHelper.obtenerProducto(comercio: comercio, idProducto: idProducto),
                   let categoria = ComerciosHelper.obtenerCategoria(comercio: comercio, idProducto: idProducto) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(producto.nombre)
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(.negro)
                        
                        // Componente reutilizable que recibe estados y callbacks
                        Seleccionables(
                            categoria: categoria,
                            producto: producto,
                            seleccionadosUnitarios: state.seleccionadosUnitarios,
                            seleccionadosMultiples: state.seleccionadosMultiples,
                            onCambiarSeleccionadoUnitario: { id, valor in
                                viewModel.cambiarSeleccionadoUnitario(productoSeleccionableState: state, id: id, seleccionado: valor)
                            },
                            onCambiarSeleccionadoMultiple: { id, cantidad in
                                viewModel.cambiarSeleccionadoMultiple(productoState: state, id: id, cantidad: cantidad)
                            }
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
