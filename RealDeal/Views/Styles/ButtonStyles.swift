import SwiftUI

/// Primary button style for main actions
@available(iOS 15.0, macOS 12.0, *)
struct PrimaryButtonStyle: ButtonStyle {
    let isLoading: Bool
    let isDisabled: Bool
    
    init(isLoading: Bool = false, isDisabled: Bool = false) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            }
            
            configuration.label
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor(configuration: configuration))
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isDisabled || isLoading)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if isDisabled || isLoading {
            return Color.gray.opacity(0.6)
        } else if configuration.isPressed {
            return Color.blue.opacity(0.8)
        } else {
            return Color.blue
        }
    }
}

/// Secondary button style for less prominent actions
@available(iOS 15.0, macOS 12.0, *)
struct SecondaryButtonStyle: ButtonStyle {
    let isLoading: Bool
    let isDisabled: Bool
    
    init(isLoading: Bool = false, isDisabled: Bool = false) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.blue)
            }
            
            configuration.label
        }
        .font(.headline)
        .foregroundColor(foregroundColor(configuration: configuration))
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor(configuration: configuration), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(backgroundColor(configuration: configuration))
                )
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isDisabled || isLoading)
    }
    
    private func foregroundColor(configuration: Configuration) -> Color {
        if isDisabled || isLoading {
            return Color.gray
        } else {
            return Color.blue
        }
    }
    
    private func borderColor(configuration: Configuration) -> Color {
        if isDisabled || isLoading {
            return Color.gray.opacity(0.6)
        } else if configuration.isPressed {
            return Color.blue.opacity(0.8)
        } else {
            return Color.blue
        }
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if configuration.isPressed {
            return Color.blue.opacity(0.1)
        } else {
            return Color.clear
        }
    }
}

/// Destructive button style for delete actions
@available(iOS 15.0, macOS 12.0, *)
struct DestructiveButtonStyle: ButtonStyle {
    let isLoading: Bool
    let isDisabled: Bool
    
    init(isLoading: Bool = false, isDisabled: Bool = false) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 8) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            }
            
            configuration.label
        }
        .font(.headline)
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor(configuration: configuration))
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isDisabled || isLoading)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if isDisabled || isLoading {
            return Color.gray.opacity(0.6)
        } else if configuration.isPressed {
            return Color.red.opacity(0.8)
        } else {
            return Color.red
        }
    }
}

/// Compact button style for smaller spaces
@available(iOS 15.0, macOS 12.0, *)
struct CompactButtonStyle: ButtonStyle {
    let isLoading: Bool
    let isDisabled: Bool
    
    init(isLoading: Bool = false, isDisabled: Bool = false) {
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .tint(.white)
            }
            
            configuration.label
        }
        .font(.subheadline)
        .fontWeight(.semibold)
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(backgroundColor(configuration: configuration))
        )
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isDisabled || isLoading)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if isDisabled || isLoading {
            return Color.gray.opacity(0.6)
        } else if configuration.isPressed {
            return Color.blue.opacity(0.8)
        } else {
            return Color.blue
        }
    }
}

/// Floating action button style
@available(iOS 15.0, macOS 12.0, *)
struct FloatingActionButtonStyle: ButtonStyle {
    let isLoading: Bool
    
    init(isLoading: Bool = false) {
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
            } else {
                configuration.label
            }
        }
        .font(.title2)
        .foregroundColor(.white)
        .frame(width: 56, height: 56)
        .background(
            Circle()
                .fill(backgroundColor(configuration: configuration))
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: configuration.isPressed ? 2 : 8,
                    x: 0,
                    y: configuration.isPressed ? 1 : 4
                )
        )
        .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
        .disabled(isLoading)
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if isLoading {
            return Color.gray.opacity(0.6)
        } else if configuration.isPressed {
            return Color.blue.opacity(0.8)
        } else {
            return Color.blue
        }
    }
}

/// Icon button style for toolbar and navigation
@available(iOS 15.0, macOS 12.0, *)
struct IconButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.title2)
            .foregroundColor(foregroundColor(configuration: configuration))
            .padding(12)
            .background(
                Circle()
                    .fill(backgroundColor(configuration: configuration))
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: configuration.isPressed ? 1 : 4,
                        x: 0,
                        y: configuration.isPressed ? 0.5 : 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
    
    private func foregroundColor(configuration: Configuration) -> Color {
        if isSelected {
            return .white
        } else {
            return .blue
        }
    }
    
    private func backgroundColor(configuration: Configuration) -> Color {
        if isSelected {
            return .blue
        } else if configuration.isPressed {
            return Color.blue.opacity(0.1)
        } else {
            return Color.white
        }
    }
}

// MARK: - View Extensions

@available(iOS 15.0, macOS 12.0, *)
extension View {
    func primaryButtonStyle(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        buttonStyle(PrimaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }
    
    func secondaryButtonStyle(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        buttonStyle(SecondaryButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }
    
    func destructiveButtonStyle(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        buttonStyle(DestructiveButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }
    
    func compactButtonStyle(isLoading: Bool = false, isDisabled: Bool = false) -> some View {
        buttonStyle(CompactButtonStyle(isLoading: isLoading, isDisabled: isDisabled))
    }
    
    func floatingActionButtonStyle(isLoading: Bool = false) -> some View {
        buttonStyle(FloatingActionButtonStyle(isLoading: isLoading))
    }
    
    func iconButtonStyle(isSelected: Bool = false) -> some View {
        buttonStyle(IconButtonStyle(isSelected: isSelected))
    }
}

// MARK: - Previews

#Preview("Button Styles") {
    VStack(spacing: 20) {
        Button("Primary Button") {}
            .primaryButtonStyle()
        
        Button("Loading Button") {}
            .primaryButtonStyle(isLoading: true)
        
        Button("Disabled Button") {}
            .primaryButtonStyle(isDisabled: true)
        
        Button("Secondary Button") {}
            .secondaryButtonStyle()
        
        Button("Destructive Button") {}
            .destructiveButtonStyle()
        
        Button("Compact Button") {}
            .compactButtonStyle()
        
        HStack(spacing: 20) {
            Button(action: {}) {
                Image(systemName: "plus")
            }
            .floatingActionButtonStyle()
            
            Button(action: {}) {
                Image(systemName: "heart")
            }
            .iconButtonStyle()
            
            Button(action: {}) {
                Image(systemName: "heart.fill")
            }
            .iconButtonStyle(isSelected: true)
        }
    }
    .padding()
}