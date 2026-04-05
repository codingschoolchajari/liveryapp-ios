import SwiftUI
import CoreLocation

struct NuevoRepartoView: View {
    let onRepartoCreado: () -> Void
    let onCerrar: () -> Void

    @StateObject private var viewModel: NuevoRepartoViewModel
    @State private var tabSeleccionada = 0
    @State private var mostrarDireccionesUsuario = false
    private let seccionContenidoHeight: CGFloat = 390

    private var coordenadasDestinoKey: String? {
        guard let coord = viewModel.coordenadasDestino else { return nil }
        return "\(coord.latitude),\(coord.longitude)"
    }

    init(perfilUsuarioState: PerfilUsuarioState, onRepartoCreado: @escaping () -> Void, onCerrar: @escaping () -> Void) {
        self.onRepartoCreado = onRepartoCreado
        self.onCerrar = onCerrar
        _viewModel = StateObject(wrappedValue: NuevoRepartoViewModel(perfilUsuarioState: perfilUsuarioState))
    }

    var body: some View {
        VStack(spacing: 10) {
            header

            HStack(spacing: 0) {
                tabItem(titulo: "Comercio", index: 0)
                tabItem(titulo: "Usuario", index: 1)
                tabItem(titulo: "Comprobante", index: 2)
            }
            .padding(.horizontal, 12)

            ZStack(alignment: .top) {
                if tabSeleccionada == 0 {
                    comercioTab
                } else if tabSeleccionada == 1 {
                    usuarioTab
                } else {
                    comprobanteTab
                }
            }
            .frame(height: seccionContenidoHeight)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $viewModel.descripcionEnvio)
                    .frame(minHeight: 80, maxHeight: 80)
                    .padding(8)
                    .background(Color.blanco)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )

