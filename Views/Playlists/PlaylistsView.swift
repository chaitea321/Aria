import SwiftUI

struct PlaylistsView: View {
    @ObservedObject var playerManager: PlayerManager
    @ObservedObject var playlistsManager: PlaylistsManager
    @ObservedObject var recentlyPlayedManager: RecentlyPlayedManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var themeManager: ThemeManager

    @State private var selectedTab: PlaylistTab = .recentlyAdded
    @State private var showNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    @State private var selectedPlaylist: Playlist?

    enum PlaylistTab: String, CaseIterable {
        case recentlyAdded = "Recently Added"
        case recentlyPlayed = "Recently Played"
    }

    var body: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerBar
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    recentPlaylistsSection
                        .padding(.top, 16)

                    tabPicker
                        .padding(.horizontal, 16)
                        .padding(.top, 20)

                    tabContent
                        .padding(.top, 8)

                    yourPlaylistsSection
                        .padding(.top, 24)
                }
            }
        }
        .alert("New Playlist", isPresented: $showNewPlaylistAlert) {
            TextField("Playlist name", text: $newPlaylistName)
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                let trimmed = newPlaylistName.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                _ = playlistsManager.create(name: trimmed)
                newPlaylistName = ""
            }
        }
        .sheet(item: $selectedPlaylist) { playlist in
            PlaylistDetailView(
                playerManager: playerManager,
                playlistsManager: playlistsManager,
                recentlyPlayedManager: recentlyPlayedManager,
                themeManager: themeManager,
                playlist: playlist
            )
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Menu {
                ForEach(PlaylistSortOrder.allCases, id: \.self) { order in
                    Button {
                        playlistsManager.sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if playlistsManager.sortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.body)
                    .foregroundColor(themeManager.textPrimary)
            }

            Spacer()

            Button {
                showNewPlaylistAlert = true
            } label: {
                Image(systemName: "plus")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.theme.accentColor)
            }
        }
    }

    // MARK: - Recent Playlists

    private var recentPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !playlistsManager.recentlyPlayedPlaylists.isEmpty {
                Text("Recently Played")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimary)
                    .padding(.horizontal, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(playlistsManager.recentlyPlayedPlaylists) { playlist in
                            playlistCard(playlist)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private func playlistCard(_ playlist: Playlist) -> some View {
        VStack(alignment: .leading) {
            Group {
                if let url = playlist.previewThumbnailURL {
                    AsyncCachedImage(url: url) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(themeManager.theme.accentColor.opacity(0.3))
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.title)
                                    .foregroundColor(themeManager.theme.accentColor)
                            )
                    }
                    .aspectRatio(contentMode: .fill)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(themeManager.theme.accentColor.opacity(0.3))
                        .overlay(
                            Image(systemName: "music.note.list")
                                .font(.title)
                                .foregroundColor(themeManager.theme.accentColor)
                        )
                }
            }
            .frame(width: 120, height: 120)
            .cornerRadius(10)
            .clipped()

            Text(playlist.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.textPrimary)
                .lineLimit(1)
                .frame(width: 120)

            Text("\(playlist.tracks.count) tracks")
                .font(.caption2)
                .foregroundColor(themeManager.textSecondary)
        }
        .onTapGesture {
            playlistsManager.markPlayed(playlist)
            selectedPlaylist = playlist
        }
    }

    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(PlaylistTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundColor(selectedTab == tab ? themeManager.textPrimary : themeManager.textSecondary)
                        Rectangle()
                            .fill(selectedTab == tab ? themeManager.theme.accentColor : Color.clear)
                            .frame(height: 2)
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Tab Content

    private var tabContent: some View {
        let tracks = selectedTab == .recentlyAdded
            ? recentlyPlayedManager.recentlyAdded
            : recentlyPlayedManager.recentlyPlayed

        if tracks.isEmpty {
            return AnyView(
                VStack(spacing: 8) {
                    Image(systemName: selectedTab == .recentlyAdded ? "plus.circle" : "clock")
                        .font(.title2)
                        .foregroundColor(themeManager.textSecondary)
                    Text("No tracks yet")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            )
        }

        return AnyView(
            LazyVStack(spacing: 0) {
                ForEach(tracks.prefix(100)) { track in
                    Button {
                        playerManager.play(track)
                        recentlyPlayedManager.trackPlayed(track)
                    } label: {
                        HStack(spacing: 12) {
                            trackThumbnail(track)
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                    .addToQueueGesture(playerManager: playerManager, track: track)
                }
            }
        )
    }

    // MARK: - Your Playlists

    private var yourPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your Playlists")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
                .padding(.horizontal, 16)

            if playlistsManager.playlists.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "music.note.list")
                        .font(.title2)
                        .foregroundColor(themeManager.textSecondary)
                    Text("Create your first playlist")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(playlistsManager.sortedPlaylists) { playlist in
                        playlistRow(playlist)
                    }
                }
                .padding(.top, 8)
            }
        }
    }

    private func playlistRow(_ playlist: Playlist) -> some View {
        Button {
            selectedPlaylist = playlist
        } label: {
            HStack(spacing: 12) {
                Group {
                    if let url = playlist.previewThumbnailURL {
                        AsyncCachedImage(url: url) {
                            Rectangle()
                                .fill(themeManager.theme.accentColor.opacity(0.2))
                                .overlay(
                                    Image(systemName: "music.note.list")
                                        .font(.system(size: 18))
                                        .foregroundColor(themeManager.theme.accentColor)
                                )
                        }
                    } else {
                        Rectangle()
                            .fill(themeManager.theme.accentColor.opacity(0.2))
                            .overlay(
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 18))
                                    .foregroundColor(themeManager.theme.accentColor)
                            )
                    }
                }
                .frame(width: 48, height: 48)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(playlist.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textPrimary)
                    Text("\(playlist.tracks.count) tracks")
                        .font(.caption)
                        .foregroundColor(themeManager.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func trackThumbnail(_ track: Track) -> some View {
        TrackThumbnail(url: track.thumbnailURL, size: 44)
    }
}
