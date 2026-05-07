import SwiftUI
import CoreLocation

private let PASO_DIRECCION_USUARIO = 0
private let PASO_COMERCIO = 1
private let PASO_DESCRIPCION = 2
private let PASO_PAGO = 3
private let PASO_RESUMEN = 4
private let TOTAL_PASOS = 5

struct NuevoRepartoView: View {
    let onRepartoCreado: () -> Void
    let onCerrar: () -> Void
    let onNuevaDireccion: () -> Void

    @StateObject private var viewModel: NuevoRepartoViewModel
    @State private var pasoActual: Int = PASO_DIRECCION_USUARIO

    init(
        perfilUsuarioState: PerfilUsuarioState,
        onRepartoCreado: @escaping () -> Void,
        onCerrar: @escaping () -> Void,
        onNuevaDireccion: @escaping () -> Void
    ) {
        self.onRepartoCreado = onRepartoCreado
        self.onCerrar = onCerrar
        self.onNuevaDireccion = onNuevaDireccion
        _viewModel = StateObject(wrappedValue: NuevoRepartoViewModel(perfilUsuarioState: perfilUsuarioState))
    }

    private var pasoValido: Bool {
        switch pasoActual {
        case PASO_DIRECCION_USUARIO:
            return viewModel.idDireccionUsuarioSeleccionada != nil
        case PASO_COMERCIO:
            return !viewModel.nombreComercio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !viewModel.calle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && !viewModel.numero.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case PASO_DESCRIPCION:
            return !viewModel.descripcionEnvio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case PASO_PAGO:
            switch viewModel.pagoTransferencia {
            case .some(true):
                return viewModel.comprobanteSeleccionado != nil
            case .some(false):
                let codigoCompleto = viewModel.codigoVerificacion.count == 6
                let codigoEnviado = viewModel.estadoEnvioCodigo == .enviado
                let tienePrecio = !viewModel.precioTotalProductos.isEmpty
                let noSuperaLimite = !viewModel.superaLimitePagoEfectivo
                return codigoCompleto && codigoEnviado && tienePrecio && noSuperaLimite
            default:
                return false
            }
        case PASO_RESUMEN:
            return !viewModel.creandoReparto
        default:
            return false
        }
    }

