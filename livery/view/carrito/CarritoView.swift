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
                            .frame(height: UIScreen.main.bounds.height * 0.35)
                        
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.blanco)
        .task {
            await carritoViewModel.cargarEstadoInicial(
                perfilUsuarioState: perfilUsuarioState,
                ciudadSeleccionada: perfilUsuarioState.ciudadSeleccionada,
                usuarioDireccion: perfilUsuarioState.obtenerUsuarioDireccion()
            )
        }
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
        let tieneAlcohol = carritoViewModel.itemsProductos.contains { $0.contieneAlcohol == true }
            || carritoViewModel.itemsPromociones.contains { $0.contieneAlcohol == true }

        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 8) {

                if tieneAlcohol {
                    AdvertenciaProductosConAlcohol()
                }

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
        VStack(spacing: 0) {
            if itemProducto.disponibleParaDelivery == false {
                Text("No disponible para delivery")
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.rojoError)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 4)
            }

            HStack(alignment: .top, spacing: 12) {
            AsyncImage(url: URL(string: API.baseURL + "/" + itemProducto.imagenProductoURL)) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.grisSurface
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ItemProductoDescripcion(
                itemProducto: itemProducto,
                eliminable: true
            )
        }
        .padding(12)
        .background(Color.grisSurface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                    .inset(by: 1)
                    .stroke(
                        itemProducto.esPremio ? Color.oroPremio : .clear,
                        lineWidth: 2
                    )
        )
        }
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
            .scrollContentBackground(.hidden)
            .background(Color.blanco)
            .tint(.verdePrincipal)
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            .frame(minHeight: 40, maxHeight: 40)
            .padding(4)
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

    var hayNoDisponiblesParaDelivery: Bool {
        carritoViewModel.itemsProductos.contains { $0.disponibleParaDelivery == false }
    }

    var opciones: [TipoEntrega] {
        var result: [TipoEntrega] = []

        if !hayNoDisponiblesParaDelivery && carritoViewModel.comercio?.envios.envioPropio == true {
            result.append(.envioPropio)
        }
        if !hayNoDisponiblesParaDelivery && carritoViewModel.enviosLiveryActivo {
            result.append(.envioLivery)
        }
        result.append(.retiroEnComercio)

        return result
    }

    var body: some View {
        VStack(spacing: 8) {

            // MARK: Segmented buttons
            HStack(spacing: 0) {
                ForEach(opciones.indices, id: \.self) { index in
                    let tipo = opciones[index]

                    TipoEntregaButton(
                        tipo: tipo,
                        seleccionado: carritoViewModel.tipoEntregaSeleccionada == tipo,
                        isFirst: index == 0,
                        isLast: index == opciones.count - 1
                    ) {
                        carritoViewModel.onTipoEntregaChange(
                            perfilUsuarioState: perfilUsuarioState,
                            tipoEntrega: tipo,
                            usuarioDireccion: perfilUsuarioState.obtenerUsuarioDireccion()
                        )
                    }
                }
            }
            .padding(.horizontal, 16)

            // MARK: Aclaración
            Text(carritoViewModel.tipoEntregaSeleccionada.aclaracion)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.grisSecundario)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .lineLimit(1)
                .frame(minHeight: 26)

            // MARK: Advertencia no disponible para delivery
            if hayNoDisponiblesParaDelivery {
                Text("Contiene uno o más productos no disponibles para delivery")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.rojoError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineLimit(2)
            }
        }
        .onChange(of: opciones) { _, nuevasOpciones in
            if !nuevasOpciones.contains(carritoViewModel.tipoEntregaSeleccionada) {
                carritoViewModel.onTipoEntregaChange(
                    perfilUsuarioState: perfilUsuarioState,
                    tipoEntrega: .retiroEnComercio,
                    usuarioDireccion: perfilUsuarioState.obtenerUsuarioDireccion()
                )
            }
        }
    }
}

struct TipoEntregaButton: View {
    let tipo: TipoEntrega
    let seleccionado: Bool
    let isFirst: Bool
    let isLast: Bool
    let action: () -> Void

    var shape: RoundedCorners {
        RoundedCorners(
            radius: 16,
            corners: [
                isFirst ? .topLeft : [],
                isFirst ? .bottomLeft : [],
                isLast ? .topRight : [],
                isLast ? .bottomRight : []
            ]
        )
    }

