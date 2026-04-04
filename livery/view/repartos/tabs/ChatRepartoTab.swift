import SwiftUI

struct ChatRepartoTab: View {
    @ObservedObject var repartosViewModel: RepartosViewModel
    @StateObject var repartoChatViewModel: RepartoChatViewModel

    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    var body: some View {
        let repartoSeleccionado = repartosViewModel.repartoSeleccionado
        let idRepartidor = repartoSeleccionado?.idRepartidor
        let estado = EstadoReparto.desdeString(repartoSeleccionado?.estado?.nombre ?? "")

        VStack {
            if let idRepartidor, !idRepartidor.isEmpty,
               let estado,
               [.enEsperaRepartidor, .enCamino, .entregado].contains(estado) {
                RepartoChatView(repartoChatViewModel: repartoChatViewModel)
                    .id("repartidor_\(repartoSeleccionado?.idInterno ?? "")")
                    .onDisappear {
                        repartoChatViewModel.limpiarChat()
                    }
                    .padding(.horizontal, 16)
            } else {
                Text("Esta seccion se habilitara cuando un repartidor haya sido asignado.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                Spacer()
            }
        }
        .task(id: repartoSeleccionado?.idInterno) {
            if let reparto = repartoSeleccionado,
               let id = reparto.idRepartidor, !id.isEmpty {
                repartoChatViewModel.setChatParams(
                    idReparto: reparto.idInterno,
                    idRepartidor: id
                )
            }
        }
    }
}

private struct RepartoChatView: View {
    @ObservedObject var repartoChatViewModel: RepartoChatViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState

    @State private var texto: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(repartoChatViewModel.mensajes) { mensaje in
                            MensajeRow(mensaje: mensaje, emailUsuario: perfilUsuarioState.usuario?.email ?? "")
                                .id(mensaje.id)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .onChange(of: repartoChatViewModel.mensajes.count) {
                    if let lastId = repartoChatViewModel.mensajes.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isFocused) {
                    if let lastId = repartoChatViewModel.mensajes.last?.id {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                TextField("", text: $texto)
                    .tint(.verdePrincipal)
                    .disableAutocorrection(true)
                    .autocapitalization(.sentences)
                    .font(.custom("Barlow", size: 14))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .foregroundColor(Color.grisTerciario)
                    .background(Color.grisSurface)
                    .cornerRadius(22)
                    .focused($isFocused)
                    .overlay(
                        Group {
                            if texto.isEmpty {
                                Text("Escribir mensaje...")
                                    .font(.custom("Barlow", size: 14))
                                    .foregroundColor(Color.grisTerciario)
                                    .padding(.horizontal, 16)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .leading
                    )
                    .onChange(of: texto) { _, newValue in
                        var result = newValue.replacingOccurrences(of: "^\\s+", with: "", options: .regularExpression)
                        if let first = result.first {
                            result = first.uppercased() + result.dropFirst()
                        }
                        texto = String(result.prefix(100))
                    }

                Button(action: enviarMensaje) {
                    Image("icono_enviar")
                        .resizable()
                        .frame(width: 32, height: 32)
                        .foregroundColor(Color.negro)
                }
                .disabled(texto.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.vertical, 16)
        }
        .alert("Chat no disponible", isPresented: Binding(
            get: { repartoChatViewModel.errorMensaje != nil },
            set: { _ in repartoChatViewModel.limpiarError() }
        )) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(repartoChatViewModel.errorMensaje ?? "")
        }
    }

    private func enviarMensaje() {
        guard let usuario = perfilUsuarioState.usuario,
              !usuario.email.isEmpty else { return }

        let emisorNombre = "\(usuario.datosPersonales?.nombre ?? "") \(usuario.datosPersonales?.apellido ?? "")"
        let nuevoMensaje = Mensaje(texto: texto, emisorId: usuario.email, emisorNombre: emisorNombre)

        repartoChatViewModel.enviarMensaje(mensaje: nuevoMensaje)
        texto = ""
    }
}
