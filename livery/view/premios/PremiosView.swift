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
        VStack(spacing: 0) {
            
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
            
            ListaPremios(premiosViewModel: premiosViewModel)
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.blanco)
        .onAppear {
            Task {
                await premiosViewModel.refresh()
                prepararSegmentos()
            }   
        }
        .sheet(isPresented: $mostrarPopUpResultado) {
            DialogoResultadoGirarRuleta(
                mostrarPopUpResultado: $mostrarPopUpResultado,
                resultado: premiosViewModel.resultadoGirarRuleta
            )
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
            Text("\(perfilUsuarioState.usuario?.premios?.girosRestantes ?? 0)")                .font(.custom("Barlow", size: 20))
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
    
    var body: some View {
        let historial = perfilUsuarioState.usuario?.premios?.historialPremios.reversed() ?? []
        
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(historial, id: \.idInterno) { premio in
                    HStack(alignment: .top) {
                        // Imagen Logo
                        AsyncImage(url: URL(string: API.baseURL + "/" + premio.logoComercioURL)) { img in
                            img.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 65, height: 65)
                        .cornerRadius(12)
                        
                        VStack(alignment: .leading) {
                            Text(premio.nombreProducto)
                                .font(.headline)
                            Text("Ganado: \(premio.fechaAsignacion)")
                                .font(.subheadline)
                            Text(premio.estado)
                                .font(.caption).bold()
                                .foregroundColor(.orange)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .onTapGesture {
                        premiosViewModel.seleccionarPremio(premio: premio)
                    }
                }
            }
            .padding(.bottom, 100)
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
                    VStack(alignment: .center, spacing: 24) {
                        
                        if resultado == nil {
                            // --- CASO: SIN PREMIO ---
                            Image("personaje_sin_premio_grande")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200)

                            TextStrokeView(text: "Suerte la Próxima", color: .blue)
                            
                        } else {
                            // --- CASO: CON PREMIO ---
                            Image("personaje_con_premio_grande")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 200)

                            TextStrokeView(text: "Ganaste un Premio", color: .blue)

                            Divider()
                                .padding(.vertical, 8)

                            Text(resultado?.nombreProducto ?? "")
                                .font(.system(size: 16, weight: .bold))
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
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 32)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.9)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}

// Componente auxiliar para el texto con contorno (Stroke)
struct TextStrokeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        ZStack {
            // Simulación de Stroke mediante 4 offsets (técnica común en SwiftUI)
            ForEach([(-1.5, -1.5), (1.5, -1.5), (-1.5, 1.5), (1.5, 1.5)], id: \.0) { offset in
                Text(text)
                    .font(.system(size: 40, weight: .black))
                    .foregroundColor(.primary) // El color del borde
                    .offset(x: offset.0, y: offset.1)
            }
            
            Text(text)
                .font(.system(size: 40, weight: .black))
                .foregroundColor(color) // El color del relleno
        }
        .multilineTextAlignment(.center)
    }
}
