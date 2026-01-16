import SwiftUI
internal import Realtime

struct InfoCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(10)
    }
}

struct AppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .font(.title3)
                    .foregroundColor(.accentColor)

                Spacer()

                Text(appointment.appointmentStatus.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(appointment.appointmentStatus.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appointment.appointmentStatus.color.opacity(0.15))
                    .cornerRadius(6)
            }

            Text("Dr. \(appointment.doctorName)")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            // Date & Time
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(appointment.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let slot = appointment.timeSlot {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(slot.timeRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .frame(width: 200, height: 160)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(14)
        }
    }
}

// MARK: - Dashboard View
struct PatientDashboardView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var viewModel = PatientViewModel()
    @State private var selectedTab = 0
    @State private var authUserId: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PatientHomeTabView(viewModel: viewModel, selectedTab: $selectedTab)
                    .environmentObject(authVM)
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            
            NavigationStack {
                PrescriptionsListView(patientId: viewModel.patient?.id ?? UUID())
            }
            .tabItem {
                Label("Prescriptions", systemImage: "pills.fill")
            }
            .tag(1)
            
            NavigationStack {
                if let userId = authUserId {
                    MedicalReportsScene(userId: userId)
                } else {
                    ProgressView()
                }
            }
            .tabItem {
                Label("Records", systemImage: "doc.text.fill")
            }
            .tag(2)
            
            NavigationStack {
                PaymentHistoryView(patientName: viewModel.name)
            }
            .tabItem {
                Label("Bills", systemImage: "creditcard.fill")
            }
            .tag(3)
        }
        .accentColor(.blue)
        .task {
            self.authUserId = await authVM.currentUserId()
            await viewModel.loadDashboardData(authVM: authVM)
        }
    }
}

// MARK: - Home Tab View
struct PatientHomeTabView: View {
    @ObservedObject var viewModel: PatientViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var selectedTab: Int
    
    @State private var showingProfile = false
    @State private var showQROverlay = false
    @State private var navigateToDoctorList = false
    @State private var navigateToPastAppointments = false

    var body: some View {
        NavigationLink(
            destination: DoctorListView(),
            isActive: $navigateToDoctorList
        ) {
            EmptyView()
        }
        
        NavigationLink(
            destination: PastAppointmentsView(patientId: viewModel.patient?.id ?? UUID()),
            isActive: $navigateToPastAppointments
        ) {
            EmptyView()
        }

        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    if !viewModel.upcomingFollowUps.isEmpty {
                        followUpRemindersCarousel
                    }
                    if viewModel.suggestionsVisible && !viewModel.aiSuggestions.isEmpty {
                        aiSuggestionsCard
                    }
                    hospitalIDCard
                    upcomingAppointmentsSection
                    quickActionsSection
                }
                .padding()
            }

            if showQROverlay {
                qrOverlay
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("iHMS")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingProfile = true
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            NavigationStack {
                PatientProfileView(viewModel: viewModel)
                    .environmentObject(authVM)
            }
        }
    }

    // MARK: - Follow-up Reminders Carousel
    private var followUpRemindersCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Follow-up Reminders")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            TabView {
                ForEach(viewModel.upcomingFollowUps) { prescription in
                    NavigationLink(destination: destinationForFollowUp(prescription)) {
                        FollowUpReminderCard(prescription: prescription)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 100)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
    
    @ViewBuilder
    private func destinationForFollowUp(_ prescription: Prescription) -> some View {
        if let staff = prescription.staff {
            BookAppointmentView(selectedDoctor: staff)
        } else {
            DoctorListView()
        }
    }
    
    // MARK: - AI Suggestions Card
    private var aiSuggestionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text("Recommended For You")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    withAnimation {
                        viewModel.dismissSuggestions()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            TabView {
                ForEach(viewModel.aiSuggestions) { suggestion in
                    NavigationLink {
                        if let staff = findStaff(byId: suggestion.staffId) {
                            BookAppointmentView(selectedDoctor: staff)
                        } else {
                            DoctorListView()
                        }
                    } label: {
                        DashboardAISuggestionCard(suggestion: suggestion)
                            .padding(.bottom, 20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(height: 110)
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
    
    private func findStaff(byId id: UUID) -> Staff? {
        return viewModel.findStaff(byId: id)
    }

    // MARK: - Hospital Card
    private var hospitalIDCard: some View {
        VStack(alignment: .leading, spacing: 18) {

            Text("Digital Patient Card")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    HStack(spacing: 10) {
                        infoPill("Age", "\(viewModel.age)")
                        infoPill("Gender", viewModel.gender)
                        infoPill("Blood", viewModel.bloodGroup)
                    }
                }

                Spacer()

                QRCodeView(data: viewModel.qrCodeData)
                    .frame(width: 90, height: 90)
                    .onTapGesture {
                        showQROverlay = true
                    }
            }

            Text("Scan this QR at hospital reception")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(22)
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Appointments
    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Upcoming Appointments")

            if viewModel.appointments.isEmpty {
                Text("No upcoming appointments")
                    .foregroundColor(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.appointments) { appointment in
                            NavigationLink(destination: AppointmentDestinationView(appointment: appointment)) {
                                AppointmentCard(appointment: appointment)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Quick Actions")

            VStack(spacing: 12) {
                QuickActionCard(
                    icon: "calendar.badge.plus",
                    title: "Book Appointment",
                    subtitle: "Schedule a doctor visit",
                    tint: .blue
                ) {
                    navigateToDoctorList = true
                }

                QuickActionCard(
                    icon: "clock.arrow.circlepath",
                    title: "Past Appointments",
                    subtitle: "View appointment history",
                    tint: .blue
                ){
                    navigateToPastAppointments = true
                }
            }
        }
    }

    private var qrOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { showQROverlay = false }

            QRCodeView(data: viewModel.qrCodeData)
                .frame(width: 260, height: 260)
                .padding()
                .background(Color(white: 0.12))
                .cornerRadius(26)
        }
    }

    private func infoPill(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
}

// MARK: - Preview
struct PatientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDashboardView()
    }
}

// MARK: - Follow-up Reminder Card
struct FollowUpReminderCard: View {
    let prescription: Prescription
    
    private var formattedFollowUpDate: String {
        guard let dateString = prescription.followUpDate else { return "N/A" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return dateString }
        
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private var daysUntil: Int? {
        guard let dateString = prescription.followUpDate else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let followUpDate = formatter.date(from: dateString) else { return nil }
        
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: Date(), to: followUpDate).day
        return days
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("Follow-up with Dr. \(prescription.staff?.fullName ?? "Doctor")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    Text(formattedFollowUpDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let days = daysUntil {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if days == 0 {
                            Text("Today")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        } else if days == 1 {
                            Text("Tomorrow")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.accentColor)
                        } else if days > 1 {
                            Text("in \(days) days")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Dashboard AI Suggestion Card
struct DashboardAISuggestionCard: View {
    let suggestion: PatientViewModel.AISlotSuggestion
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: suggestion.date) else { return suggestion.date }
        
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: suggestion.reason.contains("preferred") ? "star.fill" : "calendar")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 6) {
                    Text(suggestion.staffName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    // Date on first line
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11))
                        Text(formattedDate)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    // Time on second line
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(suggestion.timeRange)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Badge
                if suggestion.reason.contains("preferred") {
                    VStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                        Text("Preferred")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
