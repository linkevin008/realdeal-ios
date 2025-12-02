import SwiftUI

/// Skeleton loading view with shimmer animation
@available(iOS 15.0, macOS 12.0, *)
struct SkeletonView: View {
    let width: CGFloat?
    let height: CGFloat
    let cornerRadius: CGFloat
    
    @State private var isAnimating = false
    
    init(width: CGFloat? = nil, height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.black,
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(70))
                    .offset(x: isAnimating ? 200 : -200)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

/// Property card skeleton for loading states
@available(iOS 15.0, macOS 12.0, *)
struct PropertyCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image skeleton
            SkeletonView(height: 200, cornerRadius: 12)
            
            VStack(alignment: .leading, spacing: 8) {
                // Price skeleton
                SkeletonView(width: 120, height: 24, cornerRadius: 6)
                
                // Address skeletons
                SkeletonView(width: 200, height: 16, cornerRadius: 4)
                SkeletonView(width: 160, height: 16, cornerRadius: 4)
                
                // Specifications skeleton
                HStack(spacing: 16) {
                    SkeletonView(width: 60, height: 14, cornerRadius: 4)
                    SkeletonView(width: 60, height: 14, cornerRadius: 4)
                    SkeletonView(width: 80, height: 14, cornerRadius: 4)
                }
                
                // Property type skeleton
                SkeletonView(width: 80, height: 20, cornerRadius: 10)
            }
            .padding(.horizontal, 4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

/// List skeleton for multiple items
@available(iOS 15.0, macOS 12.0, *)
struct PropertyListSkeleton: View {
    let itemCount: Int
    
    init(itemCount: Int = 3) {
        self.itemCount = itemCount
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(0..<itemCount, id: \.self) { _ in
                    PropertyCardSkeleton()
                }
            }
            .padding()
        }
    }
}

/// Profile skeleton for loading states
@available(iOS 15.0, macOS 12.0, *)
struct ProfileSkeleton: View {
    var body: some View {
        VStack(spacing: 24) {
            // Profile photo skeleton
            SkeletonView(width: 120, height: 120, cornerRadius: 60)
            
            VStack(spacing: 16) {
                // Name skeleton
                SkeletonView(width: 150, height: 24, cornerRadius: 6)
                
                // Email skeleton
                SkeletonView(width: 200, height: 16, cornerRadius: 4)
                
                // Phone skeleton
                SkeletonView(width: 140, height: 16, cornerRadius: 4)
                
                // Role skeleton
                SkeletonView(width: 80, height: 16, cornerRadius: 4)
            }
        }
        .padding()
    }
}

/// Map annotation skeleton
@available(iOS 15.0, macOS 12.0, *)
struct MapLoadingSkeleton: View {
    var body: some View {
        ZStack {
            Color.gray.opacity(0.2)
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
                
                Text("Loading properties...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Previews

#Preview("Skeleton View") {
    VStack(spacing: 20) {
        SkeletonView(width: 200, height: 20)
        SkeletonView(width: 150, height: 16)
        SkeletonView(width: 100, height: 12)
    }
    .padding()
}

#Preview("Property Card Skeleton") {
    PropertyCardSkeleton()
        .padding()
}

#Preview("Property List Skeleton") {
    PropertyListSkeleton(itemCount: 2)
}

#Preview("Profile Skeleton") {
    ProfileSkeleton()
}