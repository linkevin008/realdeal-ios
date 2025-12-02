import SwiftUI

/// Custom text field style with consistent appearance
@available(iOS 15.0, macOS 12.0, *)
struct RealDealTextFieldStyle: TextFieldStyle {
    let hasError: Bool
    let isDisabled: Bool
    
    init(hasError: Bool = false, isDisabled: Bool = false) {
        self.hasError = hasError
        self.isDisabled = isDisabled
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
                    .stroke(borderColor, lineWidth: 1)
            )
            .foregroundColor(isDisabled ? .gray : .primary)
            .disabled(isDisabled)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.1)
        } else {
            return Color(.systemBackground)
        }
    }
    
    private var borderColor: Color {
        if hasError {
            return Color.red
        } else if isDisabled {
            return Color.gray.opacity(0.3)
        } else {
            return Color.gray.opacity(0.5)
        }
    }
}

/// Form field container with label and error message
@available(iOS 15.0, macOS 12.0, *)
struct FormField<Content: View>: View {
    let label: String
    let isRequired: Bool
    let errorMessage: String?
    let content: Content
    
    init(
        label: String,
        isRequired: Bool = false,
        errorMessage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.isRequired = isRequired
        self.errorMessage = errorMessage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            HStack(spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if isRequired {
                    Text("*")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            
            // Content
            content
            
            // Error message
            if let errorMessage = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
    }
}

/// Segmented picker style
@available(iOS 15.0, macOS 12.0, *)
struct RealDealSegmentedPickerStyle: View {
    let options: [String]
    @Binding var selection: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = index
                    }
                }) {
                    Text(option)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selection == index ? .white : .blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == index ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

/// Toggle switch with custom styling
@available(iOS 15.0, macOS 12.0, *)
struct RealDealToggle: View {
    let label: String
    let description: String?
    @Binding var isOn: Bool
    
    init(label: String, description: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.description = description
        self._isOn = isOn
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

/// Multi-select checkbox group
@available(iOS 15.0, macOS 12.0, *)
struct CheckboxGroup<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: Set<T>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(options.enumerated()), id: \.offset) { _, option in
                CheckboxRow(
                    value: option.0,
                    label: option.1,
                    isSelected: selection.contains(option.0)
                ) { isSelected in
                    if isSelected {
                        selection.insert(option.0)
                    } else {
                        selection.remove(option.0)
                    }
                }
            }
        }
    }
}

/// Individual checkbox row
@available(iOS 15.0, macOS 12.0, *)
struct CheckboxRow<T: Hashable>: View {
    let value: T
    let label: String
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        Button(action: {
            onToggle(!isSelected)
        }) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// Range slider with labels
@available(iOS 15.0, macOS 12.0, *)
struct LabeledSlider: View {
    let label: String
    let range: ClosedRange<Double>
    @Binding var value: Double
    let step: Double
    let formatter: NumberFormatter
    
    init(
        label: String,
        range: ClosedRange<Double>,
        value: Binding<Double>,
        step: Double = 1,
        formatter: NumberFormatter = NumberFormatter()
    ) {
        self.label = label
        self.range = range
        self._value = value
        self.step = step
        self.formatter = formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(formatter.string(from: NSNumber(value: value)) ?? "\(value)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .fontWeight(.medium)
            }
            
            Slider(value: $value, in: range, step: step)
                .tint(.blue)
            
            HStack {
                Text(formatter.string(from: NSNumber(value: range.lowerBound)) ?? "\(range.lowerBound)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formatter.string(from: NSNumber(value: range.upperBound)) ?? "\(range.upperBound)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

/// Form section with header and content
@available(iOS 15.0, macOS 12.0, *)
struct FormSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - View Extensions

@available(iOS 15.0, macOS 12.0, *)
extension View {
    func realDealTextFieldStyle(hasError: Bool = false, isDisabled: Bool = false) -> some View {
        textFieldStyle(RealDealTextFieldStyle(hasError: hasError, isDisabled: isDisabled))
    }
}

// MARK: - Previews

#Preview("Form Styles") {
    ScrollView {
        VStack(spacing: 24) {
            FormSection(title: "Basic Information") {
                VStack(spacing: 16) {
                    FormField(label: "Name", isRequired: true) {
                        TextField("Enter your name", text: .constant(""))
                            .realDealTextFieldStyle()
                    }
                    
                    FormField(label: "Email", isRequired: true, errorMessage: "Please enter a valid email") {
                        TextField("Enter your email", text: .constant(""))
                            .realDealTextFieldStyle(hasError: true)
                    }
                    
                    FormField(label: "Phone") {
                        TextField("Enter your phone", text: .constant(""))
                            .realDealTextFieldStyle()
                    }
                }
            }
            
            FormSection(title: "Preferences") {
                VStack(spacing: 16) {
                    RealDealToggle(
                        label: "Email Notifications",
                        description: "Receive updates about new properties",
                        isOn: .constant(true)
                    )
                    
                    RealDealToggle(
                        label: "SMS Notifications",
                        description: "Get text messages for urgent updates",
                        isOn: .constant(false)
                    )
                }
            }
            
            FormSection(title: "Property Types") {
                CheckboxGroup(
                    options: [
                        ("house", "House"),
                        ("apartment", "Apartment"),
                        ("condo", "Condo")
                    ],
                    selection: .constant(Set(["house", "apartment"]))
                )
            }
        }
        .padding()
    }
}