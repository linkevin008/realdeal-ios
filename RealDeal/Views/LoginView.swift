import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var showRegistration = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo/Header
                    VStack(spacing: 8) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)
                        
                        Text("RealDeal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Find your perfect property")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 4) {
                            TextField("Email", text: $viewModel.loginEmail)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)
                                #endif
                                .disabled(viewModel.isLoading)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Password", text: $viewModel.loginPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                #if os(iOS)
                                .textContentType(.password)
                                #endif
                                .disabled(viewModel.isLoading)
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Sign In Button
                        Button(action: {
                            Task {
                                await viewModel.signIn()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel.canSignIn ? Color.blue : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(!viewModel.canSignIn)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                            
                            Text("or")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical, 8)
                        
                        // Sign Up Button
                        Button(action: {
                            showRegistration = true
                        }) {
                            Text("Create New Account")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.clear)
                                .foregroundColor(.blue)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue, lineWidth: 2)
                                )
                        }
                        .disabled(viewModel.isLoading)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            #if os(iOS)
            .navigationBarHidden(true)
            #endif
            .sheet(isPresented: $showRegistration) {
                RegistrationView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct LoginView_Previews: PreviewProvider {
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
        
        return LoginView(viewModel: viewModel)
    }
}
