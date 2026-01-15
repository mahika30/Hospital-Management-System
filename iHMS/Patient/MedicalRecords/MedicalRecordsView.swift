import SwiftUI

struct MedicalRecordsView: View {
    let patientId: UUID
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                Text("Medical Records")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Coming Soon")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Text("View your medical reports, test results, and health documents here.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .navigationTitle("Medical Records")
        .navigationBarTitleDisplayMode(.inline)
    }
}