    private var tituloPaso: String {
        switch pasoActual {
        case PASO_DIRECCION_USUARIO: return "Elegí una de tus direcciones para recibir los productos."
        case PASO_COMERCIO: return "¿En qué comercio debemos buscar tus productos?"
        case PASO_DESCRIPCION: return "¿Qué productos debemos buscar?"
        case PASO_PAGO: return "¿Los productos ya se encuentran pagos mediante transferencia?"
        case PASO_RESUMEN: return "Resumen del mandado"
        default: return ""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Solicitar Nuevo Mandado")
                .font(.custom("Barlow", size: 18))
                .bold()
                .foregroundColor(.negro)
                .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            // Indicador de paso
            Text("Paso \(pasoActual + 1) de \(TOTAL_PASOS)")
                .font(.custom("Barlow", size: 12))
                .foregroundColor(.grisSecundario)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: 4)

            // Barra de progreso
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.grisSecundario.opacity(0.3))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.verdePrincipal)
                        .frame(width: geo.size.width * CGFloat(pasoActual + 1) / CGFloat(TOTAL_PASOS), height: 4)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 16)

            Spacer().frame(height: 12)

            // Título del paso
            Text(tituloPaso)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .center)

            Spacer().frame(height: 12)

            // Mapa fuera del scroll — solo visible en PASO_COMERCIO
            if pasoActual == PASO_COMERCIO {
                ZStack {
                    GoogleMapView(coordenadas: $viewModel.coordenadasDestino)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.verdePrincipal, lineWidth: 2)
                        )

                    Image("icono_ubicacion_mapa")
                        .resizable()
                        .frame(width: 50, height: 50)
                }
                .padding(.horizontal, 8)
                .frame(height: UIScreen.main.bounds.height * 0.28)

                Spacer().frame(height: 12)
            }

            // Contenido scrollable del paso
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    switch pasoActual {
                    case PASO_DIRECCION_USUARIO:
                        PasoDireccionUsuarioView(viewModel: viewModel, onNuevaDireccion: onNuevaDireccion)
                    case PASO_COMERCIO:
                        PasoComercioView(viewModel: viewModel)
                    case PASO_DESCRIPCION:
                        PasoDescripcionView(viewModel: viewModel)
                    case PASO_PAGO:
                        PasoPagoView(viewModel: viewModel)
                    case PASO_RESUMEN:
                        PasoResumenView(viewModel: viewModel)
                    default:
                        EmptyView()
                    }
                    Spacer().frame(height: 8)
                }
                .padding(.horizontal, 16)
            }

            // Botones de navegación
            HStack(spacing: 12) {
                Button {
                    if pasoActual > 0 { pasoActual -= 1 }
                } label: {
                    Text("Atrás")
                        .font(.custom("Barlow", size: 16))
                        .bold()
                        .foregroundColor(pasoActual > 0 ? .blanco : .grisSecundario)
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(pasoActual > 0 ? Color.gray : Color.grisSecundario.opacity(0.3))
                        .cornerRadius(24)
                }
                .disabled(pasoActual == 0)

                if pasoActual < PASO_RESUMEN {
                    Button {
                        Task {
                            if pasoActual == PASO_PAGO && viewModel.pagoTransferencia == false {
                                let valido = await viewModel.validarCodigoVerificacion()
                                if valido { pasoActual += 1 }
                            } else if pasoValido {
                                pasoActual += 1
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.validandoCodigo {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blanco))
                            } else {
                                Text("Siguiente")
                                    .font(.custom("Barlow", size: 16))
                                    .bold()
                                    .foregroundColor(pasoValido ? .blanco : .grisSecundario)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 45)
                        .background(pasoValido ? Color.naranjaIntentosRestantes : Color.grisSecundario.opacity(0.3))
                        .cornerRadius(24)
                    }
                    .disabled(!pasoValido || viewModel.validandoCodigo)
                } else {
                    Button {
                        Task { await viewModel.crearReparto() }
                    } label: {
                        Text(viewModel.creandoReparto ? "Confirmando..." : "Confirmar Mandado")
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(!viewModel.creandoReparto ? .blanco : .grisSecundario)
                            .frame(maxWidth: .infinity)
                            .frame(height: 45)
                            .background(!viewModel.creandoReparto ? Color.verdePrincipal : Color.grisSecundario.opacity(0.3))
                            .cornerRadius(24)
                    }
                    .disabled(viewModel.creandoReparto)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.blanco)
        .alert("Error enviando código", isPresented: $viewModel.mostrarErrorTelefono) {
            Button("Entendido") { viewModel.descartarErrorTelefono() }
        } message: {
            Text("Hubo un error al enviar el código de verificación a través de WhatsApp. Por favor verificá el código de país y el número.")
        }
        .alert("Código inválido", isPresented: $viewModel.mostrarErrorCodigo) {
            Button("Entendido") { viewModel.descartarErrorCodigo() }
        } message: {
            Text("El código de verificación ingresado no es válido. Revisá el código o solicitá uno nuevo.")
        }
        .onChange(of: viewModel.repartoCreado) { _, creado in
            if creado {
                onRepartoCreado()
                viewModel.resetearEstado()
            }
        }
    }
}

// PASO 1: DIRECCIÓN DEL USUARIO

