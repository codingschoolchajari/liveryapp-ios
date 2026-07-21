//
//  CarritoView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 18/12/2025.
//
import SwiftUI
import CoreLocation

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
                            .frame(height: UIScreen.main.bounds.height * 0.28)
                        
                        // Notas
                        NotasView()
                            .padding(.horizontal, 16)
                        
                        // Tipo de Entrega
                        TipoEntregaView()
                        
                        // Resumen de costos + botón de confirmación
                        ScrollView {
                            VStack(spacing: 8) {
                                ResumenView()
                                    .padding(.horizontal, 16)
                                
                                ConfirmacionView()
                                    .padding(.horizontal, 60)
                                    .padding(.bottom, 10)
                            }
                        }
                    }
                        
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
            RemoteImage(
                url: URL(string: API.baseURL + "/" + itemPromocion.imagenPromocionURL),
                fallbackURL: URL(string: API.baseURL + "/" + imagenPorDefectoURL(itemPromocion.imagenPromocionURL))
            )
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
                    .foregroundColor(.naranjaPrincipal)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
            }
            HStack(alignment: .top, spacing: 12) {
            RemoteImage(
                url: URL(string: API.baseURL + "/" + itemProducto.imagenProductoURL),
                fallbackURL: URL(string: API.baseURL + "/" + imagenPorDefectoURL(itemProducto.imagenProductoURL))
            )
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            ItemProductoDescripcion(
                itemProducto: itemProducto,
                eliminable: true
            )
        }
        .padding(12)
        }
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
        if !hayNoDisponiblesParaDelivery && carritoViewModel.enviosLiveryActivo && carritoViewModel.comercio?.envios.envioLivery == true {
            result.append(.envioLivery)
        }
        result.append(.retiroEnComercio)

        return result
    }

    var body: some View {
        VStack(spacing: 8) {

            // MARK: Mensaje envíos Livery
            if let mensaje = perfilUsuarioState.configuracion?.mensajeEnviosLivery, !mensaje.isEmpty,
               !opciones.contains(.envioLivery),
               carritoViewModel.comercio?.envios.envioLivery == true {
                Text(mensaje)
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.naranjaPrincipal)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

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
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.naranjaPrincipal)
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
                .contentShape(Rectangle())
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
        let tarifaServicio = carritoViewModel.aplicaTarifaServicio
            ? carritoViewModel.tarifaServicioCalculada
            : 0.0

        let esLivery = carritoViewModel.tipoEntregaSeleccionada == .envioLivery
        let subtotal = carritoViewModel.precioTotal
        
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
                Text("Subtotal")
                Spacer()
                Text(DoubleUtils.formatearPrecio(valor: subtotal))
            }
            .font(.custom("Barlow", size: 16))
            .bold()
            .foregroundColor(.negro)
            
            if carritoViewModel.tipoEntregaSeleccionada != .retiroEnComercio {
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
                    if carritoViewModel.comercio?.envios.envioGratisParaCliente == true {
                        Text("Gratis")
                            .fontWeight(.bold)
                            .foregroundColor(.verdePrincipal)
                    } else if carritoViewModel.envio > 0 {
                        // En Envío Livery la tarifa se suma al costo del envío
                        let envioMostrado = esLivery
                            ? carritoViewModel.envio + tarifaServicio
                            : carritoViewModel.envio
                        Text(DoubleUtils.formatearPrecio(valor: envioMostrado))
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
    @State private var mostrarBottomSheetConfirmarDireccionYPago = false
    @State private var mostrarAlerta = false
    @State private var tituloError = ""
    @State private var textoError = ""
    @State private var mostrarAvisoRetiro = false

    private var sesionValidaParaPagar: Bool {
        guard !perfilUsuarioState.esInvitado else { return false }
        let email = perfilUsuarioState.usuario?.email.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !email.isEmpty
    }

    private var puedeIrAPagar: Bool {
        sesionValidaParaPagar && perfilUsuarioState.obtenerUsuarioDireccion() != nil
    }
    
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
                .background(puedeIrAPagar ? Color.verdePrincipal : Color.grisSecundario)
                .cornerRadius(24)
        }
        .disabled(!puedeIrAPagar)
        .alert(tituloError, isPresented: $mostrarAlerta) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(textoError)
        }
        .alert("IMPORTANTE - RETIRO EN COMERCIO", isPresented: $mostrarAvisoRetiro) {
            Button("Aceptar") { mostrarBottomSheetPago = true }
        } message: {
            Text("Esta opción significa que **debés pasar a buscar tu pedido por el comercio**, ya que no hay opciones de envío disponibles.")
        }
        .sheet(isPresented: $mostrarBottomSheetConfirmarDireccionYPago) {
            BottomSheetConfirmarDireccionYPagoCarrito {
                Task {
                    await confirmarPedido()
                }
            }
            .presentationDetents([.fraction(0.95)])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $mostrarBottomSheetPago) {
            BottomSheetPagoCarrito {
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
        ? carritoViewModel.tarifaServicioCalculada
        : 0.0
    }
    
    func procesarConfirmacion() async {
        guard let usuario = perfilUsuarioState.usuario,
              let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else { return }

        guard sesionValidaParaPagar else {
            tituloError = "Inicio de sesión requerido"
            textoError = "Para confirmar el pedido, iniciá sesión con tu cuenta."
            mostrarAlerta = true
            return
        }

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
        } else if carritoViewModel.tipoEntregaSeleccionada == .envioPropio || carritoViewModel.tipoEntregaSeleccionada == .envioLivery {
            mostrarBottomSheetConfirmarDireccionYPago = true
        } else {
            mostrarAvisoRetiro = true
        }
    }

    private func confirmarPedido() async {
        guard let usuario = perfilUsuarioState.usuario,
              let direccion = perfilUsuarioState.obtenerUsuarioDireccion() else { return }

        guard sesionValidaParaPagar else {
            mostrarBottomSheetPago = false
            tituloError = "Inicio de sesión requerido"
            textoError = "Tu sesión no es válida para crear pedidos. Iniciá sesión nuevamente."
            mostrarAlerta = true
            return
        }

        await carritoViewModel.crearPedido(
            perfilUsuarioState: perfilUsuarioState,
            email: usuario.email,
            nombreUsuario: usuario.obtenerNombreCompleto(),
            direccion: direccion,
            tarifaServicio: tarifaServicio
        )

        carritoViewModel.onPedidoConfirmado()
        carritoViewModel.limpiarComprobante()
        mostrarBottomSheetConfirmarDireccionYPago = false
        mostrarBottomSheetPago = false
        navManager.select(.pedidos)
    }
}

