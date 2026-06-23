import SwiftUI

struct PlaylistDetailView: View {
    @ObservedObject var playerManager: PlayerManager
    @ObservedObject var playlistsManager: PlaylistsManager
    @ObservedObject var recentlyPlayedManager: RecentlyPlayedManager
    @ObservedObject var themeManager: ThemeManager

    let playlist: Playlist

    @State private var showRenameAlert = false
    @State private var showDeleteAlert = false
    @State private var renameText = ""
    @Environment(\.dismiss) private var dismiss

    private var currentPlaylist: Playlist {
        playlistsManager.playlists.first(where: { $0.id == playlist.id }) ?? playlist
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.background.ignoresSafeArea()

                if currentPlaylist.tracks.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        shufflePlayButton
                            .padding(.horizontal, 16)
                            .padding(.top, 12)
                            .padding(.bottom, 8)

                        Text("\(currentPlaylist.tracks.count) tracks")
                            .font(.caption)
                            .foregroundColor(themeManager.textSecondary)
                            .padding(.bottom, 8)

                        trackList
                    }
                }
            }
            .navigationTitle(currentPlaylist.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            renameText = currentPlaylist.name
                            showRenameAlert = true
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Delete Playlist", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(themeManager.textPrimary)
                    }
                }
            }
            .alert("Rename Playlist", isPresented: $showRenameAlert) {
                TextField("Name", text: $renameText)
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespaces)
                    guard !trimmed.isEmpty else { return }
                    playlistsManager.rename(currentPlaylist, to: trimmed)
                }
            }
            .alert("Delete Playlist", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    playlistsManager.delete(currentPlaylist)
                    dismiss()
                }
            } message: {
                Text("This will permanently delete \"\(currentPlaylist.name)\". This action cannot be undone.")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "music.note.list")
                .font(.system(size: 48))
                .foregroundColor(themeManager.textSecondary)
            Text("No Tracks")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
            Text("Add songs to this playlist from search or now playing")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var shufflePlayButton: some View {
        Button {
            if let random = currentPlaylist.tracks.randomElement() {
                playerManager.play(random)
                recentlyPlayedManager.trackPlayed(random)
                playlistsManager.markPlayed(currentPlaylist)
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

    private var trackList: some View {
        List {
            ForEach(currentPlaylist.tracks) { track in
                Button {
                    playerManager.play(track)
                    recentlyPlayedManager.trackPlayed(track)
                    playlistsManager.markPlayed(currentPlaylist)
                } label: {
                    HStack(spacing: 12) {
                        TrackThumbnail(url: track.thumbnailURL, size: 48)

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
                .addToQueueGesture(playerManager: playerManager, track: track)
            }
            .onDelete { offsets in
                for idx in offsets.sorted(by: >) {
                    playlistsManager.removeTrack(currentPlaylist.tracks[idx], from: currentPlaylist)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(themeManager.background)
    }
}
