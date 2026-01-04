//
//  PagoTab.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI
import PhotosUI

struct PagoTab: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    let pedido: Pedido
    let estadoPedido: EstadoPedido?
    
    var body: some View {
        VStack {
            if estadoPedido != .pendienteAprobacion {
                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        Text(
                            DoubleUtils.formatearPrecio(
                                valor : pedido.precioTotal + (pedido.tarifaServicio)
                            )
                        )
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
                        
                        Spacer().frame(height: 4)
                        
                        Text("El envío se abona directamente al repartidor.")
                            .font(.custom("Barlow", size: 12))
                            .bold()
                            .foregroundColor(.negro)
                        
                        Spacer().frame(height: 8)
                        
                        // Secciones Desplegables
                        SeccionDesplegable(
                            titulo: "Datos Bancarios",
                            expandidoInicialmente: false,
                            backgroundColor: Color.grisSurface,
                            contenido: {
                                DatosBancariosView(pedidosViewModel: pedidosViewModel)
                            }
                        )
                        
                        Spacer().frame(height: 8)
                        
                        SeccionDesplegable(
                            titulo: "Comprobante",
                            expandidoInicialmente: true,
                            backgroundColor: Color.grisSurface,
                            contenido: {
                                ComprobanteView(
                                    pedidosViewModel: pedidosViewModel,
                                    pedido: pedido,
                                    estadoPedido: estadoPedido)
                            }
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.grisSurface)
                    .cornerRadius(12)
                }
            } else {
                Text("Esta sección se habilitará cuando el pedido haya sido aprobado por el comercio.")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(.negro)
                    .multilineTextAlignment(.center)
                    .padding(.top, 16)
                    .padding(.horizontal, 16)
            }
        }
    }
}

struct DatosBancariosView: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    
    @State private var aliasCopiado = false
    @State private var cbuCopiado = false
    
    var body: some View {
        let comercio = pedidosViewModel.comercioSeleccionado
        
        Spacer().frame(height: 8)
        
        VStack(spacing: 8) {
            // ALIAS
            VStack(spacing: 2) {
                Text("ALIAS")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(Color.negro)
            
                HStack {
                    Text(comercio?.datosBancarios.alias ?? "")
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(Color.negro)
                    
                    Button(action: {
                        UIPasteboard.general.string = comercio?.datosBancarios.alias ?? ""
                        withAnimation { aliasCopiado = true }
                        
                        // Volver al icono original después de 1.5 segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { aliasCopiado = false }
                        }
                    }) {
                        Image("icono_copiar")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(aliasCopiado ? .verdePrincipal : .negro)
                    }
                }
                .offset(x: 18) // Icono de copiar
            }
            
            // CBU/CVU
            VStack(spacing: 2) {
                Text("CBU/CVU")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(Color.negro)
            
                HStack {
                    Text(comercio?.datosBancarios.cbu ?? "")
                        .font(.custom("Barlow", size: 14))
                        .foregroundColor(Color.negro)
                    
                    Button(action: {
                        UIPasteboard.general.string = comercio?.datosBancarios.cbu ?? ""
                        withAnimation { cbuCopiado = true }
                        
                        // Volver al icono original después de 1.5 segundos
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { cbuCopiado = false }
                        }
                    }) {
                        Image("icono_copiar")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(cbuCopiado ? .verdePrincipal : .negro)
                    }
                }
                .offset(x: 18) // Icono de copiar
            }

            VStack(spacing: 2) {
                Text("TITULAR")
                    .font(.custom("Barlow", size: 14))
                    .bold()
                    .foregroundColor(Color.negro)
                Text(comercio?.datosBancarios.titular ?? "")
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(Color.negro)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.blanco)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func datoCopiable(titulo: String, valor: String) -> some View {
        @State var copiado: Bool = false
        
        
    }
}

struct ComprobanteView: View {
    @ObservedObject var pedidosViewModel: PedidosViewModel
    let pedido: Pedido
    let estadoPedido: EstadoPedido?
    
    @State private var existeComprobante = false
    
    @State private var mostrarMenu = false
    @State private var mostrarSelectorFotos = false
    @State private var mostrarSelectorArchivos = false
    @State private var fotoSeleccionada: PhotosPickerItem? = nil
    