    var body: some View {
        Button(action: action) {
            Text(tipo.descripcion)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(seleccionado ? .verdePrincipal : .negro)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(seleccionado ? Color.grisSurface : Color.blanco)
        }
        .clipShape(shape)
        .overlay(
            shape.stroke(Color.grisSecundario, lineWidth: 2)
        )
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
            
            if (carritoViewModel.tipoEntregaSeleccionada != TipoEntrega.retiroEnComercio) {
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
    
    @State private var mostrarBottomSheetPago = false
    @State private var mostrarAlerta = false
    @State private var tituloError = ""
    @State private var textoError = ""
    
    var body: some View {
        Button {
            Task {
                await procesarConfirmacion()
            }
        } label: {
            Text("Ir a Pagar")
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
        .sheet(isPresented: $mostrarBottomSheetPago) {
            BottomSheetPagoCarrito(
                tarifaServicio: tarifaServicio
            ) {
                Task {
                    await confirmarPedido()
                }
            }
            .presentationDetents([.fraction(0.95)])
            .presentationDragIndicator(.hidden)
        }
    }

    private var tarifaServicio: Double {
        carritoViewModel.aplicaTarifaServicio
        ? (perfilUsuarioState.configuracion?.tarifaServicio ?? StringUtils.tarifaServicioDefault)
        : 0.0
    }
    
    func procesarConfirmacion() async {
        guard let usuario = perfilUsuarioState.usuario,
              let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else { return }

        let validacionDisponibilidad = await carritoViewModel.validacionDisponibilidad(
            perfilUsuarioState: perfilUsuarioState,
            email: usuario.email
        )

        if !validacionDisponibilidad.valor {
            tituloError = StringUtils.tituloAppNoDisponible
            textoError = validacionDisponibilidad.mensaje ?? ""
            mostrarAlerta = true
            return
        }
        
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
            mostrarBottomSheetPago = true
        }
    }

    private func confirmarPedido() async {
        guard let usuario = perfilUsuarioState.usuario,
              let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else { return }

        await carritoViewModel.crearPedido(
            perfilUsuarioState: perfilUsuarioState,
            email: usuario.email,
            nombreUsuario: usuario.obtenerNombreCompleto(),
            direccion: direccion,
            tarifaServicio: tarifaServicio
        )

        carritoViewModel.onPedidoConfirmado()
        carritoViewModel.limpiarComprobante()
        mostrarBottomSheetPago = false
        navManager.select(.pedidos)
    }
}

struct BottomSheetPagoCarrito: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var carritoViewModel: CarritoViewModel

    let tarifaServicio: Double
    let onConfirmarPedido: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()

                        Button(action: { dismiss() }) {
                            Image("icono_cerrar")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(.negro)
                                .background(Color.blanco)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.negro, lineWidth: 2))
                        }
                    }
                    .padding(.horizontal, 8)

                    MontoAPagarView(
                        subtotal: obtenerSubtotal(
                            tipoEntrega: carritoViewModel.tipoEntregaSeleccionada,
                            precioTotal: carritoViewModel.precioTotal,
                            tarifaServicio: tarifaServicio
                        ),
                        tipoEntrega: carritoViewModel.tipoEntregaSeleccionada
                    )

                    Spacer().frame(height: 8)

                    SeccionDesplegable(
                        titulo: "Datos Bancarios",
                        expandidoInicialmente: false,
                        backgroundColor: .grisSurface,
                        contenido: {
                            DatosBancariosPagoView(
                                datosBancarios: carritoViewModel.comercio?.datosBancarios
                            )
                        }
                    )

                    Spacer().frame(height: 8)

                    SeccionDesplegable(
                        titulo: "Comprobante",
                        expandidoInicialmente: true,
                        backgroundColor: .grisSurface,
                        contenido: {
                            ComprobantePagoView(
                                estaCargando: carritoViewModel.cargandoComprobante,
                                comprobanteEnMemoria: carritoViewModel.comprobanteSeleccionado?.contenido,
                                urlComprobante: nil,
                                onCargarComprobante: { comprobante in
                                    carritoViewModel.cargarComprobante(comprobante: comprobante)
                                }
                            )
                        }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.grisSurface)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }

            Spacer().frame(height: 12)

            Button(action: {
                onConfirmarPedido()
                dismiss()
            }) {
                Text("Confirmar Pedido")
                    .font(.custom("Barlow", size: 16))
                    .bold()
                    .foregroundColor(carritoViewModel.comprobanteSeleccionado != nil ? .blanco : .grisSecundario)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(carritoViewModel.comprobanteSeleccionado != nil ? Color.verdePrincipal : .grisSurface)
                    .cornerRadius(24)
            }
            .disabled(carritoViewModel.comprobanteSeleccionado == nil)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
    }
}
