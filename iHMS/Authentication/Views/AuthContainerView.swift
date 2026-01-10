//
//  AuthContainerView.swift
//  iHMS
//
//  Created by Hargun Singh on 05/01/26.
//

import SwiftUI

struct AuthContainerView: View {

    @State private var showLogin = true

    var body: some View {
        NavigationStack {
            VStack {
                if showLogin {
                    LoginView(
                        onSwitchToSignup: {
                            showLogin = false
                        }
                    )
                } else {
                    SignupView(
                        onSwitchToLogin: {
                            showLogin = true
                        }
                    )
                }
            }
        }
    }
}
