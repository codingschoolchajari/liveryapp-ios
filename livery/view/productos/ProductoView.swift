//
//  ProductoView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 26/12/2025.
//
import SwiftUI

struct ProductoTitulo: View {
    @ObservedObject var comercioViewModel: ComercioViewModel
    let producto: Producto
    let categoria: Categoria
    let onSelect: () -> Void
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    @State private var esFavorito: Bool = false
    
    var body: some View {
        let comercio = comercioViewModel.comercio
        let idFavorito = perfilUsuarioState.usuario?.obtenerIdProductoFavorito(
            idComercio: comercio?.idInterno,
            idProducto: producto.idInterno
        )
        
        ZStack {
            HStack(spacing: 8) {
                ProductoDescripcion(producto: producto)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .center) {
                    AsyncImage(url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? ""))) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color.grisSurface
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                if(comercio != nil){
                                    toggleFavorito(comercio: comercio!, idFavorito: idFavorito)
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 25, height: 25)
                                    Image(esFavorito ? "icono_favoritos_relleno" : "icono_favoritos_vacio")
                                        .resizable()
                                        .renderingMode(.template)
                                        .frame(width: 18, height: 18)
                                        .foregroundColor(esFavorito ? .verdePrincipal : .negro)
                                }
                            }
                            .padding(6)
                        }
                        Spacer()
                    }
                    
                    if let descuento = producto.descuento, descuento > 0 {
                        VStack {
                            Spacer()
                            RectanguloDescuento(producto: producto, redondeado: 12)
                                .padding(.bottom, 4)
                        }
                    }
                }
                .frame(width: 100, height: 100)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(Color.blanco)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                onSelect()
            }
        }
        .onAppear {
            esFavorito = (idFavorito != nil)
        }
    }
    
    private func toggleFavorito(comercio: Comercio, idFavorito: String?) {
        esFavorito.toggle()
        Task {
            if esFavorito {
                await perfilUsuarioState.agregarFavorito(
                    idFavorito: UUID().uuidString,
                    idComercio: comercio.idInterno,
                    nombreComercio: comercio.nombre,
                    logoComercioURL: comercio.logoURL,
                    idProducto: producto.idInterno,
                    idPromocion: nil,
                    nombre: producto.nombre,
                    imagenURL: producto.imagenURL
                )
            } else if let idFav = idFavorito {
                await perfilUsuarioState.eliminarFavorito(idFavorito: idFav)
            }
        }
    }
}

struct ProductoDescripcion: View {
    let producto: Producto
    
    // Valores por defecto
    var fontSizeNombre: CGFloat = 16
    var fontSizePrecio: CGFloat = 18
    var fontSizeDescripcion: CGFloat = 14
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(producto.nombre)
                .font(.custom("Barlow", size: fontSizeNombre))
                .bold()
                .foregroundColor(.negro)
            
            if !producto.descripcion.isEmpty {
                Text(producto.descripcion)
                    .font(.custom("Barlow", size: fontSizeDescripcion))
                    .foregroundColor(.negro)
                    .lineLimit(2)
                    .truncationMode(.tail)
            }
            
            if producto.precio > 0 {
                HStack(alignment: .center, spacing: 8) {
                    Text(DoubleUtils.formatearPrecio(valor: producto.precio))
                        .font(.custom("Barlow", size: fontSizePrecio))
                        .bold()
                        .foregroundColor(.negro)
                    
                    if let descuento = producto.descuento,
                       let precioSinDescuento = producto.precioSinDescuento,
                       descuento > 0 {
                        
                        Text(DoubleUtils.formatearPrecio(valor: precioSinDescuento))
                            .font(.custom("Barlow", size: fontSizePrecio))
                            .foregroundColor(.grisTerciario)
                            .strikethrough(true, color: .grisTerciario)
                    }
                }
            }
        }
    }
}

struct RectanguloDescuento: View {
    let producto: Producto
    var fontSizeDescuento: CGFloat = 14
    var redondeado: CGFloat = 8
    
    var body: some View {
        if let descuento = producto.descuento {
            Text("\(Int(descuento)) % OFF")
                .font(.custom("Barlow", size: fontSizeDescuento))
                .bold()
                .foregroundColor(.negro)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Color.amarilloDescuento
                        .cornerRadius(redondeado)
                )
        }
    }
}

struct BottomSheetSeleccionProducto: View {
    let producto: Producto
    let categoria: Categoria
    let comercio: Comercio
    let onClose: () -> Void
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    @StateObject private var itemProductoViewModel = ItemProductoViewModel()
    
    @State private var mostrarDialogoConflicto = false
    @State private var mensajeToast: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. Portada (Ocupa 3/4 del ancho de pantalla)
            PortadaProducto(producto: producto)
            