struct BottomSheetConfirmarDireccionYPagoCarrito: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    let onConfirmarPedido: () -> Void

    @State private var mostrarPasoPago = false
    @State private var mostrarNuevaDireccion = false
    @State private var coordenadasMapa: CLLocationCoordinate2D? = nil

    private var direcciones: [UsuarioDireccion] {
        perfilUsuarioState.usuario?.direcciones ?? []
    }

    private var tarifaServicio: Double {
        carritoViewModel.aplicaTarifaServicio
        ? carritoViewModel.tarifaServicioCalculada
        : 0.0
    }

    private var textoCostoEnvio: String {
        if carritoViewModel.comercio?.envios.envioGratisParaCliente == true {
            return "Gratis"
        }
        if carritoViewModel.envio > 0 {
            if carritoViewModel.tipoEntregaSeleccionada == .envioLivery {
                return DoubleUtils.formatearPrecio(valor: carritoViewModel.envio + tarifaServicio)
            }
            return DoubleUtils.formatearPrecio(valor: carritoViewModel.envio)
        }
        return ""
    }

    var body: some View {
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
            .padding(.horizontal, 16)
            .padding(.top, 12)

            if mostrarPasoPago {
                BottomSheetPagoCarrito(
                    onConfirmarPedido: onConfirmarPedido,
                    mostrarBotonCerrar: false,
                    contentHorizontalPadding: 0
                )
            } else {
                VStack(spacing: 0) {
                    Text("Confirmar Dirección")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(.negro)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 12)

                    ZStack {
                        GoogleMapView(coordenadas: $coordenadasMapa)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.grisSecundario, lineWidth: 1)
                            )

                        Image("icono_ubicacion_mapa")
                            .resizable()
                            .frame(width: 52, height: 52)
                    }
                    .frame(height: 170)

                    Spacer().frame(height: 12)

                    Text("Costo de envío: \(textoCostoEnvio)")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.negro)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    Spacer().frame(height: 8)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 6) {
                            ForEach(direcciones) { direccion in
                                let seleccionada = direccion.id == perfilUsuarioState.idDireccionSeleccionada

                                Button {
                                    Task {
                                        await perfilUsuarioState.actualizarDireccionSeleccionada(idDireccion: direccion.id)
                                        await perfilUsuarioState.obtenerCiudadSeleccionada()
                                        carritoViewModel.refrescarCostoEnvio(
                                            perfilUsuarioState: perfilUsuarioState,
                                            usuarioDireccion: direccion
                                        )
                                        if let ciudad = perfilUsuarioState.ciudadSeleccionada {
                                            await carritoViewModel.actualizarEnviosLiveryActivo(
                                                perfilUsuarioState: perfilUsuarioState,
                                                localidad: ciudad
                                            )
                                        }
                                        actualizarMapaSegunDireccionSeleccionada()
                                    }
                                } label: {
                                    HStack {
                                        Text(StringUtils.formatearDireccion(direccion.calle, direccion.numero, direccion.departamento))
                                            .font(.custom("Barlow", size: 14))
                                            .foregroundColor(.negro)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(seleccionada ? Color.verdePrincipal.opacity(0.1) : Color.grisSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(
                                                seleccionada ? Color.verdePrincipal : Color.grisSecundario.opacity(0.4),
                                                lineWidth: seleccionada ? 2 : 1
                                            )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }

                            Spacer().frame(height: 10)

                            Button {
                                mostrarNuevaDireccion = true
                            } label: {
                                Text("Nueva dirección")
                                    .font(.custom("Barlow", size: 14))
                                    .bold()
                                    .foregroundColor(.blanco)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 36)
                                    .background(Color.naranjaPrincipal)
                                    .cornerRadius(24)
                                    .padding(.horizontal, 100)
                            }
                        }
                    }

                    Spacer().frame(height: 12)
                    Divider()
                    Spacer().frame(height: 10)

                    Text("Recordar que el envío se debe abonar siempre directamente al repartidor, ya sea que abones por transferencia o en efectivo.")
                        .font(.custom("Barlow", size: 13))
                        .foregroundColor(.negro)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Spacer().frame(height: 12)

                    Button {
                        mostrarPasoPago = true
                    } label: {
                        Text("Continuar")
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(perfilUsuarioState.obtenerUsuarioDireccion() != nil ? .blanco : .grisSecundario)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(perfilUsuarioState.obtenerUsuarioDireccion() != nil ? Color.verdePrincipal : Color.grisSurface)
                            .cornerRadius(24)
                    }
                    .disabled(perfilUsuarioState.obtenerUsuarioDireccion() == nil)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onAppear {
            actualizarMapaSegunDireccionSeleccionada()
        }
        .onChange(of: perfilUsuarioState.idDireccionSeleccionada) { _, _ in
            actualizarMapaSegunDireccionSeleccionada()
        }
        .sheet(isPresented: $mostrarNuevaDireccion) {
            DireccionView()
                .presentationDetents([.large])
        }
    }

    private func actualizarMapaSegunDireccionSeleccionada() {
        guard let direccion = perfilUsuarioState.obtenerUsuarioDireccion(),
              direccion.coordenadas.coordinates.count >= 2 else {
            return
        }

        coordenadasMapa = CLLocationCoordinate2D(
            latitude: direccion.coordenadas.coordinates[0],
            longitude: direccion.coordenadas.coordinates[1]
        )
    }
}

