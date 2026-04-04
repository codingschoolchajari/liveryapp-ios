import SwiftUI
import CoreLocation

struct RecorridoRepartoTab: View {
    @ObservedObject var repartosViewModel: RepartosViewModel

    var body: some View {
        let reparto = repartosViewModel.repartoSeleccionado
        let recorrido = repartosViewModel.recorridoSeleccionado
        let estado = EstadoReparto.desdeString(reparto?.estado?.nombre ?? "")

        let habilitado = (estado == .enCamino || estado == .entregado) &&
                        reparto != nil && recorrido != nil

        VStack {
            if habilitado,
               let reparto,
               let recorrido,
               reparto.direccion.coordenadas.coordinates.count >= 2,
               let origen = reparto.direccionOrigen?.coordenadas.coordinates,
               origen.count >= 2 {
                GoogleMapTrackingView(
                    recorrido: recorrido,
                    coordComercio: CLLocationCoordinate2D(latitude: origen[0], longitude: origen[1]),
                    coordCliente: CLLocationCoordinate2D(
                        latitude: reparto.direccion.coordenadas.coordinates[0],
                        longitude: reparto.direccion.coordenadas.coordinates[1]
                    ),
                    tick: repartosViewModel.recorridoTick
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.verdePrincipal, lineWidth: 2)
                )
                .padding(4)
            } else {
                Text("Esta seccion se habilitara cuando el reparto se encuentre en camino.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                Spacer()
            }
        }
    }
}
