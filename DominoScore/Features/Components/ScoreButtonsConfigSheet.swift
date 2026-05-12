//
//  ScoreButtonsConfigSheet.swift
//  DominoScore
//

import SwiftUI

/// Sheet that lets the host configure score buttons (count and values).
struct ScoreButtonsConfigSheet: View {
    @Binding var buttons: [ScoreButton]
    @Environment(\.dismiss) private var dismiss

    /// Local editing copy so changes only apply on save.
    @State private var draft: [ScoreButton] = []
    @Namespace private var previewNamespace

    private let allowedValues = stride(from: 5, through: 50, by: 5).map { $0 }
    private let countRange = 3...5

    var body: some View {
        NavigationStack {
            List {
                buttonCountSection
                buttonValuesSection
                previewSection
            }
            .navigationTitle("Botões")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        buttons = sortedDraft
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                draft = buttons
            }
        }
    }

    // MARK: - Sections

    private var buttonCountSection: some View {
        Section {
            Stepper("Quantidade: \(draft.count)", value: buttonCountBinding, in: countRange)
        } header: {
            Text("Quantidade de botões")
        } footer: {
            Text("Escolha de 3 a 5 botões.")
        }
    }

    private var buttonValuesSection: some View {
        Section("Valores") {
            ForEach(draft.indices, id: \.self) { index in
                buttonRow(at: index)
            }
        }
    }

    private var sortedDraft: [ScoreButton] {
        draft.sorted { $0.value < $1.value }
    }

    private var previewSection: some View {
        Section("Preview") {
            HStack(spacing: 10) {
                ForEach(sortedDraft) { btn in
                    Text(btn.label)
                        .font(.title3.weight(.bold).monospacedDigit())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.green.opacity(0.15), in: .rect(cornerRadius: 10))
                        .matchedGeometryEffect(id: btn.id, in: previewNamespace)
                }
            }
            .animation(.snappy, value: sortedDraft.map(\.id))
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        }
    }

    // MARK: - Row

    private func buttonRow(at index: Int) -> some View {
        HStack {
            Text("Botão \(index + 1)")

            Spacer()

            Picker("", selection: $draft[index].value) {
                ForEach(allowedValues, id: \.self) { v in
                    Text("\(v)").tag(v)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 80)

            if draft[index].value == 50 {
                Toggle("🐓", isOn: $draft[index].isGalo)
                    .labelsHidden()
                    .frame(width: 50)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: draft[index].value)
        .onChange(of: draft[index].value) { _, newValue in
            if newValue != 50 {
                draft[index].isGalo = false
            }
        }
    }

    // MARK: - Helpers

    private var buttonCountBinding: Binding<Int> {
        Binding(
            get: { draft.count },
            set: { newCount in
                if newCount > draft.count {
                    let toAdd = newCount - draft.count
                    for _ in 0..<toAdd {
                        let nextValue = allowedValues.first { v in
                            !draft.contains { $0.value == v && !$0.isGalo }
                        } ?? 5
                        draft.append(ScoreButton(value: nextValue))
                    }
                } else if newCount < draft.count {
                    draft.removeLast(draft.count - newCount)
                }
            }
        )
    }
}

#Preview {
    @Previewable @State var buttons = ScoreButton.defaultButtons
    ScoreButtonsConfigSheet(buttons: $buttons)
}