            // 2. Bloque Central (Descripción + Seleccionables) - NO Scrolleable externamente
            VStack(alignment: .leading, spacing: 0) {
                ProductoDescripcion(
                    producto: producto,
                    fontSizeNombre: 20,
                    fontSizePrecio: 22,
                    fontSizeDescripcion: 16
                )
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer().frame(height: 12)
                
                if let min = producto.cantidadMinimaSeleccionables, min > 0, categoria.seleccionables != nil {
                    Seleccionables(
                        categoria: categoria,
                        producto: producto,
                        seleccionadosUnitarios: itemProductoViewModel.seleccionadosUnitarios,
                        seleccionadosMultiples: itemProductoViewModel.seleccionadosMultiples,
                        onCambiarSeleccionadoUnitario: { id, valor in
                            itemProductoViewModel.cambiarSeleccionadoUnitario(
                                perfilUsuarioState: perfilUsuarioState,
                                id: id,
                                seleccionadoUnitario: valor
                            )
                        },
                        onCambiarSeleccionadoMultiple: { id, cant in
                            itemProductoViewModel.cambiarSeleccionadoMultiple(id: id, cantidad: cant)
                        }
                    )
                    Spacer()
                    let item = itemProductoViewModel.itemProducto
                    
                    CantidadUnidadesYPrecio(
                        cambioUnidadesHabilitado: false,
                        cantidad: itemProductoViewModel.cantidad,
                        precio: item?.precio,
                        onAumentarCantidad: { itemProductoViewModel.aumentarCantidad() },
                        onDisminuirCantidad: { itemProductoViewModel.disminuirCantidad() }
                    )
                    Spacer().frame(height: 4)
                    AgregarCarrito(
                        enabled: calcularSiEstaHabilitado(),
                        mostrarDialogoConflicto: $mostrarDialogoConflicto,
                        onConfirmar: {
                            agregarItemProducto(onClose: onClose)
                        },
                        onConfirmarConflicto: {
                            limpiarYAgregarItemProducto(onClose: onClose)
                        }
                    )
                } else {
                    let item = itemProductoViewModel.itemProducto
                    
                    Spacer()
                    CantidadUnidadesYPrecio(
                        cambioUnidadesHabilitado: producto.esPremio != true,
                        cantidad: itemProductoViewModel.cantidad,
                        precio: item?.precio,
                        onAumentarCantidad: { itemProductoViewModel.aumentarCantidad() },
                        onDisminuirCantidad: { itemProductoViewModel.disminuirCantidad() }
                    )
                    Spacer().frame(height: 4)
                    AgregarCarrito(
                        enabled: calcularSiEstaHabilitado(),
                        mostrarDialogoConflicto: $mostrarDialogoConflicto,
                        onConfirmar: { agregarItemProducto(onClose: onClose) },
                        onConfirmarConflicto: { limpiarYAgregarItemProducto(onClose: onClose) }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onAppear {
            itemProductoViewModel.inicializar(producto: producto, categoria: categoria, comercio: comercio)
        }
        .overlay(ToastView(mensaje: $mensajeToast))
    }
    
    // --- Lógica de Validación (Cálculo de 'enabled') ---
    
    private func calcularSiEstaHabilitado() -> Bool {
        guard let item = itemProductoViewModel.itemProducto else { return false }
        
        let precioValido = item.precio > 0 || item.esPremio
        
        // Si no hay seleccionables obligatorios, solo valida precio
        guard let min = producto.cantidadMinimaSeleccionables, min > 0 else {
            return precioValido
        }
        
        let totalUnitarios = itemProductoViewModel.seleccionadosUnitarios.values.count { $0 == true }
        let totalMultiples = itemProductoViewModel.seleccionadosMultiples.values.reduce(0, +)
        
        let seleccionValida = totalUnitarios >= min ||
                              totalMultiples == (producto.cantidadMaximaSeleccionables ?? 0)
        
        return precioValido && seleccionValida
    }
    
    // --- Métodos de Acción ---
    
    private func agregarItemProducto(
        onClose: () -> Void
    ) {
        if(itemProductoViewModel.itemProducto == nil) { return }
        
        let direccion = perfilUsuarioState.obtenerUsuarioDireccion()
        let ciudad = perfilUsuarioState.ciudadSeleccionada
        
        if direccion != nil && ciudad != nil && !ciudad!.isEmpty {
            if carritoViewModel.validacionComercio(comercio: comercio) {
                carritoViewModel.agregarItemProducto(
                    perfilUsuarioState: perfilUsuarioState,
                    itemProducto: itemProductoViewModel.itemProducto!,
                    direccion: direccion!
                )
                onClose()
            } else {
                mostrarDialogoConflicto = true
            }
        } else {
            mensajeToast = "Es necesario una dirección válida"
        }
    }
    
    private func limpiarYAgregarItemProducto(
        onClose: () -> Void
    ) {
        if(itemProductoViewModel.itemProducto == nil
           || perfilUsuarioState.obtenerUsuarioDireccion() == nil) { return }

        carritoViewModel.limpiarYAgregarItemProducto(
            perfilUsuarioState: perfilUsuarioState,
            itemProducto: itemProductoViewModel.itemProducto!,
            comercio: comercio,
            direccion: perfilUsuarioState.obtenerUsuarioDireccion()!
        )
        mostrarDialogoConflicto = false
        
        onClose()
    }
}

struct PortadaProducto: View {
    let producto: Producto
    
    var body: some View {
        let altoDeseado = UIScreen.main.bounds.height * (1/3)
        
        ZStack(alignment: .topTrailing) {
            AsyncImage(url: URL(string: API.baseURL + "/" + (producto.imagenURL ?? ""))) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
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
            
            if let descuento = producto.descuento, descuento > 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        RectanguloDescuento(
                            producto: producto,
                            fontSizeDescuento: 18,
                            redondeado: 18
                        )
                        .padding(12)
                    }
                }
            }
        }
        .frame(height: altoDeseado)
    }
}
