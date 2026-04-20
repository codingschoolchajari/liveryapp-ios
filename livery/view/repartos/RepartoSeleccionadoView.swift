import SwiftUI

struct BottomSheetRepartoDescripcion: View {
    var onClose: () -> Void

    @ObservedObject var repartosViewModel: RepartosViewModel
    @StateObject var repartoChatViewModel: RepartoChatViewModel

    @State private var selectedTabIndex = 0

    let tabsFila1 = ["Descripcion", "Pago"]
    let tabsFila2 = ["Recorrido", "Chat Repartidor", "Cancelacion"]

    init(perfilUsuarioState: PerfilUsuarioState, repartosViewModel: RepartosViewModel, onClose: @escaping () -> Void) {
        self.repartosViewModel = repartosViewModel
        self.onClose = onClose
        _repartoChatViewModel = StateObject(wrappedValue: RepartoChatViewModel(perfilUsuarioState: perfilUsuarioState))
    }

    var body: some View {
        VStack(spacing: 0) {
            if let reparto = repartosViewModel.repartoSeleccionado {
                let estado = EstadoReparto.desdeString(reparto.estado?.nombre ?? "")

                VStack(spacing: 0) {
                    Spacer().frame(height: 16)

                    PortadaRepartoView(repartosViewModel: repartosViewModel, reparto: reparto, onClose: onClose)

                    Spacer().frame(height: 8)
                    EstadoRepartoView(estadoReparto: estado)
                    Spacer().frame(height: 16)

                    Divider()
                        .frame(height: 1.5)
                        .background(Color.grisTerciario)
                    Spacer().frame(height: 4)

                    TabsConBoxes(
                        tabsFila1: tabsFila1,
                        tabsFila2: tabsFila2,
                        selectedTabIndex: $selectedTabIndex
                    )

                    Spacer().frame(height: 4)
                    Divider()
                        .frame(height: 1.5)
                        .background(Color.grisTerciario)

                    Spacer().frame(height: 8)

                    VStack {
                        switch selectedTabIndex {
                        case 0:
                            DescripcionRepartoTab(reparto: reparto, estadoReparto: estado)
                        case 1:
                            PagoRepartoTab(repartosViewModel: repartosViewModel, reparto: reparto, estadoReparto: estado)
                        case 2:
                            RecorridoRepartoTab(repartosViewModel: repartosViewModel)
                        case 3:
                            ChatRepartoTab(repartosViewModel: repartosViewModel, repartoChatViewModel: repartoChatViewModel)
                        case 4:
                            CancelarRepartoTab(repartosViewModel: repartosViewModel, onClose: onClose)
                        default:
                            EmptyView()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onChange(of: selectedTabIndex) { _, newValue in
            repartoChatViewModel.setChatTabActive(active: newValue == 3)
            repartosViewModel.setRecorridoTabActive(active: newValue == 2)
        }
    }
}

private struct PortadaRepartoView: View {
    @ObservedObject var repartosViewModel: RepartosViewModel
    let reparto: Reparto
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .top) {
            Button(action: {
                Task {
                    await repartosViewModel.refrescarRepartoSeleccionado(reparto: reparto)
                }
            }) {
                Image("icono_reload")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.negro)
            }

            Spacer()

            ZStack {
                Color.gray.opacity(0.3)

                if reparto.tipo == "REPARTO_SOLICITADO_USUARIO" {
                    Image("logo_reparto_usuario")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    RemoteImage(url: URL(string: API.baseURL + "/" + (reparto.logoComercioURL ?? "")))
                }
            }
            .frame(width: 65, height: 65)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button(action: onClose) {
                Image("icono_cerrar")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.negro)
                    .background(Color.blanco)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.negro, lineWidth: 2))
            }
        }
        .padding(.horizontal, 16)
    }
}

private struct EstadoRepartoView: View {
    let estadoReparto: EstadoReparto?

    var body: some View {
        if let estado = estadoReparto {
            VStack(spacing: 2) {
                Text(estado.descripcion)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(estado.color)

                Text(estado.aclaracion)
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.grisSecundario)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
        }
    }
}