private struct PasoDireccionUsuarioView: View {
    @ObservedObject var viewModel: NuevoRepartoViewModel
    let onNuevaDireccion: () -> Void
    @State private var expandirDirecciones = false

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.direccionesUsuario.isEmpty {
                Text("No tenés direcciones registradas. Agregá una nueva.")
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(.grisSecundario)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
            } else {
                let idSeleccionada = viewModel.idDireccionUsuarioSeleccionada
                let textoSeleccionado = viewModel.direccionesUsuario.first(where: { $0.id == idSeleccionada })
                    .map { StringUtils.formatearDireccion($0.calle, $0.numero, $0.departamento) }
                    ?? "Seleccionar dirección"

                // Selector colapsable
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        expandirDirecciones.toggle()
                    }
                } label: {
                    HStack {
                        Text(textoSeleccionado)
                            .font(.custom("Barlow", size: 15))
                            .foregroundColor(.negro)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: expandirDirecciones ? "chevron.up" : "chevron.down")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.negro)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.blanco)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                idSeleccionada != nil ? Color.verdePrincipal : Color.grisSecundario,
                                lineWidth: idSeleccionada != nil ? 2 : 1
                            )
                    )
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .overlay(alignment: .topLeading) {
                    if expandirDirecciones {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.direccionesUsuario.enumerated()), id: \.element.id) { index, direccion in
                                let seleccionada = direccion.id == idSeleccionada
                                Button {
                                    viewModel.onDireccionUsuarioSeleccionadaChange(idDireccion: direccion.id)
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandirDirecciones = false
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Circle()
                                            .stroke(seleccionada ? Color.verdePrincipal : Color.grisSecundario, lineWidth: 2)
                                            .background(
                                                Circle().fill(seleccionada ? Color.verdePrincipal : Color.clear)
                                            )
                                            .frame(width: 18, height: 18)
                                        Text(StringUtils.formatearDireccion(direccion.calle, direccion.numero, direccion.departamento))
                                            .font(.custom("Barlow", size: 15))
                                            .foregroundColor(.negro)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(seleccionada ? Color.verdePrincipal.opacity(0.08) : Color.blanco)
                                }
                                .buttonStyle(.plain)

                                if index < viewModel.direccionesUsuario.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.blanco)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.grisSecundario, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 4)
                        .offset(y: 52)
                        .zIndex(10)
                    }
                }
                .zIndex(expandirDirecciones ? 10 : 0)
            }

            Spacer().frame(height: 16)

            Button(action: onNuevaDireccion) {
                Text("Nueva Dirección")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.blanco)
                    .frame(height: 36)
                    .padding(.horizontal, 24)
            }
            .background(Color.verdePrincipal)
            .cornerRadius(24)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 80)
        }
        .padding(.top, 4)
    }
}

// PASO 2: COMERCIO

private struct PasoComercioView: View {
    @ObservedObject var viewModel: NuevoRepartoViewModel

    var body: some View {
        VStack(spacing: 8) {
            // Toggle Buscar / Manual
            HStack(spacing: 0) {
                Button {
                    viewModel.seleccionarModo(manual: false)
                } label: {
                    Text("Buscar Dirección")
                        .font(.custom("Barlow", size: 11))
                        .bold()
                        .foregroundColor(!viewModel.modoManual ? .blanco : .grisSecundario)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(!viewModel.modoManual ? Color.verdePrincipal : Color.blanco)
                        .contentShape(Rectangle())
                }

                Button {
                    viewModel.seleccionarModo(manual: true)
                } label: {
                    Text("Cargar Manualmente")
                        .font(.custom("Barlow", size: 11))
                        .bold()
                        .foregroundColor(viewModel.modoManual ? .blanco : .grisSecundario)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .background(viewModel.modoManual ? Color.verdePrincipal : Color.blanco)
                        .contentShape(Rectangle())
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )
            .cornerRadius(24)
            .padding(.horizontal, 30)

            // Buscador (solo en modo búsqueda)
            PlacesSearchBar(
                coordenadasInicialesGPS: viewModel.coordenadasDestino,
                soloDirecciones: false,
                placeholder: "Buscar Dirección / Comercio"
            ) { place in
                viewModel.actualizarDesdePlace(place)
            }
            .opacity(viewModel.modoManual ? 0 : 1)
            .allowsHitTesting(!viewModel.modoManual)

            // Calle y Número
            GeometryReader { geo in
                HStack(spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calle")
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(.negro)
                        TextField(
                            text: Binding(
                                get: { viewModel.calle },
                                set: { if viewModel.modoManual { viewModel.calle = $0 } }
                            ),
                            prompt: Text("").foregroundColor(.grisSecundario)
                        ) { EmptyView() }
                            .font(.custom("Barlow", size: 16))
                            .foregroundColor(.negro)
                            .disabled(!viewModel.modoManual)
                            .padding(10)
                            .background(viewModel.modoManual ? Color.blanco : Color.grisSecundario.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.grisSecundario, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    .frame(width: geo.size.width * 0.62)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Número")
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(.negro)
                        TextField(
                            text: Binding(
                                get: { viewModel.numero },
                                set: { viewModel.onNumeroChange($0) }
                            ),
                            prompt: Text("").foregroundColor(.grisSecundario)
                        ) { EmptyView() }
                            .font(.custom("Barlow", size: 16))
                            .foregroundColor(.negro)
                            .disabled(viewModel.modoManual ? false : viewModel.calle.isEmpty)
                            .padding(10)
                            .background(
                                (viewModel.modoManual || !viewModel.calle.isEmpty) ? Color.blanco : Color.grisSecundario.opacity(0.15)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.grisSecundario, lineWidth: 1)
                            )
                            .cornerRadius(8)
                    }
                    .frame(width: geo.size.width * 0.38 - 8)
                }
            }
            .frame(height: 68)

            // Nombre del Comercio
            VStack(alignment: .leading, spacing: 2) {
                Text("Nombre del Comercio")
                    .font(.custom("Barlow", size: 12))
                    .bold()
                    .foregroundColor(.negro)
                TextField(
                    text: $viewModel.nombreComercio,
                    prompt: Text("").foregroundColor(.grisSecundario)
                ) { EmptyView() }
                    .font(.custom("Barlow", size: 16))
                    .foregroundColor(.negro)
                    .padding(10)
                    .background(Color.blanco)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )
                    .cornerRadius(8)
            }
        }
        .padding(.top, 4)
    }
}

