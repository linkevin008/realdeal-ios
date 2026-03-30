import Foundation
import Combine
import AuthenticationServices
import CryptoKit

/// ViewModel managing authentication state and user interactions
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var error: AppError?
    
    // Login form
    @Published var loginEmail: String = ""
    @Published var loginPassword: String = ""
    
    // Registration form
    @Published var registerName: String = ""
    @Published var registerEmail: String = ""
    @Published var registerPassword: String = ""
    @Published var registerConfirmPassword: String = ""
    @Published var registerPhoneNumber: String = ""
    @Published var registerRole: UserRole = .buyer
    @Published var registerLicenseNumber: String = ""

    // Validation
    @Published var emailValidationError: String?
    @Published var passwordValidationError: String?
    @Published var nameValidationError: String?
    @Published var confirmPasswordError: String?
    @Published var licenseNumberValidationError: String?
    
    // MARK: - Properties
    
    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(authService: AuthenticationServiceProtocol) {
        self.authService = authService

        // Initialize with current user if available
        self.currentUser = authService.currentUser
        self.isAuthenticated = authService.currentUser != nil

        // Set up validation
        setupValidation()
    }

    /// Call on app launch to repopulate auth state from a saved Keychain token.
    func restoreSessionIfNeeded() async {
        guard !isAuthenticated else { return }
        if let service = authService as? AuthenticationService {
            await service.restoreSession()
        }
        currentUser = authService.currentUser
        isAuthenticated = authService.currentUser != nil
    }
    
    // MARK: - Validation Setup
    
    private func setupValidation() {
        // Email validation
        $registerEmail
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] email in
                guard let self = self, !email.isEmpty else {
                    self?.emailValidationError = nil
                    return
                }
                
                if !Validator.isValidEmail(email) {
                    self.emailValidationError = "Please enter a valid email address"
                } else {
                    self.emailValidationError = nil
                }
            }
            .store(in: &cancellables)
        
        // Password validation
        $registerPassword
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] password in
                guard let self = self, !password.isEmpty else {
                    self?.passwordValidationError = nil
                    return
                }
                
                self.passwordValidationError = Validator.passwordValidationMessage(password)
            }
            .store(in: &cancellables)
        
        // Confirm password validation
        Publishers.CombineLatest($registerPassword, $registerConfirmPassword)
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] password, confirmPassword in
                guard let self = self, !confirmPassword.isEmpty else {
                    self?.confirmPasswordError = nil
                    return
                }
                
                if password != confirmPassword {
                    self.confirmPasswordError = "Passwords do not match"
                } else {
                    self.confirmPasswordError = nil
                }
            }
            .store(in: &cancellables)
        
        // Name validation
        $registerName
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self = self, !name.isEmpty else {
                    self?.nameValidationError = nil
                    return
                }
                
                if name.trimmingCharacters(in: .whitespaces).isEmpty {
                    self.nameValidationError = "Name cannot be empty"
                } else {
                    self.nameValidationError = nil
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    /// Sign in with email and password
    func signIn() async {
        isLoading = true
        errorMessage = nil
        error = nil
        
        do {
            // Use retry logic for authentication
            _ = try await RetryExecutor.execute(policy: .conservative) {
                try await self.authService.signIn(email: self.loginEmail, password: self.loginPassword)
            }
            
            // Update state
            currentUser = authService.currentUser
            isAuthenticated = true
            
            // Clear form
            loginEmail = ""
            loginPassword = ""
        } catch let appError as AppError {
            error = appError
            errorMessage = appError.userMessage
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            self.error = appError
            errorMessage = appError.userMessage
        }
        
        isLoading = false
    }
    
    /// Retry last sign in attempt
    func retrySignIn() async {
        await signIn()
    }
    
    /// Register new user account
    func signUp() async {
        isLoading = true
        errorMessage = nil
        error = nil
        
        // Validate all fields
        guard validateRegistrationForm() else {
            isLoading = false
            return
        }
        
        do {
            let profile = UserProfile(
                name: registerName,
                email: registerEmail,
                phoneNumber: registerPhoneNumber.isEmpty ? nil : registerPhoneNumber,
                role: registerRole,
                licenseNumber: registerRole == .agent ? registerLicenseNumber : nil,
                visibilitySettings: ProfileVisibility()
            )
            
            // Use retry logic for registration
            _ = try await RetryExecutor.execute(policy: .conservative) {
                try await self.authService.signUp(
                    email: self.registerEmail,
                    password: self.registerPassword,
                    profile: profile
                )
            }
            
            // Update state
            currentUser = authService.currentUser
            isAuthenticated = true
            
            // Clear form
            clearRegistrationForm()
        } catch let appError as AppError {
            error = appError
            errorMessage = appError.userMessage
        } catch {
            let appError = AppError.unknown(error.localizedDescription)
            self.error = appError
            errorMessage = appError.userMessage
        }
        
        isLoading = false
    }
    
    /// Retry last sign up attempt
    func retrySignUp() async {
        await signUp()
    }
    
    // MARK: - Social Sign In

    /// Nonce used for the current Apple Sign In request (stored so it can be verified)
    private(set) var currentNonce: String?

    /// Generate a random nonce and store it for verification
    func prepareAppleSignIn() -> String {
        let nonce = randomNonce()
        currentNonce = nonce
        return sha256(nonce)
    }

    /// Complete Apple Sign In after receiving the authorization credential
    func handleAppleSignIn(result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        error = nil

        switch result {
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let identityToken = String(data: tokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Apple Sign In failed — invalid credential"
                isLoading = false
                return
            }

            let fullName: String? = {
                guard let name = credential.fullName else { return nil }
                return [name.givenName, name.familyName].compactMap { $0 }.joined(separator: " ")
            }()

            do {
                _ = try await authService.signInWithApple(
                    identityToken: identityToken,
                    nonce: nonce,
                    fullName: fullName,
                    email: credential.email
                )
                currentUser = authService.currentUser
                isAuthenticated = true
            } catch let appError as AppError {
                error = appError
                errorMessage = appError.userMessage
            } catch {
                errorMessage = error.localizedDescription
            }

        case .failure(let err):
            // ASAuthorizationError.canceled (1001) means the user tapped cancel — not an error
            if (err as? ASAuthorizationError)?.code != .canceled {
                errorMessage = err.localizedDescription
            }
        }

        isLoading = false
        currentNonce = nil
    }

    /// Sign in with a Google ID token (call after receiving the token from GoogleSignIn SDK)
    func handleGoogleSignIn(idToken: String) async {
        isLoading = true
        errorMessage = nil
        error = nil

        do {
            _ = try await authService.signInWithGoogle(idToken: idToken)
            currentUser = authService.currentUser
            isAuthenticated = true
        } catch let appError as AppError {
            error = appError
            errorMessage = appError.userMessage
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Nonce helpers (required by Apple Sign In spec)

    private func randomNonce(length: Int = 32) -> String {
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        precondition(errorCode == errSecSuccess, "Unable to generate nonce")
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// Sign out current user
    func signOut() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await authService.signOut()
            
            // Update state
            currentUser = nil
            isAuthenticated = false
            
            // Clear forms
            loginEmail = ""
            loginPassword = ""
            clearRegistrationForm()
        } catch {
            errorMessage = "Failed to sign out. Please try again."
        }
        
        isLoading = false
    }
    
    // MARK: - Form Validation
    
    private func validateRegistrationForm() -> Bool {
        var isValid = true
        
        // Name validation
        if registerName.trimmingCharacters(in: .whitespaces).isEmpty {
            nameValidationError = "Name is required"
            isValid = false
        }
        
        // Email validation
        if registerEmail.isEmpty {
            emailValidationError = "Email is required"
            isValid = false
        } else if !Validator.isValidEmail(registerEmail) {
            emailValidationError = "Please enter a valid email address"
            isValid = false
        }
        
        // Password validation
        if registerPassword.isEmpty {
            passwordValidationError = "Password is required"
            isValid = false
        } else if let error = Validator.passwordValidationMessage(registerPassword) {
            passwordValidationError = error
            isValid = false
        }
        
        // Confirm password validation
        if registerPassword != registerConfirmPassword {
            confirmPasswordError = "Passwords do not match"
            isValid = false
        }

        return isValid
    }
    
    private func clearRegistrationForm() {
        registerName = ""
        registerEmail = ""
        registerPassword = ""
        registerConfirmPassword = ""
        registerPhoneNumber = ""
        registerRole = .buyer
        registerLicenseNumber = ""

        nameValidationError = nil
        emailValidationError = nil
        passwordValidationError = nil
        confirmPasswordError = nil
        licenseNumberValidationError = nil
    }
    
    // MARK: - Computed Properties
    
    var canSignIn: Bool {
        !loginEmail.isEmpty && !loginPassword.isEmpty && !isLoading
    }
    
    var canSignUp: Bool {
        !registerName.isEmpty &&
        !registerEmail.isEmpty &&
        !registerPassword.isEmpty &&
        !registerConfirmPassword.isEmpty &&
        emailValidationError == nil &&
        passwordValidationError == nil &&
        confirmPasswordError == nil &&
        nameValidationError == nil &&
        !isLoading
    }
}
