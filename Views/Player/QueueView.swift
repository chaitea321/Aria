import SwiftUI

struct QueueView: View {
    @ObservedObject var playerManager: PlayerManager
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.background.ignoresSafeArea()

                if playerManager.queue.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        trackCount
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)

                        queueList
                    }
                }
            }
            .navigationTitle("Up Next")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.theme.accentColor)
                }
                if !playerManager.queue.isEmpty {
                    ToolbarItem(placement: .destructiveAction) {
                        Button("Clear", role: .destructive) {
                            playerManager.clearQueue()
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textSecondary)
            Text("Queue is Empty")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
            Text("Long press on a song to add it to the queue")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var trackCount: some View {
        HStack {
            Text("\(playerManager.queue.count) track\(playerManager.queue.count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(themeManager.textSecondary)
            Spacer()
        }
    }

    private var queueList: some View {
        List {
            ForEach(Array(playerManager.queue.enumerated()), id: \.element.id) { index, track in
                Button {
                    if index == 0 {
                        playerManager.playNextInQueue()
                        if playerManager.queue.isEmpty {
                            dismiss()
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                            .frame(width: 20)

                        TrackThumbnail(url: track.thumbnailURL, size: 44)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.textPrimary)
                                .lineLimit(1)
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 2)
                }
            }
            .onDelete { offsets in
                for idx in offsets.sorted(by: >) {
                    playerManager.removeFromQueue(at: idx)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(themeManager.background)
    }
}
