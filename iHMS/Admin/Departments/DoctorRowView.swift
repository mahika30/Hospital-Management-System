import SwiftUI

struct DoctorRowView: View {
    let doctor: Staff

    var body: some View {
        HStack(spacing: 6) {

            Image(systemName: "stethoscope.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 3) {

                
                Text("Dr. \(doctor.fullName)")
                    .font(.headline)

                Text(doctor.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(departmentDisplayName.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(departmentBadgeColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }

            Spacer()


        }
        .padding(.vertical, 10)
    }


    private var departmentDisplayName: String {
        doctor.departmentId ?? "Unassigned"
    }

    private var departmentBadgeColor: Color {
        doctor.departmentId == nil ? .gray : .teal
    }
}
