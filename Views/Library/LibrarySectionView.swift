import SwiftUI

/// Renders one section of the library — a header (when grouping is on)
/// followed by the rows. Used inside `LibraryView`'s
/// `ScrollView { LazyVStack { ForEach(vm.sections) { ... } } }`.
struct LibrarySectionView: View {
    let section: LibrarySection
    let showHeader: Bool
    let tokens: DesignTokens
    let isCurrentTrack: (LocalTrack) -> Bool
    let isPlaying: Bool
    let isFavorite: (LocalTrack) -> Bool
    let onToggleFavorite: (LocalTrack) -> Void
    let onPlay: (LocalTrack) -> Void
    let onAddToPlaylist: (LocalTrack) -> Void
    let onDelete: (LocalTrack) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showHeader && !section.title.isEmpty {
                Text(section.title)
                    .font(.headline)
                    .foregroundColor(tokens.textPrimary)
                    .padding(.horizontal)
                    .padding(.top, 8)
            }
            ForEach(section.tracks) { track in
                LibraryTrackRow(
                    track: track,
                    isCurrentTrack: isCurrentTrack(track),
                    isPlaying: isPlaying,
                    tokens: tokens,
                    isFavorite: isFavorite(track),
                    onTap: { onPlay(track) },
                    onToggleFavorite: { onToggleFavorite(track) }
                )
                .padding(.horizontal)
                .padding(.vertical, 4)
                .background(tokens.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .contextMenu {
                    Button {
                        onPlay(track)
                    } label: {
                        Label("Play", systemImage: "play.fill")
                    }
                    Button {
                        onAddToPlaylist(track)
                    } label: {
                        Label("Add to Playlist", systemImage: "text.badge.plus")
                    }
                    Divider()
                    Button(role: .destructive) {
                        onDelete(track)
                    } label: {
                        Label("Delete from Library", systemImage: "trash")
                    }
                }
            }
        }
    }
}