// PASO 3: DESCRIPCIÓN

private struct PasoDescripcionView: View {
    @ObservedObject var viewModel: NuevoRepartoViewModel

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $viewModel.descripcionEnvio)
                .font(.custom("Barlow", size: 16))
                .foregroundColor(.negro)
                .frame(minHeight: 140, maxHeight: 140)
                .padding(8)
                .background(Color.blanco)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )

            if viewModel.descripcionEnvio.isEmpty {
                Text("Descripción (Productos a Retirar)")
                    .font(.custom("Barlow", size: 16))
                    .foregroundColor(.grisSecundario)
                    .padding(.leading, 14)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
            }
        }
        .padding(.top, 4)
    }
}

// PASO 4: PAGO

private struct PasoPagoView: View {
    @ObservedObject var viewModel: NuevoRepartoViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Sí / No
            HStack(spacing: 12) {
                Button {
                    viewModel.onPagoTransferenciaChange(true)
                } label: {
                    Text("Sí")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(viewModel.pagoTransferencia == true ? Color.verdePrincipal : .negro)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.pagoTransferencia == true ? Color.verdePrincipal.opacity(0.1) : Color.blanco)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.pagoTransferencia == true ? Color.verdePrincipal : Color.grisSecundario,
                                    lineWidth: viewModel.pagoTransferencia == true ? 2 : 1
                                )
                        )
                        .cornerRadius(16)
                }

                Button {
                    viewModel.onPagoTransferenciaChange(false)
                } label: {
                    Text("No")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(viewModel.pagoTransferencia == false ? Color.verdePrincipal : .negro)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(viewModel.pagoTransferencia == false ? Color.verdePrincipal.opacity(0.1) : Color.blanco)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    viewModel.pagoTransferencia == false ? Color.verdePrincipal : Color.grisSecundario,
                                    lineWidth: viewModel.pagoTransferencia == false ? 2 : 1
                                )
                        )
                        .cornerRadius(16)
                }
            }

            if viewModel.pagoTransferencia == true {
                Text("Subí el comprobante del pago al comercio.")
                    .font(.custom("Barlow", size: 13))
                    .bold()
                    .foregroundColor(.grisSecundario)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                ComprobantePagoView(
                    estaCargando: false,
                    comprobanteEnMemoria: viewModel.comprobanteSeleccionado?.contenido,
                    urlComprobante: nil,
                    botonHabilitado: true,
                    backgroundImagen: Color.grisSecundario,
                    altoImagen: 400,
                    onCargarComprobante: { comprobante in
                        viewModel.cargarComprobante(comprobante)
                    }
                )
            } else if viewModel.pagoTransferencia == false {
                Text("Un repartidor abonará sus productos en efectivo y luego se le cobrará al recibir los mismos.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                // Precio Total
                VStack(alignment: .leading, spacing: 4) {
                    Text("Precio Total de Productos")
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(.negro)
                    TextField(
                        text: Binding(
                            get: { viewModel.precioTotalProductos },
                            set: { viewModel.onPrecioTotalProductosChange($0) }
                        ),
                        prompt: Text("$ 0").font(.custom("Barlow", size: 14)).foregroundColor(.grisSecundario)
                    ) { EmptyView() }
                        .keyboardType(.numberPad)
                        .font(.custom("Barlow", size: 16))
                        .foregroundColor(.negro)
                        .frame(height: 48)
                        .padding(.horizontal, 12)
                        .background(Color.blanco)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    viewModel.superaLimitePagoEfectivo ? Color.rojoError : Color.grisSecundario,
                                    lineWidth: viewModel.superaLimitePagoEfectivo ? 2 : 1
                                )
                        )
                        .cornerRadius(8)

                    if viewModel.superaLimitePagoEfectivo {
                        Text("El límite máximo para pago en efectivo es de \(DoubleUtils.formatearPrecio(valor: viewModel.limitePagoEfectivo)), utilizá la opción de pago por transferencia para realizar tu pedido.")
                            .font(.custom("Barlow", size: 13))
                            .bold()
                            .foregroundColor(.rojoError)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }

                SeccionVerificacionWhatsAppView(viewModel: viewModel)
            }
        }
        .padding(.top, 4)
    }
}

