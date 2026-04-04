import SwiftUI

struct CancelarRepartoTab: View {
    @ObservedObject var repartosViewModel: RepartosViewModel
    let onClose: () -> Void

    @State private var motivoCancelacion = ""
    @State private var mostrarDialogo = false

    var body: some View {
        let reparto = repartosViewModel.repartoSeleccionado
        let estado = EstadoReparto.desdeString(reparto?.estado?.nombre ?? "")
        let repartidorAsignado = !((reparto?.idRepartidor ?? "").isEmpty) || !((reparto?.nombreRepartidor ?? "").isEmpty)

        VStack {
            if repartidorAsignado {
                Text("No es posible cancelar este reparto porque ya tiene un repartidor asignado. Si necesitas cancelarlo, comunicate con soporte de Livery.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
                Spacer()
            } else {
                VStack(spacing: 16) {
                    TextEditor(text: Binding(
                        get: {
                            if motivoCancelacion.isEmpty {
                                return reparto?.estado?.extra ?? ""
                            }
                            return motivoCancelacion
                        },
                        set: { nuevo in
                            motivoCancelacion = String(nuevo.prefix(100))
                        }
                    ))
                    .frame(minHeight: 90, maxHeight: 90)
                    .padding(8)
                    .background(Color.blanco)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.grisSecundario, lineWidth: 1)
                    )
                    .disabled((reparto?.estado?.extra?.isEmpty == false) || estado == .cancelado)

                    Spacer()

                    Button {
                        mostrarDialogo = true
                    } label: {
                        Text("Cancelar Reparto")
                            .font(.custom("Barlow", size: 16))
                            .bold()
                            .foregroundColor(.blanco)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                (motivoCancelacion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || estado == .cancelado) ? Color.grisSurface : Color.rojoError
                            )
                            .cornerRadius(24)
                    }
                    .disabled(motivoCancelacion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || estado == .cancelado)
                    .padding(.horizontal, 50)
                }
                .padding(16)
            }
        }
        .alert(isPresented: $mostrarDialogo) {
            Alert(
                title: Text("Confirmar Cancelacion"),
                message: Text("Estas seguro de que deseas cancelar el reparto?"),
                primaryButton: .destructive(Text("Si")) {
                    Task {
                        await repartosViewModel.cancelarReparto(
                            motivoCancelacion: motivoCancelacion.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onClose()
                    }
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
}
