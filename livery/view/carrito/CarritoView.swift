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
        if !hayNoDisponiblesParaDelivery && carritoViewModel.enviosLiveryActivo {
            result.append(.envioLivery)
        }
        result.append(.retiroEnComercio)

        return result
    }

    var body: some View {
        VStack(spacing: 8) {

            // MARK: Mensaje envíos Livery
            if let mensaje = perfilUsuarioState.configuracion?.mensajeEnviosLivery, !mensaje.isEmpty,
               !opciones.contains(.envioLivery) {
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
        let tarifaServicio = carritoViewModel.aplicaTarifaServicio ?
        (perfilUsuarioState.configuracion?.tarifaServicio ?? StringUtils.tarifaServicioDefault) : 0.0

        let esLivery = carritoViewModel.tipoEntregaSeleccionada == .envioLivery
        let subtotal = esLivery
            ? carritoViewModel.precioTotal
            : carritoViewModel.precioTotal + tarifaServicio
        
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

            // En Envío Livery la tarifa se suma al envío, no se muestra acá
            // En Retiro en Comercio no aplica tarifa de servicio
            if !esLivery && carritoViewModel.tipoEntregaSeleccionada != .retiroEnComercio {
                HStack {
                    Text("Impuesto de Aplicación")
                    Spacer()
                    Text(DoubleUtils.formatearPrecio(valor: tarifaServicio))
                }
                .font(.custom("Barlow", size: 16))
                .foregroundColor(.negro)
            }
            
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
    @State private var mostrarAlerta = false
    @State private var tituloError = ""
    @State private var textoError = ""
    @State private var mostrarAvisoEnvio = false
    @State private var mostrarAvisoRetiro = false
    
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
        .alert("IMPORTANTE", isPresented: $mostrarAvisoEnvio) {
            Button("Aceptar") { mostrarBottomSheetPago = true }
        } message: {
            Text("Recordar que el **envío** se debe abonar **siempre directamente al repartidor**, ya sea que abones por transferencia o en efectivo.")
        }
        .alert("IMPORTANTE - RETIRO EN COMERCIO", isPresented: $mostrarAvisoRetiro) {
            Button("Aceptar") { mostrarBottomSheetPago = true }
        } message: {
            Text("Esta opción significa que **debés pasar a buscar tu pedido por el comercio**, ya que no hay opciones de envío disponibles.")
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
        } else if carritoViewModel.tipoEntregaSeleccionada == .envioPropio || carritoViewModel.tipoEntregaSeleccionada == .envioLivery {
            mostrarAvisoEnvio = true
        } else {
            mostrarAvisoRetiro = true
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
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    let tarifaServicio: Double
    let onConfirmarPedido: () -> Void

    @State private var tabSeleccionado: Int = 0

    private var limitePagoEfectivo: Double {
        perfilUsuarioState.configuracion?.limitePagoEfectivo ?? 0.0
    }

    private var superaLimiteEfectivo: Bool {
        guard limitePagoEfectivo > 0 else { return false }
        let descuento = carritoViewModel.calcularMontoDescuentoEfectivo()
        let base = carritoViewModel.precioTotal - descuento
        let total = carritoViewModel.tipoEntregaSeleccionada == .envioLivery
            ? base
            : base + tarifaServicio
        return total > limitePagoEfectivo
    }

    private var confirmarHabilitado: Bool {
        switch tabSeleccionado {
        case 0:
            return carritoViewModel.comprobanteSeleccionado != nil
        case 1:
            return !superaLimiteEfectivo && carritoViewModel.estadoValidacionEfectivo == .validado
        default:
            return false
        }
    }

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
                            tarifaServicio: tarifaServicio,
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
                        SeccionEfectivo(superaLimite: superaLimiteEfectivo, limitePagoEfectivo: limitePagoEfectivo)
                    default:
                        EmptyView()
                    }
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
                    .foregroundColor(confirmarHabilitado ? .blanco : .grisSecundario)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(confirmarHabilitado ? Color.verdePrincipal : .grisSurface)
                    .cornerRadius(24)
            }
            .disabled(!confirmarHabilitado)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onChange(of: tabSeleccionado) { _, newTab in
            carritoViewModel.onPagoTransferenciaChange(newTab == 0)
        }
        .onChange(of: carritoViewModel.urlWhatsapp) { _, nuevaUrl in
            guard let nuevaUrl,
                  let url = URL(string: nuevaUrl) else { return }
            openURL(url)
            carritoViewModel.limpiarUrlWhatsapp()
        }
        .alert("Error al validar", isPresented: $carritoViewModel.mostrarErrorValidacion) {
            Button("Aceptar", role: .cancel) { carritoViewModel.descartarErrorValidacion() }
        } message: {
            Text("Hubo un error al generar el código de validación. Por favor intentá nuevamente.")
        }
    }
}

// MARK: – Sección Efectivo
private struct SeccionEfectivo: View {
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    let superaLimite: Bool
    let limitePagoEfectivo: Double

    var body: some View {
        VStack(spacing: 12) {
            if superaLimite {
                Text("El límite máximo para pago en efectivo es de \(DoubleUtils.formatearPrecio(valor: limitePagoEfectivo)). Utilizá la opción de transferencia para realizar tu pedido.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.rojoError)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            } else {
                Text("Necesitamos validar tu número de WhatsApp para poder abonar en efectivo.")
                    .font(.custom("Barlow", size: 13))
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                switch carritoViewModel.estadoValidacionEfectivo {
                case .validado:
                    Text("✓ Número de WhatsApp validado")
                        .font(.custom("Barlow", size: 15))
                        .bold()
                        .foregroundColor(.verdePrincipal)
                        .multilineTextAlignment(.center)
                case .esperando:
                    if !carritoViewModel.codigoEfectivo.isEmpty {
                        Text("Tu código: \(carritoViewModel.codigoEfectivo)")
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .foregroundColor(.negro)
                    }
                    Text("Esperando validación...")
                        .font(.custom("Barlow", size: 13))
                        .foregroundColor(.grisSecundario)
                        .multilineTextAlignment(.center)
                    ProgressView()
                        .tint(.verdePrincipal)
                default:
                    let cargando = carritoViewModel.estadoValidacionEfectivo == .cargandoCodigo
                    Button(action: {
                        carritoViewModel.generarCodigoEfectivo(perfilUsuarioState: perfilUsuarioState)
                    }) {
                        Group {
                            if cargando {
                                ProgressView()
                                    .tint(.blanco)
                                    .frame(width: 22, height: 22)
                            } else {
                                Text("Validar WhatsApp")
                                    .font(.custom("Barlow", size: 15))
                                    .bold()
                                    .foregroundColor(.blanco)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.verdePrincipal)
                        .cornerRadius(24)
                        .padding(.horizontal, 40)
                    }
                    .disabled(cargando)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
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
