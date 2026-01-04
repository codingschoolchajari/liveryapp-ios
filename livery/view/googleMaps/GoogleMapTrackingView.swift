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
        let camera = GMSCameraPosition.camera(withTarget: coordComercio, zoom: 15)
        let map = GMSMapView(frame: .zero, camera: camera)
        map.settings.myLocationButton = true
        map.isMyLocationEnabled = true
        return map
    }

    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear() // Limpiamos marcadores previos para redibujar
        
        // 1. Dibujar Marcador Comercio
        let markerComercio = GMSMarker(position: coordComercio)
        markerComercio.icon = UIImage(named: "icono_ubicacion_comercio")
        markerComercio.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        markerComercio.map = mapView
        
        // 2. Dibujar Marcador Cliente
        let markerCliente = GMSMarker(position: coordCliente)
        markerCliente.icon = UIImage(named: "icono_ubicacion_cliente")
        markerCliente.map = mapView
        
        // 3. Dibujar Recorrido (Círculos/Puntos)
        if let coordenadas = recorrido?.coordenadas {
            for coord in coordenadas {
                let circle = GMSCircle(position: coord.toCLLocationCoordinate2D(), radius: 10)
                circle.fillColor = UIColor.systemGreen.withAlphaComponent(0.5)
                circle.strokeColor = Color.blanco
                circle.strokeWidth = 2
                circle.map = mapView
            }
            
            // 4. Marcador Repartidor (en la última ubicación)
            if let last = coordenadas.last?.toCLLocationCoordinate2D() {
                let markerRepartidor = GMSMarker(position: last)
                markerRepartidor.icon = UIImage(named: "icono_ubicacion_repartidor")
                markerRepartidor.groundAnchor = CGPoint(x: 0.5, y: 0.85)
                markerRepartidor.map = mapView
                
                // Mover cámara cuando cambia el tick (animado)
                mapView.animate(to: GMSCameraPosition.camera(withTarget: last, zoom: 16))
            }
        }
    }
}
