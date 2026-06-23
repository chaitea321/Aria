import SwiftUI

struct FavoritesView: View {
    @ObservedObject var playerManager: PlayerManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var recentlyPlayedManager: RecentlyPlayedManager
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()

            if favoritesManager.tracks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    shuffleButton
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    listContent
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textSecondary)
            Text("No Favorites")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
            Text("Tap the heart on any song to add it here")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondary)
        }
    }

    private var shuffleButton: some View {
        Button {
            if let random = favoritesManager.tracks.randomElement() {
                playerManager.play(random)
                recentlyPlayedManager.trackPlayed(random)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .font(.body)
                Text("Shuffle Play")
                    .font(.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(themeManager.theme.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private var listContent: some View {
        List {
            ForEach(favoritesManager.groupedByLetter(), id: \.letter) { group in
                Section {
                    ForEach(group.tracks) { track in
                        Button {
                            playerManager.play(track)
                            recentlyPlayedManager.trackPlayed(track)
                        } label: {
                            HStack(spacing: 12) {
                                thumbnail(for: track)

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
                                Image(systemName: "ellipsis")
                                    .font(.caption)
                                    .foregroundColor(themeManager.textSecondary)
                            }
                            .padding(.vertical, 2)
                        }
                        .addToQueueGesture(playerManager: playerManager, track: track)
                    }
                    .onDelete { offsets in
                        guard let idx = offsets.first else { return }
                        let track = group.tracks[idx]
                        favoritesManager.remove(track)
                    }
                } header: {
                    Text(group.letter)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textPrimary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(themeManager.background)
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Text("\(favoritesManager.tracks.count) tracks")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
            }
            .padding(.vertical, 8)
            .background(themeManager.background)
        }
    }

    private func thumbnail(for track: Track) -> some View {
        TrackThumbnail(url: track.thumbnailURL, size: 48)
    }
}
