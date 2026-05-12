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

            if let (data, _) = try? await URLSession.shared.data(from: url),
               let loaded = UIImage(data: data) {
                ImageCache.shared.set(loaded, for: url)
                uiImage = loaded
            } else if let fallbackURL {
                if let cached = ImageCache.shared.get(fallbackURL) {
                    uiImage = cached
                    return
                }
                guard let (data, _) = try? await URLSession.shared.data(from: fallbackURL),
                      let loaded = UIImage(data: data) else { return }
                ImageCache.shared.set(loaded, for: fallbackURL)
                uiImage = loaded
            }
        }
    }
}

private final class ImageCache {
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
        let cost = image.jpegData(compressionQuality: 1)?.count ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }

    func clearAll() {
        cache.removeAllObjects()
    }
}
