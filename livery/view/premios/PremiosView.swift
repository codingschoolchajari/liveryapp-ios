//
//  PremiosView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 05/01/2026.
//
import SwiftUI

struct PremiosView: View {
    
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @StateObject var premiosViewModel : PremiosViewModel
    
    init(perfilUsuarioState: PerfilUsuarioState) {
        _premiosViewModel = StateObject(
            wrappedValue: PremiosViewModel(perfilUsuarioState: perfilUsuarioState)
        )
    }
    
    @State private var mostrarPopUpResultado = false
    @State private var segmentos: [String] = []
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                if  ( perfilUsuarioState.ciudadSeleccionada != nil
                      && perfilUsuarioState.ciudadSeleccionada == StringUtils.sinCobertura
                    ) || (
                        perfilUsuarioState.usuario != nil
                        && perfilUsuarioState.usuario!.direcciones?.isEmpty ?? true
                    ) || (
                        perfilUsuarioState.idDireccionSeleccionada == nil
                    )
                {
                    DireccionFueraDeCobertura()
                } else {
                    Spacer().frame(height: 8)
                    
                    FranjaSuperior()
                    
                    // Ruleta
                    if !segmentos.isEmpty {
                        RuletaPremios(
                            segmentos: segmentos,
                            girar: premiosViewModel.girarRuleta,
                            resultado: premiosViewModel.resultadoGirarRuleta
                        ) {
                            Task {
                                premiosViewModel.onGirarRuletaChange(valor: false)
                                await perfilUsuarioState.buscarUsuario()
                                mostrarPopUpResultado = true
                            }
                        }
                    }
                    
                    Spacer().frame(height: 16)
                    
                    // Botón Girar
                    let girosRestantes = perfilUsuarioState.usuario?.premios?.girosRestantes ?? 0
                    let enabled = !premiosViewModel.girarRuleta && girosRestantes > 0
                    
                    Button(action: {
                        if enabled {
                            Task {
                                perfilUsuarioState.restarGirosRuleta()
                                await premiosViewModel.obtenerResultadoGirarRuleta()
                                premiosViewModel.onGirarRuletaChange(valor: true)
                            }
                        }
                    }) {
                        Text("Girar")
                            .font(.custom("Barlow", size: 18))
                            .bold()
                            .frame(width: 250, height: 40)
                            .background(enabled ? Color.verdePrincipal : Color.grisSurface)
                            .foregroundColor(enabled ? Color.blanco : Color.grisSecundario)
                            .cornerRadius(24)
                    }
                    .disabled(!enabled)
                    
                    Spacer().frame(height: 16)
                    Divider()
                    Spacer().frame(height: 16)
                    
                    ListaPremios(premiosViewModel: premiosViewModel)
                        .padding(.bottom, 20)
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.blanco)
            .disabled(mostrarPopUpResultado)
            
            if mostrarPopUpResultado {
                // Fondo oscuro semitransparente
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Opcional: cerrar al tocar fuera
                        withAnimation { mostrarPopUpResultado = false }
                    }
                
                // Tu componente de diálogo
                DialogoResultadoGirarRuleta(
                    mostrarPopUpResultado: $mostrarPopUpResultado,
                    resultado: premiosViewModel.resultadoGirarRuleta
                )
                .transition(.scale.combined(with: .opacity)) // Animación de entrada
                .zIndex(1) // Asegura que esté por encima de todo
            }
        }
        .onAppear {
            Task {
                await premiosViewModel.refresh()
                prepararSegmentos()
            }   
        }
    }
    
    private func prepararSegmentos() {
        let base = Array(repeating: "GANASTE", count: 7) + Array(repeating: "SIGUE_INTENTANDO", count: 3)
        self.segmentos = base.shuffled()
    }
}

struct FranjaSuperior: View {
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    
    var body: some View {
        HStack(alignment: .top) {
            // Círculo con el número de giros restantes
            Text("\(perfilUsuarioState.usuario?.premios?.girosRestantes ?? 0)")
                .font(.custom("Barlow", size: 20))
                .bold()
                .foregroundColor(Color.naranjaIntentosRestantes)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.blanco)
                )
                .overlay(
                    Circle()
                        .stroke(Color.naranjaIntentosRestantes, lineWidth: 3)
                )
            
            Spacer()
        }
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
    }
}

struct RuletaPremios: View {
    let segmentos: [String]
    let girar: Bool
    let resultado: Premio?
    var onTerminoGiro: () -> Void
    
    @State private var anguloRotacion: Double = 0
    