struct BottomSheetPagoCarrito: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    let onConfirmarPedido: () -> Void
    var mostrarBotonCerrar: Bool = true
    var contentHorizontalPadding: CGFloat = 16

    @State private var tabSeleccionado: Int = 0

    private var numeroWhatsappSoporte: String {
        (perfilUsuarioState.configuracion?.numeroWhatsappSoporte ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var limitePagoEfectivo: Double {
        carritoViewModel.comercio?.limitePagoEfectivo ?? perfilUsuarioState.configuracion?.limitePagoEfectivo ?? 0.0
    }

    private var superaLimiteEfectivo: Bool {
        guard limitePagoEfectivo > 0 else { return false }
        let descuento = carritoViewModel.calcularMontoDescuentoEfectivo()
        let base = carritoViewModel.precioTotal - descuento
        return base > limitePagoEfectivo
    }

    private var confirmarHabilitado: Bool {
        switch tabSeleccionado {
        case 0:
            return carritoViewModel.comprobanteSeleccionado != nil
        case 1:
            return !superaLimiteEfectivo && (
                carritoViewModel.estadoValidacionUbicacion == .cubierto
                || carritoViewModel.estadoValidacionUbicacion == .clienteFrecuente
            )
        default:
            return false
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    if mostrarBotonCerrar {
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
                    }

                    MontoAPagarView(
                        subtotal: obtenerSubtotal(
                            tipoEntrega: carritoViewModel.tipoEntregaSeleccionada,
                            precioTotal: carritoViewModel.precioTotal,
                            totalDescuentos: carritoViewModel.calcularTotalDescuentosSeleccionPago()
                        ),
                        tipoEntrega: carritoViewModel.tipoEntregaSeleccionada,
                        envioGratisParaCliente: carritoViewModel.comercio?.envios.envioGratisParaCliente ?? false
                    )

                    Spacer().frame(height: 8)

                    SelectorMetodoPagoView(tabSeleccionado: $tabSeleccionado)

                    Spacer().frame(height: 8)

                    switch tabSeleccionado {
                    case 0:
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
                    case 1:
                        SeccionEfectivo(
                            superaLimite: superaLimiteEfectivo,
                            limitePagoEfectivo: limitePagoEfectivo,
                            onAbrirAjustesPermiso: abrirAjustesApp,
                            onAbrirAjustesGps: abrirAjustesGps
                        )
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.grisSurface)
                .cornerRadius(12)
                .padding(.horizontal, contentHorizontalPadding)
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
                    .foregroundColor(confirmarHabilitado ? .blanco : .grisSecundario)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(confirmarHabilitado ? Color.verdePrincipal : .grisSurface)
                    .cornerRadius(24)
            }
            .disabled(!confirmarHabilitado)
            .padding(.horizontal, max(contentHorizontalPadding, 16))
            .padding(.bottom, 16)

            if !numeroWhatsappSoporte.isEmpty {
                Button {
                    abrirWhatsAppSoporte()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.verdePrincipal)

                        Image("icono_whatsapp")
                            .resizable()
                            .scaledToFill()
                            .clipped()
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
                .padding(.trailing, 20)
                .padding(.bottom, 80)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onAppear {
            if tabSeleccionado == 1 {
                carritoViewModel.iniciarValidacionUbicacion(perfilUsuarioState: perfilUsuarioState)
            }
        }
        .onChange(of: tabSeleccionado) { _, newTab in
            carritoViewModel.onPagoTransferenciaChange(newTab == 0)
            if newTab == 1 {
                carritoViewModel.iniciarValidacionUbicacion(perfilUsuarioState: perfilUsuarioState)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            carritoViewModel.revalidarSiNecesario(perfilUsuarioState: perfilUsuarioState)
        }
    }

    private func abrirAjustesApp() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }

    private func abrirAjustesGps() {
        guard let url = URL(string: "App-Prefs:root=Privacy&path=LOCATION") else {
            abrirAjustesApp()
            return
        }
        openURL(url)
    }

    private func abrirWhatsAppSoporte() {
        let numero = numeroWhatsappSoporte.filter { $0.isNumber }
        guard !numero.isEmpty else { return }

        let email = perfilUsuarioState.usuario?.email ?? ""
        let mensaje = "Hola, necesito ayuda con mi pago\nMi usuario es: \(email)"
        guard let encoded = mensaje.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://wa.me/\(numero)?text=\(encoded)") else {
            return
        }

        openURL(url)
    }
}

// MARK: – Sección Efectivo
private struct SeccionEfectivo: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    let superaLimite: Bool
    let limitePagoEfectivo: Double
    let onAbrirAjustesPermiso: () -> Void
    let onAbrirAjustesGps: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if superaLimite {
                Text("El límite máximo para pago en efectivo es de \(DoubleUtils.formatearPrecio(valor: limitePagoEfectivo)), utilice la opción de pago por transferencia para realizar su pedido.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.rojoError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            } else {
                switch carritoViewModel.estadoValidacionUbicacion {
                case .clienteFrecuente:
                    Text("Cliente Frecuente")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.verdePrincipal)
                        .multilineTextAlignment(.center)
                case .cubierto:
                    Text("Verificación de Ubicación Exitosa")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.verdePrincipal)
                        .multilineTextAlignment(.center)
                case .obteniendoUbicacion:
                    Text("Obteniendo ubicación...")
                        .font(.custom("Barlow", size: 13))
                        .foregroundColor(.grisSecundario)
                        .multilineTextAlignment(.center)
                    ProgressView()
                        .tint(.verdePrincipal)
                case .verificandoCobertura:
                    Text("Verificando área de cobertura...")
                        .font(.custom("Barlow", size: 13))
                        .foregroundColor(.grisSecundario)
                        .multilineTextAlignment(.center)
                    ProgressView()
                        .tint(.verdePrincipal)
                case .solicitandoPermiso:
                    ProgressView()
                        .tint(.verdePrincipal)
                case .permisoDenegado:
                    Text("Se necesitan Permisos de Ubicación")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.rojoError)
                        .multilineTextAlignment(.center)
                    Button("Permitir Ubicación") {
                        onAbrirAjustesPermiso()
                    }
                    .font(.custom("Barlow", size: 15).bold())
                    .foregroundColor(.blanco)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.verdePrincipal)
                    .cornerRadius(24)
                    .padding(.horizontal, 40)
                case .gpsApagado:
                    Text("El GPS está apagado")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.rojoError)
                        .multilineTextAlignment(.center)
                    Button("Encender GPS") {
                        onAbrirAjustesGps()
                    }
                    .font(.custom("Barlow", size: 15).bold())
                    .foregroundColor(.blanco)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.verdePrincipal)
                    .cornerRadius(24)
                    .padding(.horizontal, 40)
                case .fueraDeCobertura:
                    Text("Verificación de Ubicación fallida\n Estás fuera del Área de Cobertura de la localidad del comercio")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.rojoError)
                        .multilineTextAlignment(.center)
                    botonRevalidar
                case .error:
                    Text("No se pudo obtener tu ubicación\nVerificá que el GPS esté activo e intentá nuevamente")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.rojoError)
                        .multilineTextAlignment(.center)
                    botonRevalidar
                case .idle:
                    ProgressView()
                        .tint(.verdePrincipal)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    private var botonRevalidar: some View {
        Button(action: {
            carritoViewModel.iniciarValidacionUbicacion(perfilUsuarioState: perfilUsuarioState)
        }) {
            Text("Validar ubicación")
                .font(.custom("Barlow", size: 15))
                .bold()
                .foregroundColor(.blanco)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Color.verdePrincipal)
                .cornerRadius(24)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: – Selector país celular
private struct CelularPaisSelector: View {
    struct PaisCelular: Identifiable {
        let id = UUID()
        let iso: String
        let codigo: String
    }
    private let paises: [PaisCelular] = [
        .init(iso: "ar", codigo: "+54"),
        .init(iso: "br", codigo: "+55"),
        .init(iso: "cl", codigo: "+56"),
        .init(iso: "uy", codigo: "+598"),
        .init(iso: "py", codigo: "+595")
    ]

    let pais: String
    let onPaisChange: (String) -> Void

    @State private var expanded = false

    var paisActual: PaisCelular {
        paises.first { $0.codigo == pais } ?? paises[0]
    }

    var body: some View {
        Menu {
            ForEach(paises) { p in
                Button(action: { onPaisChange(p.codigo) }) {
                    Text("\(p.codigo)")
                }
            }
        } label: {
            HStack(spacing: 4) {
                AsyncImage(url: URL(string: "https://flagcdn.com/80x60/\(paisActual.iso).png")) { phase in
                    if let img = phase.image {
                        img.resizable().scaledToFill()
                            .frame(width: 20, height: 15)
                            .clipShape(RoundedRectangle(cornerRadius: 2))
                    } else {
                        Color.grisSurface.frame(width: 20, height: 15)
                    }
                }
                Text(paisActual.codigo)
                    .font(.custom("Barlow", size: 13))
                    .bold()
                    .foregroundColor(.negro)
            }
            .frame(width: 78, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
        }
    }
}

private struct SelectorMetodoPagoView: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @Binding var tabSeleccionado: Int

    var body: some View {
        HStack(spacing: 0) {
            botonTab(titulo: "Transferencia", index: 0)
            botonTab(titulo: "Efectivo", index: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.grisSecundario, lineWidth: 1)
        )
    }

    private func botonTab(titulo: String, index: Int) -> some View {
        let seleccionado = tabSeleccionado == index
        return Button(action: { tabSeleccionado = index }) {
            Text(titulo)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(seleccionado ? .verdePrincipal : .negro)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(seleccionado ? Color.verdePrincipal.opacity(0.1) : Color.blanco)
                .contentShape(Rectangle())
        }
    }
}
