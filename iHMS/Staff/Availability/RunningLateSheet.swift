//
//  RunningLateSheet.swift
//  iHMS
//
//  Created by Hargun Singh on 09/01/26.
//

import Foundation
import SwiftUI

struct RunningLateSheet: View {

    let slot: TimeSlot
    let onConfirm: (Int) -> Void

    @Environment(\.dismiss) var dismiss
    @State private var minutes = 15

    var body: some View {
        VStack(spacing: 20) {
            Text(slot.timeRange)
                .font(.headline)

            Stepper("Delay: \(minutes) min", value: $minutes, in: 5...120, step: 5)

            Button("Confirm") {
                onConfirm(minutes)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
