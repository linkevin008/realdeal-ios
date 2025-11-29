import Foundation
import Combine

/// ViewModel managing authentication state and user interactions
@MainActor
@available(iOS 15.0, macOS 12.0, *)
class AuthViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
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
    
    // Validation
    @Published var emailValidationError: String?
    @Published var passwordValidationError: String?
    @Published var nameValidationError: String?
    @Published var confirmPasswordError: String?
    
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
        
        do {
            _ = try await authService.signIn(email: loginEmail, password: loginPassword)
            
            // Update state
            currentUser = authService.currentUser
            isAuthenticated = true
            
            // Clear form
            loginEmail = ""
            loginPassword = ""
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    /// Register new user account
    func signUp() async {
        isLoading = true
        errorMessage = nil
        
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
                visibilitySettings: ProfileVisibility()
            )
            
            _ = try await authService.signUp(
                email: registerEmail,
                password: registerPassword,
                profile: profile
            )
            
            // Update state
            currentUser = authService.currentUser
            isAuthenticated = true
            
            // Clear form
            clearRegistrationForm()
        } catch let error as AppError {
            errorMessage = error.userMessage
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
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
        
        nameValidationError = nil
        emailValidationError = nil
        passwordValidationError = nil
        confirmPasswordError = nil
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