    private var desfaseInicial: Double {
        let gradosPorSegmento = 360.0 / Double(segmentos.count)
        return -(gradosPorSegmento / 2)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Canvas { context, size in
                _ = CGRect(origin: .zero, size: size)
                let radius = min(size.width, size.height) / 2
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let angleStep = 360.0 / Double(segmentos.count)
                
                for (i, _) in segmentos.enumerated() {
                    
                    let startAngle = Double(i) * angleStep + desfaseInicial
                    let endAngle = Double(i + 1) * angleStep + desfaseInicial
                    
                    // Dibujar Arco
                    var path = Path()
                    path.move(to: center)
                    path.addArc(center: center, radius: radius,
                                startAngle: .degrees(startAngle),
                                endAngle: .degrees(endAngle),
                                clockwise: false)
                    
                    context.fill(path, with: .color(i % 2 == 0 ? Color.verdePrincipal : Color.grisSurface))
                    
                    // Dibujar Personajes (Simplificado)
                    let midAngle = (startAngle + angleStep / 2) * .pi / 180
                    let x = center.x + cos(midAngle) * radius * 0.65
                    let y = center.y + sin(midAngle) * radius * 0.65
                    
                    if let image = context.resolveSymbol(id: i) {
                        // Creamos una copia del contexto para no afectar a los demás elementos
                        var iconContext = context
                        
                        // Movemos el origen al punto donde irá la imagen
                        iconContext.translateBy(x: x, y: y)
                        
                        // Rotamos el contexto en sentido contrario a la ruleta
                        // Usamos -anguloRotacion para que siempre mire al frente
                        iconContext.rotate(by: .degrees(-anguloRotacion))
                        
                        // Dibujamos la imagen en el nuevo centro (0,0 del iconContext)
                        iconContext.draw(image, at: .zero)
                    }
                }
            } symbols: {
                ForEach(0..<segmentos.count, id: \.self) { i in
                    Image(segmentos[i] == "GANASTE" ? "personaje_con_premio" : "personaje_sin_premio")
                        .resizable()
                        .frame(width: 45, height: 45)
                        .tag(i)
                }
            }
            .frame(width: 280, height: 280)
            .rotationEffect(.degrees(anguloRotacion))
            .overlay(
                Circle()
                    .stroke(Color.negro, lineWidth: 2)
            )
            
            // Indicador Fijo
            Image("icono_indicador_ruleta")
                .resizable()
                .frame(width: 45, height: 45)
                .offset(x: 20)
        }
        .onChange(of: girar) { oldValue, newValue in
            if newValue {
                ejecutarAnimacionGiro()
            }
        }
    }
    
    private func ejecutarAnimacionGiro() {
        // 1. Reset instantáneo (Esto limpia el acumulado de grados pero mantiene la posición visual)
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            let current = anguloRotacion.truncatingRemainder(dividingBy: 360)
            anguloRotacion = current < 0 ? current + 360 : current
        }

        // 2. Selección del destino
        let tipoBuscado = (resultado != nil) ? "GANASTE" : "SIGUE_INTENTANDO"
        let indicesPosibles = segmentos.enumerated()
            .filter { $0.element == tipoBuscado }
            .map { $0.offset }
        
        guard let indiceDestino = indicesPosibles.randomElement() else { return }
        
        print("Segmentos :  \(segmentos)")
        print("Indices Posibles : \(indicesPosibles)")
        print("Indice Destino : \(indiceDestino)")
        
        let gradosPorSegmento = 360.0 / Double(segmentos.count)
        
        // 3. CÁLCULO ABSOLUTO
        // La meta es llegar a: (360 - angulo del segmento)
        let anguloMeta = Double(indiceDestino) * gradosPorSegmento
        let desplazamientoNecesario = 360.0 - anguloMeta
        
        // Importante: Las vueltas extras se calculan sobre el ángulo base (0)
        let vueltasExtras = Double.random(in: 5...10).rounded() * 360
        
        // 4. ANIMACIÓN
        DispatchQueue.main.async {
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 3.8)) {
                // USAMOS "=" EN LUGAR DE "+="
                // Esto obliga a la ruleta a ir desde su posición actual (0-360)
                // hasta el nuevo valor total calculado.
                anguloRotacion = vueltasExtras + desplazamientoNecesario
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.8) {
            onTerminoGiro()
        }
    }
}


struct ListaPremios: View {
    @ObservedObject var premiosViewModel: PremiosViewModel
    @EnvironmentObject var perfilUsuarioState: PerfilUsuarioState
    @EnvironmentObject var carritoViewModel: CarritoViewModel
    
    @State private var mostrarAlertaError = false

    var body: some View {
        let listaFiltrada = (perfilUsuarioState.usuario?.premios?.historialPremios ?? [])
            .filter { $0.localidad == perfilUsuarioState.ciudadSeleccionada }
            .reversed()
        
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(listaFiltrada, id: \.idInterno) { premio in
                    HStack(alignment: .top) {
                        // Imagen Logo (con URL base)
                        AsyncImage(url: URL(string: API.baseURL + "/" + premio.logoComercioURL)) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(width: 65, height: 65)
                        .cornerRadius(12)
                        .clipped()
                        
                        PremioDescripcion(premio: premio)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.grisSurface)
                    .cornerRadius(12)
                    .onTapGesture {
                        if carritoViewModel.existePremioEnCarrito(idInterno: premio.idInterno) {
                            mostrarAlertaError = true
                        } else if EstadoPremio.desdeString(premio.estado) == .asignado {
                            premiosViewModel.seleccionarPremio(premio: premio)
                        }
                    }
                }
            }
        }
        .alert("Premio utilizado", isPresented: $mostrarAlertaError) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text("El premio seleccionado ya se encuentra en el carrito")
        }
        // 4. Llamada al Sheet de Selección de Producto
        .sheet(item: $premiosViewModel.premioSeleccionado) { premio in
            SeleccionProductoView(
                premiosViewModel: premiosViewModel,
                premio: premio
            )
        }
        .onDisappear(){
            premiosViewModel.limpiarPremioSeleccionado()
            premiosViewModel.limpiarProductoSeleccionado()
        }
    }
}

