import SwiftUI

/// A SwiftUI view that loads images lazily with caching and placeholder support
@available(iOS 15.0, *)
struct LazyImageView: View {
    
    // MARK: - Properties
    
    let url: URL?
    let placeholder: AnyView?
    let errorView: AnyView?
    let contentMode: ContentMode
    let animation: Animation?
    
    @State private var image: UIImage?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let imageCache = ImageCache.shared
    
    // MARK: - Initializers
    
    init(
        url: URL?,
        contentMode: ContentMode = .fit,
        animation: Animation? = .easeInOut(duration: 0.3),
        @ViewBuilder placeholder: () -> some View = { DefaultPlaceholder() },
        @ViewBuilder errorView: () -> some View = { DefaultErrorView() }
    ) {
        self.url = url
        self.contentMode = contentMode
        self.animation = animation
        self.placeholder = AnyView(placeholder())
        self.errorView = AnyView(errorView())
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity)
            } else if isLoading {
                placeholder
                    .transition(.opacity)
            } else if loadError != nil {
                errorView
                    .transition(.opacity)
            } else {
                placeholder
                    .transition(.opacity)
            }
        }
        .animation(animation, value: image)
        .task(id: url) {
            await loadImage()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadImage() async {
        guard let url = url else {
            await MainActor.run {
                image = nil
                isLoading = false
                loadError = LazyImageError.invalidURL
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            loadError = nil
        }
        
        do {
            // First check cache
            if let cachedImage = await imageCache.image(for: url) {
                await MainActor.run {
                    image = cachedImage
                    isLoading = false
                }
                return
            }
            
            // Download image
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let downloadedImage = UIImage(data: data) else {
                throw LazyImageError.invalidImageData
            }
            
            // Cache the image
            await imageCache.store(image: downloadedImage, for: url)
            
            await MainActor.run {
                image = downloadedImage
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                loadError = error
                isLoading = false
            }
        }
    }
}

// MARK: - Convenience Initializers

@available(iOS 15.0, *)
extension LazyImageView {
    
    /// Initialize with string URL
    init(
        urlString: String?,
        contentMode: ContentMode = .fit,
        animation: Animation? = .easeInOut(duration: 0.3),
        @ViewBuilder placeholder: () -> some View = { DefaultPlaceholder() },
        @ViewBuilder errorView: () -> some View = { DefaultErrorView() }
    ) {
        self.init(
            url: urlString.flatMap(URL.init),
            contentMode: contentMode,
            animation: animation,
            placeholder: placeholder,
            errorView: errorView
        )
    }
    
    /// Initialize with custom placeholder text
    init(
        url: URL?,
        placeholderText: String,
        contentMode: ContentMode = .fit,
        animation: Animation? = .easeInOut(duration: 0.3)
    ) {
        self.init(
            url: url,
            contentMode: contentMode,
            animation: animation,
            placeholder: {
                Text(placeholderText)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.1))
            },
            errorView: {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Failed to load")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray.opacity(0.1))
            }
        )
    }
}

// MARK: - Default Views

@available(iOS 15.0, *)
struct DefaultPlaceholder: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

@available(iOS 15.0, *)
struct DefaultErrorView: View {
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 8) {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Text("Image unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Specialized Image Views

@available(iOS 15.0, *)
struct PropertyImageView: View {
    let url: URL?
    let aspectRatio: CGFloat?
    
    init(url: URL?, aspectRatio: CGFloat? = nil) {
        self.url = url
        self.aspectRatio = aspectRatio
    }
    
    var body: some View {
        LazyImageView(
            url: url,
            contentMode: .fill,
            placeholder: {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "house")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Loading property image...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            },
            errorView: {
                ZStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                    
                    VStack(spacing: 8) {
                        Image(systemName: "house.slash")
                            .font(.title)
                            .foregroundColor(.secondary)
                        
                        Text("Property image unavailable")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        )
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipped()
    }
}

@available(iOS 15.0, *)
struct ProfileImageView: View {
    let url: URL?
    let size: CGFloat
    
    init(url: URL?, size: CGFloat = 60) {
        self.url = url
        self.size = size
    }
    
    var body: some View {
        LazyImageView(
            url: url,
            contentMode: .fill,
            placeholder: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Image(systemName: "person.circle")
                        .font(.system(size: size * 0.6))
                        .foregroundColor(.secondary)
                }
            },
            errorView: {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                    
                    Image(systemName: "person.slash")
                        .font(.system(size: size * 0.6))
                        .foregroundColor(.secondary)
                }
            }
        )
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

// MARK: - Errors

enum LazyImageError: Error, LocalizedError {
    case invalidURL
    case invalidImageData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .invalidImageData:
            return "Invalid image data received"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct LazyImageView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Basic lazy image
            LazyImageView(
                url: URL(string: "https://example.com/image.jpg")
            )
            .frame(height: 200)
            
            // Property image
            PropertyImageView(
                url: URL(string: "https://example.com/property.jpg"),
                aspectRatio: 16/9
            )
            .frame(height: 150)
            
            // Profile image
            ProfileImageView(
                url: URL(string: "https://example.com/profile.jpg"),
                size: 80
            )
            
            // Image gallery - preview disabled due to signature mismatch
            // ImageGalleryView(...)
        }
        .padding()
    }
}