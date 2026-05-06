//
//  ScoreStepper.swift
//  DominoScore
//

import SwiftUI

/// Reusable stepper control for incrementing/decrementing a score.
struct ScoreStepper: View {
    let title: String
    @Binding var value: Int
    var step: Int = 1
    var range: ClosedRange<Int> = 0...999

    var body: some View {
        HStack {
            Text(title)
            Spacer()

            Button {
                if value - step >= range.lowerBound {
                    value -= step
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            Text("\(value)")
                .font(.title3.monospacedDigit().bold())
                .frame(minWidth: 44)

            Button {
                if value + step <= range.upperBound {
                    value += step
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    @Previewable @State var score = 10
    ScoreStepper(title: "Pontos", value: $score)
        .padding()
}
