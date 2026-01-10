import SwiftUI

//struct AppRouter: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//
//    var body: some View {
//        Group {
//            if let role = authVM.userRole {
//                switch role {
//                case .patient:
//                    PatientHomeView()
//
//                case .staff:
//                    StaffDashboardView()
//
//                case .admin:
//                    AdminDashboardView()
//                }
//            } else {
//                ProgressView("Loading...")
//            }
//        }
//    }
//}
//struct AppRouter: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//
//    var body: some View {
//        Group {
//            if let role = authVM.userRole {
//                switch role {
//                case .patient:
//                    PatientHomeView()
//                case .staff:
//                    StaffDashboardView()
//                case .admin:
//                    AdminDashboardView()
//                }
//            } else {
//                AuthContainerView()
//            }
//        }
//    }
//}
//struct AppRouter: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//
//    var body: some View {
//        Group {
//
//            if !authVM.isAuthenticated {
//                AuthContainerView()
//            }
//
//            else if authVM.mustSetPassword && authVM.isAuthenticated {
//                SetPasswordView()
//            }
//
//            else if let role = authVM.userRole {
//                switch role {
//                case .patient:
//                    PatientHomeView()
//                case .staff:
//                    StaffDashboardView()
//                case .admin:
//                    AdminDashboardView()
//                }
//            }
//
//            else {
//                ProgressView("Loading...")
//            }
//        }
//    }
//}
import SwiftUI

struct AppRouter: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {

        if !authVM.isAuthResolved {
            ProgressView("Loading...")
        }
        else if !authVM.isAuthenticated {
            AuthContainerView()
        }

        else if authVM.mustSetPassword {
            SetPasswordView()
        }
        else if let role = authVM.userRole {
            switch role {
            case .patient:
                PatientDashboardView()
            case .staff:
                StaffDashboardView()
            case .admin:
                AdminDashboardView()
            }
        }

        else {
            ProgressView("Loading...")
        }
    }
}
