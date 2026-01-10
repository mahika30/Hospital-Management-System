//
//  AdminSettingsTab.swift
//  iHMS
//
//  Created by Hargun Singh on 06/01/26.
//

import SwiftUI
struct AdminSettingsTab: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {

                Text("Settings")
                    .font(.title2)
                    .bold()

                Spacer()

                Button(role: .destructive) {
                    Task {
                        await authVM.signOut()
                        dismiss()
                    }
                } label: {
                    Text("Logout")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }

            }
        }
    }
}