struct SeleccionProductoView: View {
    @ObservedObject var premiosViewModel: PremiosViewModel
    let premio: Premio
    
    var body: some View {
        VStack {
            if let producto = premiosViewModel.productoSeleccionado,
               let categoria = premiosViewModel.categoria,
               let comercio = premiosViewModel.comercio {
                
                BottomSheetSeleccionProducto(
                    producto: producto,
                    categoria: categoria,
                    comercio: comercio,
                    onClose: {
                        premiosViewModel.limpiarPremioSeleccionado()
                        premiosViewModel.limpiarProductoSeleccionado()
                    }
                )
            }
        }
        .onAppear {
            Task{
                await premiosViewModel.inicializarProductoSeleccionado(
                    idComercio: premio.idComercio,
                    idProducto: premio.idProducto,
                    idPremio: premio.idInterno
                )
            }
        }
    }
}

struct PremioDescripcion: View {
    let premio: Premio
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Nombre del Producto
            Text(premio.nombreProducto)
                .font(.custom("Barlow", size: 16))
                .bold()
                .foregroundColor(.negro)
            
            // Fecha de Asignación
            Text("Ganado : \(DateUtils.fechaSinSegundos(premio.fechaAsignacion))")
                .font(.custom("Barlow", size: 14))
                .foregroundColor(.negro)
            
            // Fecha de Utilización (Conditional)
            if let fechaUti = premio.fechaUtilizacion, !fechaUti.isEmpty {
                Text("Utilizado : \(DateUtils.fechaSinSegundos(fechaUti))")
                    .font(.custom("Barlow", size: 14))
                    .foregroundColor(.negro)
            }
            // Estado del Premio
            Text(PremiosHelper.obtenerEstadoPremio(premio.estado))
                .font(.custom("Barlow", size: 14))
                .bold()
                .foregroundColor(PremiosHelper.obtenerColorEstadoPremio(premio.estado) ?? .primary)
        }
    }
}

struct DialogoResultadoGirarRuleta: View {
    @Binding var mostrarPopUpResultado: Bool
    let resultado: Premio?
    
    var body: some View {
        ZStack {
            // Fondo semitransparente detrás del diálogo
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture { mostrarPopUpResultado = false }

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .center, spacing: 12) {
                        
                        if resultado == nil {
                            // --- CASO: SIN PREMIO ---
                            Image("personaje_sin_premio_grande")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200)

                            TextStrokeView(text: "Suerte la Próxima", color: Color.verdePrincipal)
                            
                        } else {
                            // --- CASO: CON PREMIO ---
                            Image("personaje_con_premio_grande")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200)

                            TextStrokeView(text: "Ganaste un Premio", color: Color.verdePrincipal)

                            Divider()

                            Text(resultado?.nombreProducto ?? "")
                                .font(.custom("Barlow", size: 20))
                                .bold()
                                .foregroundColor(.negro)
                                .multilineTextAlignment(.center)

                            // Imagen del Producto
                            AsyncImage(url: URL(string: API.baseURL + "/" + (resultado?.imagenProductoURL ?? ""))) { image in
                                image.resizable()
                                     .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 100, height: 100)
                            .cornerRadius(12)
                            .clipped()

                            Text("Cortesía de \(resultado?.nombreComercio ?? "")")
                                .font(.custom("Barlow", size: 20))
                                .bold()
                                .foregroundColor(.negro)
                        }
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: resultado != nil ? UIScreen.main.bounds.height * 0.60 : UIScreen.main.bounds.height * 0.40)
            .background(Color.blanco)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// Componente auxiliar para el texto con contorno (Stroke)
struct TextStrokeView: View {
    let text: String
    let color: Color
    
    // Definimos los puntos de offset de forma clara
    private let offsets: [CGPoint] = [
        CGPoint(x: -1.5, y: -1.5),
        CGPoint(x: 1.5, y: -1.5),
        CGPoint(x: -1.5, y: 1.5),
        CGPoint(x: 1.5, y: 1.5)
    ]
    
    var body: some View {
        ZStack {
            // Usamos el rango de índices (0, 1, 2, 3) para garantizar IDs únicos
            ForEach(0..<offsets.count, id: \.self) { index in
                Text(text)
                    .font(.custom("Barlow", size: 40))
                    .bold()
                    .foregroundColor(.negro)
                    .offset(x: offsets[index].x, y: offsets[index].y)
            }
            
            // Texto principal
            Text(text)
                .font(.custom("Barlow", size: 40))
                .bold()
                .foregroundColor(color)
        }
        .multilineTextAlignment(.center)
    }
}
