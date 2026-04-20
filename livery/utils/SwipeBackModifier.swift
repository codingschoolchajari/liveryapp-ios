//
//  SwipeBackModifier.swift
//  livery
//
import SwiftUI
import UIKit

// MARK: - View extension

extension View {
    /// Oculta el botón de "Atrás" de la NavigationBar pero mantiene activo
    /// el gesto de swipe desde el borde izquierdo para volver al stack anterior.
    func navigationBackButtonHiddenWithSwipe() -> some View {
        self
            .navigationBarBackButtonHidden(true)
            .background(SwipeBackEnablerVC())
    }
}

// MARK: - Implementación interna

private struct SwipeBackEnablerVC: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController {
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            // Se retrasa un ciclo de runloop para asegurar que el
            // navigationController ya esté asignado cuando SwiftUI embebe la vista.
            DispatchQueue.main.async { [weak self] in
                self?.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
                self?.navigationController?.interactivePopGestureRecognizer?.delegate = nil
            }
        }
    }
}