    var body: some View {
        VStack {
            let urlString = API.baseURL + "/" + PedidosHelper.generarURLComprobante(pedido: pedido) + "?ts=\(Date().timeIntervalSince1970)"
            
            // Contenedor de la Imagen
            ZStack {
                ZoomableContainer {
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .onAppear { self.existeComprobante = true }
                        case .failure:
                            Image(systemName: "photo") // Placeholder si falla
                                .onAppear { self.existeComprobante = false }
                        default:
                            ProgressView()
                        }
                    }
                }
            }
            .frame(width: 250, height: 380)
            .background(Color.blanco)
            .cornerRadius(12)
            .padding(12)
            
            Spacer().frame(height: 8)
            
            // Botón de Carga
            if estadoPedido == .pendientePago {
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
        // 1. Selector de Fotos (Donde están las screenshots)
        .photosPicker(isPresented: $mostrarSelectorFotos, selection: $fotoSeleccionada, matching: .images)
        .onChange(of: fotoSeleccionada) { oldItem, newItem in
            if let newItem {
                procesarFotoDeGaleria(item: newItem)
            }
        }

        // 2. Selector de Archivos (Para PDFs)
        .fileImporter(
            isPresented: $mostrarSelectorArchivos,
            allowedContentTypes: [.png, .jpeg, .pdf],
            allowsMultipleSelection: false
        ) { result in
            procesarArchivo(result: result)
        }
    }
    
    private func procesarFotoDeGaleria(item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            // loadTransferable extrae los bytes originales (pueden ser HEIC o PNG)
            if let data = try? await item.loadTransferable(type: Data.self) {
                
                if let dataRedimensionada = redimensionarImagen(imageBytes: data, maxWidth: 1000, maxHeight: 1200) {
                    
                    // Forzamos la extensión a .jpg porque redimensionarImagen devuelve jpegData
                    let comprobante = Comprobante(
                        contenido: dataRedimensionada,
                        nombre: "comprobante_\(Int(Date().timeIntervalSince1970)).jpg",
                        extension: "jpg"
                    )
                    
                    await pedidosViewModel.cargarComprobante(pedido: pedido, comprobante: comprobante)
                }
            }
        }
    }
    
    private func procesarArchivo(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Importante en iOS: Solicitar acceso al archivo temporal (Sandbox)
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                do {
                    let dataOriginal = try Data(contentsOf: url)
                    let nombre = url.lastPathComponent
                    let extensionArchivo = url.pathExtension.lowercased()
                    
                    var dataFinal: Data = dataOriginal
                    var extensionFinal = extensionArchivo
                    var nombreFinal = nombre
                    
                    if extensionArchivo == "pdf" {
                        // CONVERTIR PDF A JPG
                        if let imagenDesdePdf = convertirPdfAJpg(pdfData: dataOriginal) {
                            dataFinal = imagenDesdePdf
                            extensionFinal = "jpg"
                            nombreFinal = nombre.replacingOccurrences(of: ".pdf", with: ".jpg", options: .caseInsensitive)
                        }
                    }
                    
                    // 1. Redimensionar
                    if let imagenRedimensionada = redimensionarImagen(
                        imageBytes: dataFinal,
                        maxWidth: 1000,
                        maxHeight: 1200
                    ) {
                        dataFinal = imagenRedimensionada
                    }
                    
                    // 2. Crear el objeto comprobante (Ajusta los nombres según tu modelo en Swift)
                    let comprobante = Comprobante(
                        contenido: dataFinal,
                        nombre: nombreFinal,
                        extension: extensionFinal
                    )
                    
                    // 3. Llamar al ViewModel
                    Task {
                        await pedidosViewModel.cargarComprobante(pedido: pedido, comprobante: comprobante)
                    }
                    print("Archivo procesado y enviado: \(nombre)")
                    
                } catch {
                    print("Error al leer los datos del archivo: \(error.localizedDescription)")
                }
            }
            
        case .failure(let error):
            print("Error al seleccionar el archivo: \(error.localizedDescription)")
        }
    }
}
