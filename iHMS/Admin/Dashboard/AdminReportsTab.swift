//
//  AdminReportsTab.swift
//  iHMS
//
//  Created by Hargun Singh on 06/01/26.
//

import SwiftUI
struct AdminReportsTab: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                Text("Reports & Analytics")
                    .font(.title2)
                    .bold()

                Text("View hospital performance and trends")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Reports")
        }
    }
}
