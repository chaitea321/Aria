import SwiftUI

struct SearchView: View {
    @ObservedObject var playerManager: PlayerManager
    @ObservedObject var recentlyPlayedManager: RecentlyPlayedManager
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settingsManager: SettingsManager
    @Binding var selectedTab: AppTab

    @State private var query = ""
    @State private var results: [Track] = []
    @State private var isSearching = false
    @State private var errorMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var hasSearched = false

    private let searchService: YouTubeSearchService

    init(playerManager: PlayerManager, recentlyPlayedManager: RecentlyPlayedManager, themeManager: ThemeManager, settingsManager: SettingsManager, selectedTab: Binding<AppTab>) {
        self.playerManager = playerManager
        self.recentlyPlayedManager = recentlyPlayedManager
        self.themeManager = themeManager
        self.settingsManager = settingsManager
        self._selectedTab = selectedTab
        self.searchService = YouTubeSearchService(backendURL: playerManager.backendURL)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.background.ignoresSafeArea()

                if hasSearched || !query.isEmpty {
                    searchResultsList
                } else {
                    browseContent
                }
            }
            .navigationTitle("Search")
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
            .onChange(of: query) { newQuery in
                errorMessage = nil
                searchTask?.cancel()
                searchService.cancel()

                let trimmed = newQuery.trimmingCharacters(in: .whitespaces)
                guard trimmed.count >= 3 else {
                    results = []
                    hasSearched = false
                    errorMessage = nil
                    return
                }

                hasSearched = true
                searchTask = Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    await performSearch(query: trimmed)
                }
            }
            .overlay {
                if isSearching {
                    ProgressView()
                        .tint(themeManager.theme.accentColor)
                }
            }
        }
    }

    // MARK: - Browse

    private var browseContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                searchHistorySection
                recentlyPlayedSection
                trendingSection
            }
            .padding(.bottom, 32)
        }
    }

    private var searchHistorySection: some View {
        Group {
            if !settingsManager.searchHistory.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Recent Searches")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(themeManager.textPrimary)
                        Spacer()
                        Button {
                            settingsManager.clearSearchHistory()
                        } label: {
                            Text("Clear")
                                .font(.caption)
                                .foregroundColor(themeManager.theme.accentColor)
                        }
                    }
                    .padding(.horizontal, 16)

                    ForEach(settingsManager.searchHistory, id: \.self) { item in
                        Button {
                            query = item
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(themeManager.textSecondary)
                                Text(item)
                                    .font(.subheadline)
                                    .foregroundColor(themeManager.textPrimary)
                                    .lineLimit(1)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                        }
                    }
                }
            }
        }
    }

    private var recentlyPlayedSection: some View {
        Group {
            if !recentlyPlayedManager.recentlyPlayed.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Based on Your Listening")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimary)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                        ForEach(recentlyPlayedManager.recentlyPlayed.prefix(8)) { track in
                            trackCard(track)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }

    private var trendingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trending")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimary)
                .padding(.horizontal, 16)

            if recentlyPlayedManager.recentlyPlayed.isEmpty {
                Text("Start searching and listening to see trends")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondary)
                    .padding(.horizontal, 16)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                    ForEach(recentlyPlayedManager.recentlyPlayed.prefix(20)) { track in
                        smallTrackCard(track)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Search Results

    private var searchResultsList: some View {
        List {
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .listRowBackground(Color.clear)
            }

            ForEach(results) { track in
                Button {
                    playerManager.play(track)
                    recentlyPlayedManager.trackPlayed(track)
                    selectedTab = .favorites
                } label: {
                    HStack(spacing: 12) {
                        TrackThumbnail(url: track.thumbnailURL, size: 56, cornerRadius: 8)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(track.title)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.textPrimary)
                                .lineLimit(2)
                            Text(track.artist)
                                .font(.caption)
                                .foregroundColor(themeManager.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .addToQueueGesture(playerManager: playerManager, track: track)
                .listRowBackground(themeManager.background)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Track Cards

    private func trackCard(_ track: Track) -> some View {
        Button {
            playerManager.play(track)
            recentlyPlayedManager.trackPlayed(track)
            selectedTab = .favorites
        } label: {
            HStack(spacing: 10) {
                TrackThumbnail(url: track.thumbnailURL, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textPrimary)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.caption2)
                        .foregroundColor(themeManager.textSecondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(themeManager.surface)
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
        .addToQueueGesture(playerManager: playerManager, track: track)
    }

    private func smallTrackCard(_ track: Track) -> some View {
        Button {
            playerManager.play(track)
            recentlyPlayedManager.trackPlayed(track)
            selectedTab = .favorites
        } label: {
            VStack(spacing: 6) {
                TrackThumbnail(url: track.thumbnailURL, size: 64, cornerRadius: 6)
            }
        }
        .buttonStyle(.plain)
        .addToQueueGesture(playerManager: playerManager, track: track)
    }

    // MARK: - Search

    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            results = []
            errorMessage = nil
            return
        }

        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            results = try await searchService.search(query: query)
            settingsManager.addSearchToHistory(query)
        } catch {
            if !(error is CancellationError) {
                errorMessage = error.localizedDescription
            }
            results = []
        }
    }
}
