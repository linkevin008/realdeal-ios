import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct RegistrationView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Join RealDeal to start your property search")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Registration Form
                    VStack(spacing: 16) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Full Name", text: $viewModel.registerName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.name)
                                #endif
                                .disabled(viewModel.isLoading)
                            
                            if let error = viewModel.nameValidationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Email", text: $viewModel.registerEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                #endif
                                .disabled(viewModel.isLoading)
                            
                            if let error = viewModel.emailValidationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Phone Number Field (Optional)
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Phone Number (Optional)", text: $viewModel.registerPhoneNumber)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                                #endif
                                .disabled(viewModel.isLoading)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Password", text: $viewModel.registerPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.newPassword)
                                #endif
                                .disabled(viewModel.isLoading)
                            
                            if let error = viewModel.passwordValidationError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            } else {
                                Text("At least 8 characters with letters and numbers")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Confirm Password", text: $viewModel.registerConfirmPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.newPassword)
                                #endif
                                .disabled(viewModel.isLoading)
                            
                            if let error = viewModel.confirmPasswordError {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Sign Up Button
                        Button(action: {
                            Task {
                                await viewModel.signUp()
                                if viewModel.isAuthenticated {
                                    dismiss()
                                }
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canSignUp ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.canSignUp)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        let mockBackendAuth = MockAuthenticationService(simulateNetworkDelay: false)
        let mockRemote = MockRemoteDataSource(simulateNetworkDelay: false)
        let persistence = PersistenceController(inMemory: true)
        let mockUserRepo = UserProfileRepository(
            localDataSource: LocalDataSource(persistenceController: persistence),
            remoteDataSource: mockRemote
        )
        let authService = AuthenticationService(
            backendAuth: mockBackendAuth,
            userProfileRepository: mockUserRepo
        )
        let viewModel = AuthViewModel(authService: authService)
        
        return RegistrationView(viewModel: viewModel)
    }
}
