import SwiftUI

struct PaymentsBillsView: View {
    let patientId: UUID
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text("Payments & Bills")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Coming Soon")
                    .font(.body)
                    .foregroundColor(.gray)
                
                Text("Track your medical invoices, payment history, and outstanding bills here.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .navigationTitle("Payments & Bills")
        .navigationBarTitleDisplayMode(.inline)
    }
}
