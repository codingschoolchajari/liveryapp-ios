import SwiftUI

struct PagoRepartoTab: View {
    @ObservedObject var repartosViewModel: RepartosViewModel
    let reparto: Reparto
    let estadoReparto: EstadoReparto?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                SeccionDesplegable(
                    titulo: "Comprobante",
                    expandidoInicialmente: true,
                    backgroundColor: Color.grisSurface,
                    contenido: {
                        ComprobantePagoView(
                            estaCargando: repartosViewModel.cargandoComprobante,
                            comprobanteEnMemoria: nil,
                            urlComprobante: urlComprobante,
                            botonHabilitado: estadoReparto == .pendienteAsignacion,
                            onCargarComprobante: { comprobante in
                                Task {
                                    await repartosViewModel.cargarComprobante(reparto: reparto, comprobante: comprobante)
                                }
                            }
                        )
                    }
                )
            }
            .padding(12)
            .background(Color.grisSurface)
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }

    private var urlComprobante: String? {
        guard let idUsuario = reparto.idUsuario else { return nil }
        return API.baseURL + "/" + RepartosHelper.generarURLComprobante(idUsuario: idUsuario, idReparto: reparto.idInterno) + "?ts=\(Date().timeIntervalSince1970)"
    }
}