                if viewModel.descripcionEnvio.isEmpty {
                    Text("Descripción (Productos a retirar)")
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(.grisSecundario)
                        .padding(.leading, 14)
                        .padding(.top, 16)
                        .allowsHitTesting(false)
                }
            }
            .padding(.horizontal, 12)

            Text("El envio se abona directamente al repartidor.")
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.rojoError)

            resumenView

            let demanda = (viewModel.demandaRepartidores ?? "normal").lowercased()
            Text(demanda == "baja" ? "Baja Demanda" : (demanda == "alta" ? "Alta Demanda" : "Demanda Normal"))
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(demanda == "baja" ? .verdePrincipal : (demanda == "alta" ? .rojoError : .orange))

            Button {
                Task {
                    await viewModel.crearReparto()
                }
            } label: {
                Text(viewModel.creandoReparto ? "Confirmando..." : "Confirmar Reparto")
                    .font(.custom("Barlow", size: 18))
                    .bold()
                    .foregroundColor(.blanco)
                    .frame(maxWidth: .infinity)
                    .frame(height: 45)
                    .background(Color.verdePrincipal)
                    .cornerRadius(24)
            }
            .disabled(!viewModel.formularioCompleto() || viewModel.creandoReparto)
            .padding(.horizontal, 70)
            .padding(.bottom, 24)
        }
        .background(Color.blanco)
        .onChange(of: viewModel.repartoCreado) { _, creado in
            if creado {
                onRepartoCreado()
                viewModel.resetearEstado()
            }
        }
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Solicitar Nuevo Reparto")
                .font(.custom("Barlow", size: 18))
                .bold()
                .foregroundColor(.negro)
            Spacer()
            Button(action: onCerrar) {
                Image("icono_cerrar")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.negro)
            }
            .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    private var comercioTab: some View {
        VStack(spacing: 8) {
            ZStack {
                if viewModel.coordenadasDestino != nil {
                    GoogleMapView(coordenadas: $viewModel.coordenadasDestino)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.verdePrincipal, lineWidth: 2)
                        )
                }

                Image("icono_ubicacion_mapa")
                    .resizable()
                    .frame(width: 52, height: 52)

                VStack {
                    PlacesSearchBar(
                        coordenadasInicialesGPS: viewModel.coordenadasDestino,
                        soloDirecciones: false,
                        placeholder: "Buscar dirección / comercio"
                    ) { place in
                        viewModel.actualizarDesdePlace(place)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)

                    Spacer()
                }
            }
            .padding(8)
            .frame(height: 280)
            .onChange(of: coordenadasDestinoKey) { _, _ in
                if let nueva = viewModel.coordenadasDestino {
                    viewModel.actualizarDestino(coordenada: nueva)
                }
            }

            TextField(
                text: $viewModel.nombreComercio,
                prompt: Text("Nombre del comercio")
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(.grisSecundario)
            ) {
                Text("Nombre del comercio")
            }
            .font(.custom("Barlow", size: 14))
            .foregroundColor(.negro)
            .padding(12)
            .background(Color.blanco)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.grisSecundario, lineWidth: 1)
            )

            HStack(spacing: 8) {
                TextField(
                    text: $viewModel.calle,
                    prompt: Text("Calle")
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(.grisSecundario)
                ) {
                    Text("Calle")
                }
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
                .padding(12)
                .background(Color.blanco)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )

                TextField(
                    text: $viewModel.numero,
                    prompt: Text("Numero")
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(.grisSecundario)
                ) {
                    Text("Numero")
                }
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
                .padding(12)
                .background(Color.blanco)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.grisSecundario, lineWidth: 1)
                )
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
    }

    private var usuarioTab: some View {
        VStack(spacing: 8) {
            let direcciones = viewModel.direccionesUsuario

            Text("Dirección de Entrega")
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.negro)
                .frame(maxWidth: .infinity, alignment: .leading)

            if direcciones.isEmpty {
                Text("No tenes direcciones guardadas")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .padding(.top, 16)
            } else {
                let direccionSeleccionada = direcciones.first(where: { $0.id == viewModel.idDireccionUsuarioSeleccionada })
                let direccionSeleccionadaTexto = direccionSeleccionada.map {
                    StringUtils.formatearDireccion($0.calle, $0.numero, $0.departamento)
                } ?? "Seleccionar dirección"

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mostrarDireccionesUsuario.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(direccionSeleccionadaTexto)
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(.negro)
                            .lineLimit(1)

                        Spacer()

                        Image(systemName: mostrarDireccionesUsuario ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.negro)
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .frame(maxWidth: .infinity)
                    .background(Color.grisSecundario)
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                if mostrarDireccionesUsuario {
                    VStack(spacing: 0) {
                        ForEach(direcciones, id: \.id) { direccion in
                            Button {
                                viewModel.onDireccionUsuarioSeleccionadaChange(idDireccion: direccion.id)
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    mostrarDireccionesUsuario = false
                                }
                            } label: {
                                Text(StringUtils.formatearDireccion(direccion.calle, direccion.numero, direccion.departamento))
                                    .font(.custom("Barlow", size: 14))
                                    .bold()
                                    .foregroundColor(.negro)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.grisTerciario)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color.grisTerciario)
                    .cornerRadius(10)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
    }

    private var comprobanteTab: some View {
        VStack(spacing: 8) {
            Text("Repartos habilitados para productos ya abonados.\nSubir aquí el comprobante del pago al comercio.")
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(.grisTerciario)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            ComprobantePagoView(
                estaCargando: false,
                comprobanteEnMemoria: viewModel.comprobanteSeleccionado?.contenido,
                urlComprobante: nil,
                botonHabilitado: true,
                backgroundImagen: Color.grisTerciario,
                altoImagen: 300,
                onCargarComprobante: { comprobante in
                    viewModel.cargarComprobante(comprobante)
                }
            )
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
    }

    private var resumenView: some View {
        HStack(spacing: 8) {
            resumenItem(
                label: "Costo envio",
                value: viewModel.calculandoCostoEnvio ? "" : (viewModel.costoEnvio != nil ? DoubleUtils.formatearPrecio(valor: Double(viewModel.costoEnvio! + Int(viewModel.tarifaServicio))) : "")
            )

            resumenItem(
                label: "Distancia",
                value: viewModel.calculandoCostoEnvio ? "" : {
                    guard let distancia = viewModel.distanciaEnvio else { return "" }
                    if distancia >= 1000 {
                        return String(format: "%.1f km", Double(distancia) / 1000.0)
                    }
                    return "\(distancia) m"
                }()
            )

            resumenItem(
                label: "Tiempo espera",
                value: viewModel.calculandoCostoEnvio ? "" : (viewModel.tiempoEspera != nil ? "\(viewModel.tiempoEspera!) min" : "")
            )
        }
        .padding(.horizontal, 12)
    }

    private func resumenItem(label: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.custom("Barlow", size: 12))
                .bold()
                .foregroundColor(.negro)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.negro)
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 34)
                .padding(.horizontal, 8)
                .background(Color.grisSecundario)
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }

    private func tabItem(titulo: String, index: Int) -> some View {
        Button {
            tabSeleccionada = index
        } label: {
            VStack(spacing: 6) {
                Text(titulo)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(tabSeleccionada == index ? .verdePrincipal : .grisSecundario)
                    .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(tabSeleccionada == index ? Color.verdePrincipal : Color.clear)
                    .frame(height: 2)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}
