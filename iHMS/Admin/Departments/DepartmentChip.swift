//
//  DepartmentChip.swift
//  iHMS
//
//  Created by Hargun Singh on 07/01/26.
//

import Foundation
import SwiftUI

struct DepartmentChip: View {
    let department: Department
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(department.name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .blue : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.blue : Color.gray.opacity(0.3),
                            lineWidth: 1
                        )
                        .background(
                            isSelected
                            ? Color.blue.opacity(0.08)
                            : Color.clear
                        )
                )
        }
        .buttonStyle(.plain)
    }
}
