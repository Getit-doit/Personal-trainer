import SwiftUI

/// Browsable routine library: programs (Full Body, Push/Pull/Legs, Upper/Lower,
/// 5×5, Conditioning) with day templates, level, and equipment badges. Used as
/// the "start a workout" screen from Today and Train.
struct RoutineLibraryView: View {
    @Environment(\.dismiss) private var dismiss
    var onStart: (WorkoutTemplate) -> Void
    var onEmpty: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    emptyCard
                    ForEach(TrainingContent.programs, id: \.self) { program in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(program)
                                .font(Theme.hand(22, relativeTo: .title3))
                                .padding(.leading, 4)
                            ForEach(TrainingContent.templates(in: program)) { template in
                                templateCard(template)
                            }
                        }
                    }
                }
                .padding()
            }
            .scrollContentBackground(.hidden)
            .blueprintBackground()
            .navigationTitle("Start a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
        }
    }

    private var emptyCard: some View {
        Button {
            onEmpty(); dismiss()
        } label: {
            Card {
                HStack {
                    Image(systemName: "square.dashed").foregroundStyle(Theme.accent)
                    Text("Empty session").bold()
                    Spacer()
                    Image(systemName: "plus.circle.fill").foregroundStyle(Theme.accent)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func templateCard(_ template: WorkoutTemplate) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.title).font(.headline)
                        Text(template.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(template.level)
                        .font(.caption2).bold()
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Theme.card, in: Capsule())
                }

                // Equipment badges
                HStack(spacing: 10) {
                    ForEach(TrainingContent.equipment(in: template), id: \.self) { eq in
                        eq.image.resizable().scaledToFit().frame(width: 20, height: 20)
                            .foregroundStyle(Theme.accent)
                    }
                    Spacer()
                    Text("\(template.exercises.count) exercises")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Button {
                    onStart(template); dismiss()
                } label: {
                    Text("Start \(template.title)")
                        .font(Theme.hand(17, relativeTo: .headline))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(Theme.blueprintDeep)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
