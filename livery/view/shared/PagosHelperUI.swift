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
    tarifaServicio: Double
) -> String {
    if tipoEntrega == .envioLivery {
        return DoubleUtils.formatearPrecio(valor: precioTotal)
    }

    return DoubleUtils.formatearPrecio(valor: precioTotal + tarifaServicio)
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
    let onCargarComprobante: (Comprobante) -> Void

    @State private var existeComprobante = false
    @State private var mostrarMenu = false
    @State private var mostrarSelectorFotos = false
    @State private var mostrarSelectorArchivos = false
    @State private var fotoSeleccionada: PhotosPickerItem? = nil

    var body: some View {
        VStack {
            ZStack {
                if estaCargando {
                    ProgressView()
                } else {
                    ZoomableContainer {
                        contenidoImagen
                    }
                }
            }
            .frame(width: 250, height: 380)
            .background(Color.blanco)
            .cornerRadius(12)
            .padding(12)

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
        .photosPicker(isPresented: $mostrarSelectorFotos, selection: $fotoSeleccionada, matching: .images)
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

    @ViewBuilder
    private var contenidoImagen: some View {
        if let comprobanteEnMemoria,
           let image = UIImage(data: comprobanteEnMemoria) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onAppear { existeComprobante = true }
        } else if let urlComprobante,
                  let url = URL(string: urlComprobante) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .onAppear { existeComprobante = true }
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.grisSecundario)
                        .onAppear { existeComprobante = false }
                default:
                    ProgressView()
                }
            }
        } else {
            Image(systemName: "photo")
                .foregroundColor(.grisSecundario)
                .onAppear { existeComprobante = false }
        }
    }

    private func procesarFotoDeGaleria(item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let dataRedimensionada = redimensionarImagen(
                    imageBytes: data,
                    maxWidth: 1000,
                    maxHeight: 1200
               ) {
                let comprobante = Comprobante(
                    contenido: dataRedimensionada,
                    nombre: "comprobante_\(Int(Date().timeIntervalSince1970)).jpg",
                    extension: "jpg"
                )

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

                    onCargarComprobante(comprobante)
                } catch {
                    print("Error al leer los datos del archivo: \(error.localizedDescription)")
                }
            }

        case .failure(let error):
            print("Error al seleccionar el archivo: \(error.localizedDescription)")
        }
    }
}