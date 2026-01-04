//
//  GoogleMapTrackingView.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI
import GoogleMaps

struct GoogleMapTrackingView: UIViewRepresentable {
    let recorrido: Recorrido?
    let coordComercio: CLLocationCoordinate2D
    let coordCliente: CLLocationCoordinate2D
    let tick: Int
    
    func makeUIView(context: Context) -> GMSMapView {
        // 1. Crear las opciones con la cámara inicial
        let options = GMSMapViewOptions()
        options.camera = GMSCameraPosition.camera(withTarget: coordComercio, zoom: 15)
        options.frame = .zero // El frame se ajustará automáticamente por el layout de SwiftUI
        
        // 2. Inicializar el mapa con las opciones
        let map = GMSMapView(options: options)
        
        // 3. Configuraciones adicionales
        map.isMyLocationEnabled = false
        map.settings.myLocationButton = false
        map.settings.zoomGestures = true
        map.settings.scrollGestures = true
        map.settings.rotateGestures = true
        map.settings.tiltGestures = true
        map.overrideUserInterfaceStyle = .light // Opcional, para forzar modo claro
        
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear() // Limpiamos marcadores previos para redibujar
        
        // 1. Dibujar Marcador Comercio
        let markerComercio = GMSMarker(position: coordComercio)
        if let iconoBase = UIImage(named: "icono_ubicacion_comercio") {
            markerComercio.icon = iconoBase
                .resized(to: CGSize(width: 64, height: 64))
                .withTintColor(UIColor(EstadosPedidos.enCamino.color))
        }
        markerComercio.map = mapView
        
        // 2. Dibujar Marcador Cliente
        let markerCliente = GMSMarker(position: coordCliente)
        if let iconoBase = UIImage(named: "icono_ubicacion_cliente") {
            markerCliente.icon = iconoBase
                .resized(to: CGSize(width: 64, height: 64))
                .withTintColor(UIColor(EstadosPedidos.enCamino.color))
        }
        markerCliente.map = mapView
        
        // 3. Dibujar Recorrido (Círculos/Puntos)
        if let coordenadas = recorrido?.coordenadasToCoordinateList() {
            for coord in coordenadas {
                let circle = GMSCircle(position: coord, radius: 15)
                circle.fillColor = UIColor(EstadosPedidos.enCamino.color)
                circle.strokeColor = UIColor(Color.blanco)
                circle.strokeWidth = 2
                circle.map = mapView
            }
            
            // 4. Marcador Repartidor (en la última ubicación)
            if let last = coordenadas.last {
                let markerRepartidor = GMSMarker(position: last)
                if let iconoBase = UIImage(named: "icono_ubicacion_repartidor") {
                    markerRepartidor.icon = iconoBase
                        .resized(to: CGSize(width: 64, height: 64))
                        .withTintColor(UIColor(Color.negro))
                }
                markerRepartidor.map = mapView
                
                // Mover cámara cuando cambia el tick (animado)
                mapView.animate(to: GMSCameraPosition.camera(withTarget: last, zoom: 16))
            }
        }
    }
}

extension UIImage {
    // Función para cambiar tamaño
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // Tu función de color (optimizada)
    func withTintColor(_ color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(.normal)
        let rect = CGRect(origin: .zero, size: self.size)
        context?.clip(to: rect, mask: self.cgImage!)
        color.setFill()
        context?.fill(rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? self
    }
}
