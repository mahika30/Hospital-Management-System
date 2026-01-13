import SwiftUI

// MARK: - Date Extensions
extension Date {
    /// Formats date to readable string (e.g., "Jan 15, 2024")
    func formatted() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Formats date with time (e.g., "Jan 15, 2024 at 2:30 PM")
    func formattedWithTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Formats time only (e.g., "2:30 PM")
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
    
    /// Formats time in 24-hour format (e.g., "14:30")
    func time24String() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }
    
    /// Returns day of week (1 = Sunday, 7 = Saturday)
    var dayOfWeek: Int {
        Calendar.current.component(.weekday, from: self)
    }
    
    /// Checks if date is today
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is tomorrow
    var isTomorrow: Bool {
        Calendar.current.isDateInTomorrow(self)
    }
    
    /// Checks if date is in the past
    var isPast: Bool {
        self < Date()
    }
    
    /// Returns relative time string (e.g., "2 hours ago", "in 3 days")
    func relativeTime() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    /// Returns age from date of birth
    func age() -> Int? {
        Calendar.current.dateComponents([.year], from: self, to: Date()).year
    }
    
    /// Start of day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// End of day (11:59:59 PM)
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}

// MARK: - View Extensions
extension View {
    /// Applies a card style with shadow and rounded corners
    func cardStyle() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
    }
    
    /// Applies haptic feedback
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onChange(of: UUID()) { _, _ in
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
        }
    }
    
    /// Triggers haptic feedback manually
    func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Adds a border with rounded corners
    func roundedBorder(color: Color, width: CGFloat = 1, cornerRadius: CGFloat = 8) -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(color, lineWidth: width)
            )
    }
}

// MARK: - Color Extensions
extension Color {
    /// Returns color based on slot status
    static func slotStatusColor(_ status: SlotStatus) -> Color {
        switch status {
        case .available:
            return .green
        case .filling:
            return .orange
        case .full:
            return .red
        case .disabled:
            return .gray
        case .runningLate:
            return .yellow
        }
    }
    
    /// Returns color based on appointment status
    static func appointmentStatusColor(_ status: AppointmentStatus) -> Color {
        switch status {
        case .scheduled:
            return .blue
        case .confirmed:
            return .green
        case .inProgress:
            return .orange
        case .completed:
            return .gray
        case .cancelled:
            return .red
        case .noShow:
            return .orange
        case .rescheduled:
            return .purple
        }
    }
    
    /// Returns color based on admission status
    static func admissionStatusColor(_ status: AdmissionStatus) -> Color {
        switch status {
        case .admitted:
            return .purple
        case .outpatient:
            return .green
        case .discharged:
            return .blue
        case .emergency:
            return .red
        }
    }
    
    /// Custom app colors
    static let primaryAccent = Color.blue
    static let successColor = Color.green
    static let warningColor = Color.orange
    static let errorColor = Color.red
    static let infoColor = Color.blue
}

// MARK: - String Extensions
extension String {
    /// Returns initials from full name (e.g., "John Doe" -> "JD")
    var initials: String {
        let components = self.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.joined()
    }
    
    /// Validates email format
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    /// Validates phone number (basic)
    var isValidPhone: Bool {
        let phoneRegex = "^[+]?[0-9]{10,15}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: self)
    }
    
    /// Formats phone number with dashes (e.g., "1234567890" -> "123-456-7890")
    var formattedPhone: String {
        let digits = self.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard digits.count == 10 else { return self }
        
        let areaCode = digits.prefix(3)
        let prefix = digits.dropFirst(3).prefix(3)
        let suffix = digits.dropFirst(6)
        
        return "\(areaCode)-\(prefix)-\(suffix)"
    }
    
    /// Capitalizes first letter
    var capitalizedFirst: String {
        guard !self.isEmpty else { return self }
        return prefix(1).uppercased() + dropFirst()
    }
}

// MARK: - Array Extensions
extension Array where Element == TimeSlot {
    /// Returns available time slots
    var availableSlots: [TimeSlot] {
        self.filter { ($0.isAvailable ?? false) && !$0.isFull }
    }
    
    /// Returns total booked count
    var totalBookedCount: Int {
        self.reduce(0) { $0 + ($1.currentBookings ?? 0) }
    }
    
    /// Returns total capacity
    var totalCapacity: Int {
        self.reduce(0) { $0 + ($1.maxCapacity ?? 0) }
    }
    
    /// Returns fill percentage
    var fillPercentage: Double {
        let total = totalCapacity
        guard total > 0 else { return 0 }
        return Double(totalBookedCount) / Double(total) * 100
    }
}

extension Array where Element == Patient {
    /// Filters patients by admission status
    func filtered(by status: AdmissionStatus) -> [Patient] {
        self.filter { $0.admissionStatus == status.rawValue }
    }
    
    /// Filters patients by search query
    func searched(query: String) -> [Patient] {
        guard !query.isEmpty else { return self }
        return self.filter { $0.fullSearchText.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - Optional Extensions
extension Optional where Wrapped == String {
    /// Returns empty string if nil
    var orEmpty: String {
        self ?? ""
    }
    
    /// Returns true if nil or empty
    var isNilOrEmpty: Bool {
        self?.isEmpty ?? true
    }
}

// MARK: - Int Extensions
extension Int {
    /// Formats as ordinal (e.g., 1 -> "1st", 2 -> "2nd")
    var ordinal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// Returns pluralized string (e.g., 1 -> "slot", 2 -> "slots")
    func pluralized(_ singular: String, _ plural: String? = nil) -> String {
        if self == 1 {
            return singular
        } else {
            return plural ?? "\(singular)s"
        }
    }
}

// MARK: - Double Extensions
extension Double {
    /// Formats as percentage (e.g., 0.75 -> "75%")
    var asPercentage: String {
        String(format: "%.0f%%", self)
    }
    
    /// Formats with decimal places
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

// MARK: - Binding Extensions
extension Binding {
    /// Creates a binding with a custom getter and setter
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