// PASO 5: RESUMEN

private struct PasoResumenView: View {
    @ObservedObject var viewModel: NuevoRepartoViewModel

    private var direccionUsuarioTexto: String {
        guard let id = viewModel.idDireccionUsuarioSeleccionada,
              let dir = viewModel.direccionesUsuario.first(where: { $0.id == id }) else { return "" }
        return StringUtils.formatearDireccion(dir.calle, dir.numero, dir.departamento)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Tabla resumen
            VStack(spacing: 8) {
                ResumenFilaView(label: "Dirección del Comercio", value: "\(viewModel.calle) \(viewModel.numero)")
                Divider()
                ResumenFilaView(label: "Nombre del Comercio", value: viewModel.nombreComercio)
                Divider()
                ResumenFilaView(label: "Dirección del Usuario", value: direccionUsuarioTexto)
                Divider()
                ResumenFilaView(label: "Nombre del Usuario", value: viewModel.obtenerNombreUsuario())
                Divider()
                ResumenFilaView(label: "Descripción", value: viewModel.descripcionEnvio)
                Divider()
                ResumenFilaView(
                    label: "Modalidad de Pago",
                    value: viewModel.pagoTransferencia == true ? "Transferencia"
                         : viewModel.pagoTransferencia == false ? "Efectivo" : ""
                )
            }
            .padding(12)
            .background(Color.grisSecundario.opacity(0.15))
            .cornerRadius(12)

            Text("El envío se abona directamente al repartidor.")
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.rojoError)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ResumenItemView(
                    label: "Costo de envío",
                    value: viewModel.calculandoCostoEnvio ? "" : {
                        guard let costo = viewModel.costoEnvio else { return "" }
                        return DoubleUtils.formatearPrecio(valor: Double(costo) + viewModel.tarifaServicio)
                    }()
                )
                ResumenItemView(
                    label: "Distancia",
                    value: viewModel.calculandoCostoEnvio ? "" : {
                        guard let dist = viewModel.distanciaEnvio else { return "" }
                        if dist >= 1000 {
                            return String(format: "%.1f km", Double(dist) / 1000.0)
                        }
                        return "\(dist) m"
                    }()
                )
            }

            let demanda = (viewModel.demandaRepartidores ?? "normal").lowercased()
            Text(demanda == "baja" ? "Baja Demanda" : (demanda == "alta" ? "Alta Demanda" : "Demanda Normal"))
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(demanda == "baja" ? .verdePrincipal : (demanda == "alta" ? .rojoError : .orange))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 4)
    }
}

// COMPONENTES AUXILIARES

private struct ResumenFilaView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(.grisTerciario)
            Text(value)
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ResumenItemView: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(.negro)
            Text(value)
                .font(.custom("Barlow", size: 15))
                .foregroundColor(.negro)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: 44)
                .padding(.horizontal, 8)
                .background(Color.grisSecundario.opacity(0.15))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

