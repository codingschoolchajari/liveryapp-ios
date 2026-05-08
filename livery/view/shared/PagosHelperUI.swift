//
//  PagosHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 29/03/2026.
//
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

func obtenerSubtotal(
    tipoEntrega: TipoEntrega?,
    precioTotal: Double,
    tarifaServicio: Double,
    totalDescuentos: Double = 0.0
) -> String {
    if tipoEntrega == .envioLivery {
        return DoubleUtils.formatearPrecio(valor: precioTotal + totalDescuentos)
    }

    return DoubleUtils.formatearPrecio(valor: precioTotal + tarifaServicio + totalDescuentos)
}

struct MontoAPagarView: View {
    let subtotal: String
    let tipoEntrega: TipoEntrega?

    var body: some View {
        VStack(spacing: 0) {
            Text(subtotal)
                .font(.custom("Barlow", size: 18))
                .bold()
                .padding(.vertical, 8)
                .padding(.horizontal, 40)
                .background(Color.blanco)
                .foregroundColor(Color.negro)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.rojoError, lineWidth: 2)
                )

            if tipoEntrega != .retiroEnComercio {
                Spacer().frame(height: 4)

                Text("El envío se abona directamente al repartidor.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.rojoError)
            }
        }
    }
}

struct DatosBancariosPagoView: View {
    let datosBancarios: ComercioDatosBancarios?

    @State private var aliasCopiado = false
    @State private var cbuCopiado = false

    var body: some View {
        VStack(spacing: 8) {
            datoCopiable(
                titulo: "ALIAS",
                valor: datosBancarios?.alias ?? "",
                copiado: $aliasCopiado
            )

            datoCopiable(
                titulo: "CBU/CVU",
                valor: datosBancarios?.cbu ?? "",
                copiado: $cbuCopiado
            )

            VStack(spacing: 2) {
                Text("TITULAR")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)

                Text(datosBancarios?.titular ?? "")
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(.negro)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blanco)
        .cornerRadius(12)
    }

    private func datoCopiable(
        titulo: String,
        valor: String,
        copiado: Binding<Bool>
    ) -> some View {
        VStack(spacing: 2) {
            Text(titulo)
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(.negro)

            HStack {
                Text(valor)
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(.negro)

                Button(action: {
                    UIPasteboard.general.string = valor
                    withAnimation { copiado.wrappedValue = true }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation { copiado.wrappedValue = false }
                    }
                }) {
                    Image("icono_copiar")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(copiado.wrappedValue ? .verdePrincipal : .negro)
                }
            }
            .offset(x: 18)
        }
    }
}

struct ComprobantePagoView: View {
    let estaCargando: Bool
    let comprobanteEnMemoria: Data?
    let urlComprobante: String?
    var botonHabilitado: Bool = true
    var backgroundImagen: Color = .blanco
    var altoImagen: CGFloat = 380
    let onCargarComprobante: (Comprobante) -> Void

    // Imagen cargada localmente: se actualiza de forma inmediata al seleccionar,
    // sin pasar por el ciclo ViewModel → parent → prop (que requiere ZoomableContainer update)
    @State private var imagenLocal: UIImage? = nil

    private var existeComprobante: Bool {
        imagenLocal != nil || comprobanteEnMemoria != nil || urlComprobante != nil
    }
    @State private var mostrarMenu = false
    @State private var mostrarSelectorFotos = false
    @State private var mostrarSelectorArchivos = false
    @State private var fotoSeleccionada: PhotosPickerItem? = nil

