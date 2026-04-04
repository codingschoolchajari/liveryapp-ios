import SwiftUI

struct RepartosEstadosView: View {
    @ObservedObject var repartosViewModel: RepartosViewModel

    let estados: [EstadosRepartos] = [
        .todos,
        .pendientes,
        .enCamino,
        .entregados,
        .cancelados
    ]

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                ForEach(estados.prefix(3), id: \.self) { estado in
                    EstadoItem(
                        texto: estado.descripcion,
                        seleccionado: estado == repartosViewModel.estadoSeleccionado,
                        colorSeleccion: estado.color,
                        onClick: { repartosViewModel.onEstadoSeleccionadoChange(estado: estado) }
                    )
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(estados.suffix(from: 3), id: \.self) { estado in
                    EstadoItem(
                        texto: estado.descripcion,
                        seleccionado: estado == repartosViewModel.estadoSeleccionado,
                        colorSeleccion: estado.color,
                        onClick: { repartosViewModel.onEstadoSeleccionadoChange(estado: estado) }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 12)
    }
}
