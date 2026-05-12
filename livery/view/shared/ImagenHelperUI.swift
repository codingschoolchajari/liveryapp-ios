//
//  ImagenHelperUI.swift
//  livery
//
//  Created by Nicolas Matias Garay on 04/01/2026.
//
import SwiftUI
import UIKit

struct ZoomableContainer<Content: View>: UIViewRepresentable {
    private var content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        // Creamos el contenedor de la vista de SwiftUI
        let hostedView = UIHostingController(rootView: content)
        hostedView.view.backgroundColor = .clear
        hostedView.view.translatesAutoresizingMaskIntoConstraints = false

        context.coordinator.hostingController = hostedView

        scrollView.addSubview(hostedView.view)
        
        NSLayoutConstraint.activate([
            hostedView.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostedView.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        return scrollView
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController?.rootView = content
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>?

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.subviews.first
        }
    }
}

struct RemoteImage: View {
    let url: URL?
    var fallbackURL: URL? = nil
    var priority: TaskPriority = .userInitiated

    @State private var uiImage: UIImage? = nil

    var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .task(id: url) {
            uiImage = nil
            guard let url else { return }

            // Revisar caché en memoria primero
            if let cached = ImageCache.shared.get(url) {
                uiImage = cached
                return
            }

            // Descargar y decodificar fuera del main thread
            let loaded = await Task.detached(priority: priority) {
                guard let (data, _) = try? await URLSession.imageSession.data(from: url) else { return UIImage?.none }
                return UIImage(data: data)
            }.value

            if let loaded {
                ImageCache.shared.set(loaded, for: url)
                uiImage = loaded
                return
            }

            // Fallback
            guard let fallbackURL else { return }
            if let cached = ImageCache.shared.get(fallbackURL) {
                uiImage = cached
                return
            }
            let fallback = await Task.detached(priority: priority) {
                guard let (data, _) = try? await URLSession.imageSession.data(from: fallbackURL) else { return UIImage?.none }
                return UIImage(data: data)
            }.value
            if let fallback {
                ImageCache.shared.set(fallback, for: fallbackURL)
                uiImage = fallback
            }
        }
    }
}

private extension URLSession {
    static let imageSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 10
        config.timeoutIntervalForRequest = 15
        config.urlCache = nil // usamos NSCache propio
        return URLSession(configuration: config)
    }()
}

final class ImageCache {
    static let shared = ImageCache()
    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB
    }

    func get(_ url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func set(_ image: UIImage, for url: URL) {
        // Estimar tamaño sin recomprimir: ancho × alto × 4 bytes por pixel
        let cost = Int(image.size.width * image.scale) * Int(image.size.height * image.scale) * 4
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    func clearAll() {
        cache.removeAllObjects()
    }
}
