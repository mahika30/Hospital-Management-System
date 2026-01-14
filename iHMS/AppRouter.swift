//import SwiftUI
//import SwiftUI
//
//struct AppRouter: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//
//    var body: some View {
//
//        if !authVM.isAuthResolved {
//            ProgressView("Loading...")
//        }
//        else if !authVM.isAuthenticated {
//            AuthContainerView()
//        }
//
//        else if authVM.mustSetPassword {
//            SetPasswordView()
//        }
//        else if let role = authVM.userRole {
//            switch role {
//            case .patient:
//                PatientDashboardView()
//            case .staff:
//                StaffDashboardView()
//            case .admin:
//                AdminDashboardView()
//            }
//        }
//
//        else {
//            ProgressView("Loading...")
//        }
//    }
//}
import SwiftUI

struct AppRouter: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            content
        }
        .sheet(isPresented: $authVM.showResetPassword) {
            SetPasswordView(flow: .reset)
                .environmentObject(authVM)
        }
    }

    @ViewBuilder
    private var content: some View {

        if authVM.isInPasswordRecoveryFlow {
            Color.clear
        }
        else if !authVM.isAuthResolved {
            ProgressView("Loading...")
        }
        else if !authVM.isAuthenticated {
            AuthContainerView()
        }
        else if authVM.mustSetPassword {
            SetPasswordView(flow: .onboarding)
        }
        else if let role = authVM.userRole {
            switch role {
            case .patient: PatientDashboardView()
            case .staff: StaffDashboardView()
            case .admin: AdminDashboardView()
            }
        }
    }
}
