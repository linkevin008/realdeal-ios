import SwiftUI

/// Reusable favorite button component
@available(iOS 15.0, macOS 12.0, *)
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void
    var size: CGFloat = 24
    
    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: size))
                .foregroundColor(isFavorite ? .red : .gray)
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct FavoriteButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            FavoriteButton(isFavorite: false, action: {})
            FavoriteButton(isFavorite: true, action: {})
            FavoriteButton(isFavorite: false, action: {}, size: 32)
            FavoriteButton(isFavorite: true, action: {}, size: 32)
        }
        .padding()
    }
}
