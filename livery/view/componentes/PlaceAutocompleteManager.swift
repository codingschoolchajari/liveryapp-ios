//
//  Untitled.swift
//  livery
//
//  Created by Nicolas Matias Garay on 07/01/2026.
//
import Foundation
import GooglePlaces
import Combine

class PlaceAutocompleteManager: ObservableObject {

    @Published var results: [GMSAutocompletePrediction] = []

    private let client = GMSPlacesClient.shared()
    private let sessionToken = GMSAutocompleteSessionToken()

    func buscarLugares(text: String, cercaDe coordenadas: CLLocationCoordinate2D?) {
        guard text.count >= 2 else {
            results = []
            return
        }

        let filter = GMSAutocompleteFilter()
        filter.types = ["address"]
        filter.countries = ["AR"]
        
        if let coords = coordenadas {
            let norte = CLLocationCoordinate2D(latitude: coords.latitude + 0.15, longitude: coords.longitude + 0.15)
            let sur = CLLocationCoordinate2D(latitude: coords.latitude - 0.15, longitude: coords.longitude - 0.15)
            
            // Rectángulo de búsqueda alrededor de la ubicación actual
            filter.locationRestriction = GMSPlaceRectangularLocationOption(norte, sur)
        }
        
        client.findAutocompletePredictions(
            fromQuery: text,
            filter: filter,
            sessionToken: sessionToken
        ) { predictions, error in
            DispatchQueue.main.async {
                if let predictions = predictions {
                    self.results = predictions
                } else {
                    self.results = []
                    if let error = error {
                        print("❌ Autocomplete error:", error.localizedDescription)
                    }
                }
            }
        }
    }
}




