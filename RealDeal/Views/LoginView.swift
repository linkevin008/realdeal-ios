import SwiftUI
import AuthenticationServices
import GoogleSignIn

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
                        TextField("Email", text: $viewModel.loginEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #if os(iOS)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            #endif
                            .disabled(viewModel.isLoading)

                        // Password Field
                        SecureField("Password", text: $viewModel.loginPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            #if os(iOS)
                            .textContentType(.password)
                            #endif
                            .disabled(viewModel.isLoading)

                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Sign In Button
                        Button(action: {
                            Task { await viewModel.signIn() }
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
                        .disabled(!viewModel.canSignIn || viewModel.isLoading)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                            Text("or").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8)
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical, 4)

                        // Apple Sign In
                        #if os(iOS)
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = viewModel.prepareAppleSignIn()
                        } onCompletion: { result in
                            Task { await viewModel.handleAppleSignIn(result: result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(10)
                        .disabled(viewModel.isLoading)
                        #endif

                        // Google Sign In
                        // NOTE: Requires the GoogleSignIn SDK (SPM: https://github.com/google/GoogleSignIn-iOS).
                        // After adding the package, replace this button with GIDSignInButton or call
                        // GIDSignIn.sharedInstance.signIn(withPresenting:) and pass the resulting idToken
                        // to viewModel.handleGoogleSignIn(idToken:).
                        Button(action: googleSignIn) {
                            HStack(spacing: 12) {
                                Image(systemName: "g.circle.fill")
                                    .foregroundColor(.red)
                                Text("Sign in with Google")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        }
                        .disabled(viewModel.isLoading)

                        // Divider
                        HStack {
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                            Text("new here?").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8)
                            Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.3))
                        }
                        .padding(.vertical, 4)

                        // Sign Up Button
                        Button(action: { showRegistration = true }) {
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

    // MARK: - Google Sign In

    private func googleSignIn() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else { return }
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { result, error in
            guard error == nil, let idToken = result?.user.idToken?.tokenString else { return }
            Task { await viewModel.handleGoogleSignIn(idToken: idToken) }
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
        return LoginView(viewModel: AuthViewModel(authService: authService))
    }
}