private struct SeccionVerificacionWhatsAppView: View {
    @ObservedObject var viewModel: NuevoRepartoViewModel

    private let paises = [
        ("ar", "+54"), ("br", "+55"), ("cl", "+56"),
        ("uy", "+598"), ("py", "+595")
    ]

    private var puedeEnviar: Bool {
        !viewModel.celularNumero.isEmpty && viewModel.estadoEnvioCodigo != .enviando
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Ingresá tu número de WhatsApp para recibir el código de verificación.")
                .font(.custom("Barlow", size: 13))
                .foregroundColor(.negro)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                // Selector de país
                Menu {
                    ForEach(paises, id: \.1) { pais in
                        Button {
                            viewModel.onCelularPaisChange(pais.1)
                        } label: {
                            Text("\(pais.1) (\(pais.0.uppercased()))")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let iso = paises.first(where: { $0.1 == viewModel.celularPais })?.0 {
                            AsyncImage(url: URL(string: "https://flagcdn.com/80x60/\(iso).png")) { img in
                                img.resizable().aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.grisSecundario.opacity(0.3)
                            }
                            .frame(width: 20, height: 15)
                            .clipped()
                            .cornerRadius(2)
                        }
                        Text(viewModel.celularPais)
                            .font(.custom("Barlow", size: 13))
                            .bold()
                            .foregroundColor(.negro)
                    }
                    .frame(width: 80, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )
                    .cornerRadius(8)
                }

                // Campo número
                TextField(
                    text: Binding(
                        get: { viewModel.celularNumero },
                        set: { viewModel.onCelularNumeroChange($0) }
                    ),
                    prompt: Text("Sin 0 y sin 15")
                        .font(.custom("Barlow", size: 12))
                        .foregroundColor(.grisSecundario)
                ) { EmptyView() }
                    .keyboardType(.numberPad)
                    .font(.custom("Barlow", size: 16))
                    .foregroundColor(.negro)
                    .frame(height: 48)
                    .padding(.horizontal, 8)
                    .background(Color.blanco)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )
                    .cornerRadius(8)

                // Botón enviar código
                Button {
                    viewModel.enviarCodigoVerificacion()
                } label: {
                    Group {
                        if viewModel.estadoEnvioCodigo == .enviando {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blanco))
                                .frame(width: 20, height: 20)
                        } else {
                            Text(viewModel.estadoEnvioCodigo == .enviado ? "Reenviar" : "Enviar código")
                                .font(.custom("Barlow", size: 12))
                                .bold()
                                .foregroundColor(puedeEnviar ? .blanco : .grisSecundario)
                        }
                    }
                    .frame(height: 48)
                    .padding(.horizontal, 10)
                    .background(puedeEnviar ? Color.verdePrincipal : Color.grisSecundario.opacity(0.3))
                    .cornerRadius(8)
                }
                .disabled(!puedeEnviar)
            }

            if viewModel.estadoEnvioCodigo == .enviado || viewModel.estadoEnvioCodigo == .error {
                VStack(spacing: 6) {
                    Text("Ingresá el código de 6 dígitos que recibiste por WhatsApp.")
                        .font(.custom("Barlow", size: 13))
                        .foregroundColor(.negro)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    TextField(
                        text: Binding(
                            get: { viewModel.codigoVerificacion },
                            set: { viewModel.onCodigoVerificacionChange($0) }
                        ),
                        prompt: Text("------")
                            .font(.custom("Barlow", size: 20))
                            .bold()
                            .foregroundColor(.grisSecundario)
                    ) { EmptyView() }
                        .keyboardType(.numberPad)
                        .font(.custom("Barlow", size: 20))
                        .bold()
                        .foregroundColor(.negro)
                        .multilineTextAlignment(.center)
                        .frame(height: 48)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    viewModel.codigoVerificado ? Color.verdePrincipal : Color.grisSecundario,
                                    lineWidth: 1
                                )
                        )
                        .cornerRadius(8)

                    if viewModel.codigoVerificado {
                        Text("Código verificado")
                            .font(.custom("Barlow", size: 12))
                            .foregroundColor(.verdePrincipal)
                    }
                }
            }
        }
    }
}