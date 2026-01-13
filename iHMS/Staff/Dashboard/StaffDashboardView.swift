import SwiftUI
import Supabase

struct StaffDashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @State private var staff: Staff?
    @State private var isLoading = true
    @State private var selectedTab = 0
    
    var body: some View {
        if isLoading {
            LoadingView()
                .task {
                    await loadStaffData()
                }
        } else if let staff = staff {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    DashboardHomeView(
                        staff: staff,
                        authVM: authVM,
                        onRefresh: loadStaffData
                    )
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                NavigationStack {
                    ScanPatientView()
                }
                .tabItem {
                    Label("Scan Patient", systemImage: "qrcode.viewfinder")
                }
                .tag(1)
            }
        } else {
            ErrorStateView()
        }
    }
    
    private func loadStaffData() async {
        // Get current user ID from auth
        guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            isLoading = false
            return
        }
        
        do {
            // Fetch staff data from profiles table using user ID
            let response: [Staff] = try await SupabaseManager.shared.client
                .from("staff")
                .select("id, full_name, email, department_id, designation, phone, created_at, specialization, slot_capacity, profile_image, is_active")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            staff = response.first
            if let staff = staff {
                print("✅ Loaded staff: \(staff.fullName)")
                print("   Designation: \(staff.designation ?? "nil")")
                print("   Specialization: \(staff.specialization ?? "nil")")
            }
        } catch {
            print("❌ Error loading staff data: \(error)")
        }
        
        isLoading = false
    }
}

struct DashboardHomeView: View {
    let staff: Staff
    let authVM: AuthViewModel
    let onRefresh: () async -> Void
    
    @State private var admittedCount = 0
    @State private var todayAppointments = 0
    @State private var isLoadingStats = false
    @State private var showProfile = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WelcomeHeader(staff: staff)
                    .padding(.horizontal)
                
                // Quick Stats
                QuickStatsSection(
                    admittedCount: admittedCount,
                    todayAppointments: todayAppointments,
                    isLoading: isLoadingStats,
                    staffId: staff.id
                )
                .padding(.horizontal)
                
                // Quick Actions
                QuickActionsSection(staff: staff)
                    .padding(.horizontal)
                
            }
            .padding(.vertical)
        }
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showProfile = true
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
        }
        .navigationDestination(isPresented: $showProfile) {
            StaffProfileView(staff: staff, isOwner: true)
        }
        .task {
            // Reload stats AND parent staff data when view appears
            await loadStats()
            await onRefresh()
        }
        .refreshable {
            await loadStats()
            await onRefresh()
        }
    }
    
    private func loadStats() async {
        isLoadingStats = true
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)
            let tomorrowString = dateFormatter.string(from: tomorrow)
            
            let completedResponse: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select()
                .eq("staff_id", value: staff.id.uuidString)
                .gte("appointment_date", value: todayString)
                .lt("appointment_date", value: tomorrowString)
                .eq("status", value: "completed")
                .execute()
                .value
            
            admittedCount = completedResponse.count
        } catch {
            print("Error loading completed appointments count: \(error)")
        }
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)
            let tomorrowString = dateFormatter.string(from: tomorrow)
            
            print("📊 Dashboard loading appointments for staff: \(staff.id)")
            print("📊 Date range: \(todayString) to \(tomorrowString)")
            
            let appointmentsResponse: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select()
                .eq("staff_id", value: staff.id.uuidString)
                .gte("appointment_date", value: todayString)
                .lt("appointment_date", value: tomorrowString)
                .execute()
                .value
            
            print("📊 Dashboard found \(appointmentsResponse.count) appointments")
            todayAppointments = appointmentsResponse.count
        } catch {
            print("📊 Dashboard error: \(error)")
            print("Error loading today's appointments: \(error)")
        }
        
        isLoadingStats = false
    }
}
private struct WelcomeHeader: View {
    let staff: Staff
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            if let profileImage = staff.profileImage, !profileImage.isEmpty {
                AsyncImage(url: URL(string: profileImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .overlay {
                            Text(staff.fullName.prefix(1))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Text(staff.fullName.prefix(1))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back,")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundStyle(.gray.opacity(0.8))
                
                Text(staff.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let deptId = staff.departmentId {
                    let departmentName: String = {
                        switch deptId {
                        case "general": return "General Medicine"
                        case "cardiology": return "Cardiology"
                        case "neurology": return "Neurology"
                        case "neurosurgery": return "Neurosurgery"
                        case "orthopedics": return "Orthopedics"
                        case "physiotherapy": return "Physiotherapy"
                        case "sports_medicine": return "Sports Medicine"
                        case "pediatrics": return "Pediatrics"
                        case "neonatology": return "Neonatology"
                        case "gynecology": return "Gynecology"
                        case "obstetrics": return "Obstetrics"
                        case "ent": return "ENT"
                        case "ophthalmology": return "Ophthalmology"
                        case "psychiatry": return "Psychiatry"
                        case "psychology": return "Psychology"
                        case "dermatology": return "Dermatology"
                        case "endocrinology": return "Endocrinology"
                        case "radiology": return "Radiology"
                        case "pathology": return "Pathology"
                        case "laboratory": return "Laboratory Medicine"
                        case "gastroenterology": return "Gastroenterology"
                        case "pulmonology": return "Pulmonology"
                        case "nephrology": return "Nephrology"
                        case "urology": return "Urology"
                        case "general_surgery": return "General Surgery"
                        case "cardiac_surgery": return "Cardiac Surgery"
                        case "plastic_surgery": return "Plastic Surgery"
                        case "emergency": return "Emergency Medicine"
                        case "critical_care": return "Critical Care / ICU"
                        default: return deptId.capitalized
                        }
                    }()
                    
                    HStack(spacing: 6) {
                        Image(systemName: "stethoscope")
                            .font(.caption)
                        Text(departmentName)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                } else if let specialization = staff.specialization {
                    Text(specialization)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

private struct QuickStatsSection: View {
    let admittedCount: Int
    let todayAppointments: Int
    let isLoading: Bool
    let staffId: UUID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Overview")
                .font(.headline)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                HStack(spacing: 12) {
                    NavigationLink {
                        TodayAppointmentsView(staffId: staffId)
                    } label: {
                        StatCard(
                            title: "Today's Appointments",
                            value: "\(todayAppointments)",
                            icon: "calendar",
                            color: .blue
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        CompletedTodayAppointmentsView(staffId: staffId)
                    } label: {
                        StatCard(
                            title: "Completed Today",
                            value: "\(admittedCount)",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct QuickActionsSection: View {
    let staff: Staff
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            VStack(spacing: 12) {
                NavigationLink {
                    ManageAvailabilityView(staff: staff)
                } label: {
                    ActionCard(
                        title: "Manage Availability",
                        subtitle: "Set your working hours and time slots",
                        icon: "calendar",
                        color: .orange
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    PatientSearchView()
                } label: {
                    ActionCard(
                        title: "Patient Records",
                        subtitle: "Search and view patient information",
                        icon: "person.text.rectangle",
                        color: .green
                    )
                }
                .buttonStyle(.plain)
                
                NavigationLink {
                    CompletedAppointmentsView(staffId: staff.id)
                } label: {
                    ActionCard(
                        title: "Completed Appointments",
                        subtitle: "View your appointment history",
                        icon: "checkmark.circle.fill",
                        color: .purple
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(color.opacity(0.2))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray4), lineWidth: 1)
        )
    }
}
private struct ErrorStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Unable to Load Profile")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Please try logging in again")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
