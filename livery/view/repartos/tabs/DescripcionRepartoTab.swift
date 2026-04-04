import SwiftUI

struct DescripcionRepartoTab: View {
    let reparto: Reparto
    let estadoReparto: EstadoReparto?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                SeccionDesplegable(titulo: "Resumen", expandidoInicialmente: true) {
                    resumen
                }

                SeccionDesplegable(titulo: "Descripcion", expandidoInicialmente: false) {
                    Text(reparto.descripcion?.isEmpty == false ? (reparto.descripcion ?? "") : "-")
                        .font(.custom("Barlow", size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 4)
                }

                if estadoReparto == .cancelado,
                   let extra = reparto.estado?.extra,
                   !extra.isEmpty {
                    SeccionDesplegable(titulo: "Motivo Cancelacion", expandidoInicialmente: true) {
                        Text(extra)
                            .font(.custom("Barlow", size: 14))
                            .bold()
                            .foregroundColor(.rojoError)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    private var resumen: some View {
        VStack(spacing: 4) {
            row(titulo: "Comercio", valor: reparto.nombreComercio ?? "")
            row(
                titulo: "Direccion",
                valor: StringUtils.formatearDireccion(
                    reparto.direccionOrigen?.calle,
                    reparto.direccionOrigen?.numero,
                    reparto.direccionOrigen?.departamento
                )
            )

            Spacer().frame(height: 20)

            row(titulo: "Cliente", valor: reparto.nombreUsuario)
            row(
                titulo: "Direccion",
                valor: StringUtils.formatearDireccion(
                    reparto.direccion.calle,
                    reparto.direccion.numero,
                    reparto.direccion.departamento
                )
            )

            Spacer().frame(height: 20)

            row(titulo: "Envio", valor: DoubleUtils.formatearPrecio(valor: reparto.envio + reparto.tarifaServicio))
            row(titulo: "Repartidor", valor: reparto.nombreRepartidor ?? "")
        }
        .padding(.horizontal, 4)
    }

    private func row(titulo: String, valor: String) -> some View {
        HStack {
            Text(titulo)
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
            Spacer()
            Text(valor)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.negro)
        }
    }
}
