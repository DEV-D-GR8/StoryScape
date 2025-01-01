//
//  LoginView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI
import FirebaseAuth

/// A login/signup screen for Firebase authentication.
struct LoginView: View {
    
    @EnvironmentObject var sessionStore: SessionViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            if isLoading {
                ProgressView()
                    .padding()
            }
            
            Text("Welcome to StoryScape")
                .font(.largeTitle)
                .bold()
                .padding()
            
            TextField("Email", text: $email)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.none)
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.top)
            }
            
            Button(action: {
                login()
            }) {
                Text("Login")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
            
            Button(action: {
                signUp()
            }) {
                Text("Sign Up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(isLoading)
            
            Spacer()
        }
        .padding()
    }
    
    private func login() {
        isLoading = true
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let user = authResult?.user {
                    withAnimation {
                        sessionStore.user = user
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                
                if let user = authResult?.user {
                    withAnimation {
                        sessionStore.user = user
                        dismiss()
                    }
                }
            }
        }
    }
}

#if DEBUG
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
            .environmentObject(SessionViewModel())
    }
}
#endif
