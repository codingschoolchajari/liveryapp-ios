import SwiftUI

struct RepartosView: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @Environment(\.scenePhase) var scenePhase

    @StateObject private var repartosViewModel: RepartosViewModel
    @State private var mostrarNuevoReparto = false

    init(perfilUsuarioState: PerfilUsuarioState) {
        _repartosViewModel = StateObject(wrappedValue: RepartosViewModel(perfilUsuarioState: perfilUsuarioState))
    }

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer().frame(height: 8)
                Titulo(titulo: "Repartos")
                Spacer().frame(height: 8)

                RepartosEstadosView(repartosViewModel: repartosViewModel)
                Spacer().frame(height: 12)

                RepartosListView(repartosViewModel: repartosViewModel)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blanco)

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        mostrarNuevoReparto = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.blanco)
                            .frame(width: 56, height: 56)
                            .background(Color.verdePrincipal)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .onAppear {
            repartosViewModel.refrescarRepartos()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                repartosViewModel.refrescarRepartos()
            }
        }
        .sheet(isPresented: $repartosViewModel.mostrarBottomSheet) {
            BottomSheetRepartoDescripcion(
                perfilUsuarioState: perfilUsuarioState,
                repartosViewModel: repartosViewModel,
                onClose: {
                    repartosViewModel.onMostrarBottomSheetChange(mostrar: false)
                }
            )
            .onDisappear {
                repartosViewModel.onRepartoSeleccionadoChange(reparto: nil)
                repartosViewModel.refrescarRepartos()
                repartosViewModel.onMostrarBottomSheetChange(mostrar: false)
            }
        }
        .sheet(isPresented: $mostrarNuevoReparto) {
            NuevoRepartoView(
                perfilUsuarioState: perfilUsuarioState,
                onRepartoCreado: {
                    mostrarNuevoReparto = false
                    repartosViewModel.refrescarRepartos()
                },
                onCerrar: {
                    mostrarNuevoReparto = false
                }
            )
            .presentationDetents([.large])
        }
    }
}

private struct RepartosListView: View {
    @ObservedObject var repartosViewModel: RepartosViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(repartosViewModel.repartos) { reparto in
                    VStack(spacing: 12) {
                        RepartoRow(reparto: reparto)
                            .onAppear {
                                if reparto.idInterno == repartosViewModel.repartos.last?.idInterno {
                                    Task { await repartosViewModel.cargarMasRepartos() }
                                }
                            }
                            .onTapGesture {
                                Task {
                                    await repartosViewModel.refrescarRepartoSeleccionado(reparto: reparto)
                                    repartosViewModel.onMostrarBottomSheetChange(mostrar: true)
                                }
                            }
                        Divider().background(Color.grisSecundario)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .refreshable {
            repartosViewModel.refrescarRepartos()
        }
    }
}

private struct RepartoRow: View {
    let reparto: Reparto

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if reparto.tipo == "REPARTO_SOLICITADO_USUARIO" {
                Image("logo_reparto_usuario")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 65, height: 65)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                AsyncImage(url: URL(string: API.baseURL + "/" + (reparto.logoComercioURL ?? ""))) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 65, height: 65)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            VStack(spacing: 2) {
                HStack {
                    Text(reparto.nombreComercio ?? "")
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(Color.negro)
                    Spacer()
                    Text(DoubleUtils.formatearPrecio(valor: reparto.envio + reparto.tarifaServicio))
                        .font(.custom("Barlow", size: 18))
                        .bold()
                        .foregroundColor(Color.negro)
                }

                HStack {
                    Text(RepartosHelper.obtenerEstadoReparto(estado: reparto.estado?.nombre ?? ""))
                        .font(.custom("Barlow", size: 12))
                        .bold()
                        .foregroundColor(RepartosHelper.obtenerColorEstadoReparto(estado: reparto.estado?.nombre ?? "") ?? .negro)
                    Spacer()
                }

                if let estado = reparto.estado {
                    HStack {
                        Text(DateUtils.fechaATexto(fechaStr: estado.fechaUltimaActualizacion))
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(.grisSecundario)
                        Spacer()
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