    var body: some View {
        VStack {
            ZStack {
                if estaCargando {
                    ProgressView()
                } else if let imagen = imagenLocal ?? comprobanteEnMemoria.flatMap({ UIImage(data: $0) }) {
                    Image(uiImage: imagen)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 250, height: altoImagen)
                        .background(backgroundImagen)
                        .cornerRadius(12)
                        .clipped()
                } else {
                    ZoomableContainer {
                        contenidoRemoto
                    }
                    .frame(width: 250, height: altoImagen)
                    .background(backgroundImagen)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 2)

            Spacer().frame(height: 8)

            if botonHabilitado {
                Button(action: { mostrarMenu = true }) {
                    Text(existeComprobante ? "Reemplazar Comprobante" : "Cargar Comprobante")
                        .font(.custom("Barlow", size: 14))
                        .bold()
                        .foregroundColor(.blanco)
                        .frame(maxWidth: .infinity)
                        .frame(height: 35)
                        .background(Color.verdePrincipal)
                        .cornerRadius(24)
                }
                .padding(.horizontal, 60)
            }
        }
        .confirmationDialog("Seleccionar comprobante", isPresented: $mostrarMenu, titleVisibility: .visible) {
            Button("Galería de Fotos (Capturas)") {
                mostrarSelectorFotos = true
            }
            Button("Archivos / PDF") {
                mostrarSelectorArchivos = true
            }
            Button("Cancelar", role: .cancel) {}
        }
        .photosPicker(isPresented: $mostrarSelectorFotos, selection: $fotoSeleccionada, matching: .images, preferredItemEncoding: .compatible)
        .onChange(of: fotoSeleccionada) { _, newItem in
            if let newItem {
                procesarFotoDeGaleria(item: newItem)
            }
        }
        .fileImporter(
            isPresented: $mostrarSelectorArchivos,
            allowedContentTypes: [.png, .jpeg, .pdf],
            allowsMultipleSelection: false
        ) { result in
            procesarArchivo(result: result)
        }
    }

    // Solo se usa cuando hay URL remota (sin datos en memoria)
    @ViewBuilder
    private var contenidoRemoto: some View {
        if let urlComprobante, let url = URL(string: urlComprobante) {
            RemoteImage(url: url)
        } else {
            Image(systemName: "photo")
                .foregroundColor(.grisSecundario)
        }
    }

    private func procesarFotoDeGaleria(item: PhotosPickerItem) {
        Task {
            // Intentar cargar como Data (con .compatible fuerza JPEG en lugar de HEIC)
            var imagenUIKit: UIImage? = nil

            if let data = try? await item.loadTransferable(type: Data.self),
               let imagen = UIImage(data: data) {
                imagenUIKit = imagen
            }

            // Fallback: si loadTransferable falla (puede ocurrir en builds de distribución),
            // cargar usando el NSItemProvider subyacente
            if imagenUIKit == nil {
                imagenUIKit = await withCheckedContinuation { continuation in
                    item.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                        continuation.resume(returning: obj as? UIImage)
                    }
                }
            }

            guard let imagenCargada = imagenUIKit else {
                print("❌ ComprobantePagoView: no se pudo cargar la imagen desde galería")
                return
            }

            // Convertir a JPEG para redimensionar (asegura compatibilidad cross-build)
            let rawData = imagenCargada.jpegData(compressionQuality: 1.0) ?? Data()

            guard let dataFinal = redimensionarImagen(imageBytes: rawData, maxWidth: 1000, maxHeight: 1200) else {
                print("❌ ComprobantePagoView: redimensionarImagen devolvió nil")
                return
            }
            let comprobante = Comprobante(
                contenido: dataFinal,
                nombre: "comprobante_\(Int(Date().timeIntervalSince1970)).jpg",
                extension: "jpg"
            )
            await MainActor.run {
                imagenLocal = UIImage(data: dataFinal)
                onCargarComprobante(comprobante)
            }
        }
    }

    private func procesarArchivo(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }

                do {
                    let dataOriginal = try Data(contentsOf: url)
                    let nombre = url.lastPathComponent
                    let extensionArchivo = url.pathExtension.lowercased()

                    var dataFinal = dataOriginal
                    var extensionFinal = extensionArchivo
                    var nombreFinal = nombre

                    if extensionArchivo == "pdf",
                       let imagenDesdePdf = convertirPdfAJpg(pdfData: dataOriginal) {
                        dataFinal = imagenDesdePdf
                        extensionFinal = "jpg"
                        nombreFinal = nombre.replacingOccurrences(of: ".pdf", with: ".jpg", options: .caseInsensitive)
                    }

                    if let imagenRedimensionada = redimensionarImagen(
                        imageBytes: dataFinal,
                        maxWidth: 1000,
                        maxHeight: 1200
                    ) {
                        dataFinal = imagenRedimensionada
                    }

                    let comprobante = Comprobante(
                        contenido: dataFinal,
                        nombre: nombreFinal,
                        extension: extensionFinal
                    )

                    imagenLocal = UIImage(data: dataFinal)
                    onCargarComprobante(comprobante)
                } catch {
                    print("❌ ComprobantePagoView: error al leer archivo: \(error.localizedDescription)")
                }
            }

        case .failure(let error):
            print("❌ ComprobantePagoView: error al seleccionar archivo: \(error.localizedDescription)")
        }
    }
}