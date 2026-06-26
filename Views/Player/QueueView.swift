import SwiftUI

struct QueueView: View {
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    private var tokens: DesignTokens { themeManager.tokens }

    @State private var rowFrames: [CGRect] = []
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        NavigationStack {
            ZStack {
                tokens.background.ignoresSafeArea()

                if playerManager.queue.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        trackCount
                            .padding(.horizontal, DS.Spacing.lg)
                            .padding(.vertical, DS.Spacing.sm)

                        queueList
                    }
                }
            }
            .navigationTitle("Up Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(tokens.accent)
                }
                if !playerManager.queue.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear") {
                            Haptics.warning()
                            playerManager.clearQueue()
                        }
                        .foregroundColor(tokens.accent)
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [tokens.accent.opacity(0.30), tokens.accent.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(tokens.accent)
            }
            .softShadow()
            VStack(spacing: DS.Spacing.sm) {
                Text("Queue is Empty")
                    .font(DS.Typography.titleLarge)
                    .foregroundColor(tokens.textPrimary)
                Text("Long press on a song to add it to the queue")
                    .font(DS.Typography.body)
                    .foregroundColor(tokens.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, DS.Spacing.xl)
            Spacer()
        }
    }

    private var trackCount: some View {
        HStack {
            Text("\(playerManager.queue.count) track\(playerManager.queue.count == 1 ? "" : "s")")
                .font(DS.Typography.captionStrong)
                .foregroundColor(tokens.textSecondary)
            Spacer()
        }
    }

    private var queueList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(playerManager.queue.enumerated()), id: \.element.id) { index, track in
                    DraggableQueueRow(
                        track: track,
                        index: index,
                        isCurrent: index == 0,
                        onTap: { onRowTap(index) },
                        onReorder: { from, to in
                            let safeTo = min(to, playerManager.queue.count - 1)
                            playerManager.moveQueueItem(from: IndexSet(integer: from), to: safeTo)
                        },
                        rowFrames: $rowFrames,
                        draggingIndex: $draggingIndex,
                        dragOffset: $dragOffset
                    )
                    .padding(.horizontal, DS.Spacing.lg)
                    .padding(.vertical, 4)
                }
            }
        }
        .coordinateSpace(name: "QueueList")
    }

    private func onRowTap(_ index: Int) {
        Haptics.light()
        if index == 0 {
            playerManager.playNextInQueue()
            if playerManager.queue.isEmpty {
                dismiss()
            }
        }
    }
}
