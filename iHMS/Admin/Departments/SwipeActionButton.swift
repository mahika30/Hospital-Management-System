//
//  SwipeActionButton.swift
//  iHMS
//
//  Created by Hargun Singh on 07/01/26.
//

import SwiftUI

struct SwipeToInviteButton: View {

    let isEnabled: Bool
    let isLoading: Bool
    let action: () async -> Void

    @State private var offset: CGFloat = 0
    @State private var didCompleteSwipe = false

    private let height: CGFloat = 60
    private let handleSize: CGFloat = 52
    private let horizontalPadding: CGFloat = 6

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.85),
                            Color(red: 0.06, green: 0.09, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.blue.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .frame(height: height)
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.35),
                            Color.purple.opacity(0.35)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(
                    width: progressWidth,
                    height: height
                )
                .blur(radius: 10)
                .opacity(offset > 0 ? 1 : 0)
                .clipped()
                .animation(.easeOut(duration: 0.2), value: offset)

            HStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.7),
                                        Color.blue.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 5)
                    .frame(width: handleSize, height: handleSize)
                    .overlay(
                        Image(systemName: didCompleteSwipe ? "checkmark" : "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .offset(x: offset)
                    .gesture(dragGesture)

                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            Text(isEnabled ? "Swipe to Invite Doctor" : "Invite Unavailable")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(
                    isEnabled
                    ? Color.white.opacity(0.9)
                    : Color.white.opacity(0.4)
                )
                .opacity(isLoading ? 0.5 : 1)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .opacity(isLoading ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
    }

    private var maxDrag: CGFloat {
        UIScreen.main.bounds.width - handleSize - 60
    }

    private var progressWidth: CGFloat {
        max(handleSize + offset + horizontalPadding * 2, handleSize)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard isEnabled, !isLoading else { return }
                if value.translation.width > 0 {
                    offset = min(value.translation.width, maxDrag)
                }
            }
            .onEnded { _ in
                guard isEnabled, !isLoading else {
                    withAnimation(.spring()) { offset = 0 }
                    return
                }

                if offset > maxDrag * 0.75 {
                    withAnimation(.spring()) {
                        offset = maxDrag
                        didCompleteSwipe = true
                    }

                    Task { await action() }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                        withAnimation(.spring()) {
                            offset = 0
                            didCompleteSwipe = false
                        }
                    }
                } else {
                    withAnimation(.spring()) {
                        offset = 0
                    }
                }
            }
    }
}
