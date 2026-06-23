import SwiftUI

struct MoreView: View {
    @ObservedObject var playerManager: PlayerManager
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var favoritesManager: FavoritesManager
    @ObservedObject var playlistsManager: PlaylistsManager
    @ObservedObject var recentlyPlayedManager: RecentlyPlayedManager
    @ObservedObject var themeManager: ThemeManager

    @State private var showClearFavoritesAlert = false
    @State private var showDeletePlaylistsAlert = false
    @State private var showClearCacheAlert = false
    @State private var showResetStreamingAlert = false
    @State private var showClearHistoryAlert = false
    @State private var showClearEQCacheAlert = false

    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.background.ignoresSafeArea()

                List {
                    backupSection
                    settingsSection
                    advancedSection
                    extrasSection
                    versionFooter
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("More")
        }
    }

    // MARK: - Backup

    private var backupSection: some View {
        Section {
            Button {
                // Placeholder
            } label: {
                Label("Backup Playlists", systemImage: "icloud.and.arrow.up")
                    .foregroundColor(themeManager.textPrimary)
            }
            Button {
                // Placeholder
            } label: {
                Label("Recovery", systemImage: "icloud.and.arrow.down")
                    .foregroundColor(themeManager.textPrimary)
            }
            Button {
                // Placeholder
            } label: {
                Label("Transfer Playlists", systemImage: "arrow.left.arrow.right")
                    .foregroundColor(themeManager.textPrimary)
            }
        } header: {
            Text("Data")
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        Section {
            HStack {
                Label("Audio Quality", systemImage: "speaker.wave.2")
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Text("Best Available")
                    .font(.body)
                    .foregroundColor(themeManager.textSecondary)
            }

            HStack {
                Label("Default Start Page", systemImage: "house")
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Picker("", selection: $settingsManager.defaultStartTab) {
                    ForEach(DefaultStartTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .onChange(of: settingsManager.defaultStartTab) { _ in
                    settingsManager.save()
                }
            }

            Button {
                showClearHistoryAlert = true
            } label: {
                Label("Clear Search History", systemImage: "magnifyingglass")
                    .foregroundColor(themeManager.textPrimary)
            }
            .alert("Clear Search History", isPresented: $showClearHistoryAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    settingsManager.clearSearchHistory()
                }
            } message: {
                Text("This will remove all your recent searches.")
            }
        } header: {
            Text("Settings")
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        Section {
            Button {
                showResetStreamingAlert = true
            } label: {
                Label("Reinitialize Streaming Settings", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundColor(themeManager.textPrimary)
            }
            .alert("Reinitialize Streaming", isPresented: $showResetStreamingAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    settingsManager.resetStreaming()
                }
            } message: {
                Text("This will reset all streaming settings to default.")
            }

            Button {
                settingsManager.syncStreaming()
            } label: {
                Label("Sync Streaming Settings", systemImage: "arrow.triangle.2.circlepath.icloud")
                    .foregroundColor(themeManager.textPrimary)
            }

            Button {
                showClearCacheAlert = true
            } label: {
                Label("Clear Image / Data Cache", systemImage: "trash.slash")
                    .foregroundColor(themeManager.textPrimary)
            }
            .alert("Clear Cache", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    URLCache.shared.removeAllCachedResponses()
                }
            } message: {
                Text("This will clear all cached images and data.")
            }

            Button(role: .destructive) {
                showClearEQCacheAlert = true
            } label: {
                Label("Clear EQ Audio Cache", systemImage: "waveform.slash")
            }
            .alert("Clear EQ Audio Cache", isPresented: $showClearEQCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    playerManager.clearEQCache()
                }
            } message: {
                Text("Deletes cached audio files used when EQ is enabled. Next EQ playback will re-download from the network.")
            }

            Button(role: .destructive) {
                showClearFavoritesAlert = true
            } label: {
                Label("Clear All Favorites", systemImage: "heart.slash")
            }
            .alert("Clear All Favorites", isPresented: $showClearFavoritesAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear All", role: .destructive) {
                    favoritesManager.removeAll()
                }
            } message: {
                Text("This will permanently remove all your favorites. This action cannot be undone.")
            }

            Button(role: .destructive) {
                showDeletePlaylistsAlert = true
            } label: {
                Label("Delete All Playlists", systemImage: "trash")
            }
            .alert("Delete All Playlists", isPresented: $showDeletePlaylistsAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete All", role: .destructive) {
                    playlistsManager.deleteAll()
                }
            } message: {
                Text("This will permanently delete all playlists. This action cannot be undone.")
            }
        } header: {
            Text("Advanced")
        }
    }

    // MARK: - Extras

    private var extrasSection: some View {
        Section {
            HStack {
                Label("Sleep Timer", systemImage: "moon.zzz")
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Picker("", selection: $settingsManager.sleepTimer) {
                    ForEach(SleepTimerDuration.allCases, id: \.self) { duration in
                        Text(duration.rawValue).tag(duration)
                    }
                }
                .onChange(of: settingsManager.sleepTimer) { _ in
                    settingsManager.save()
                }
            }

            HStack {
                Label("Dark Mode", systemImage: "moon.circle")
                    .foregroundColor(themeManager.textPrimary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { themeManager.isDarkMode },
                    set: { _ in themeManager.toggleDarkMode() }
                ))
                .tint(themeManager.theme.accentColor)
            }

            NavigationLink {
                themePicker
            } label: {
                Label("Choose Theme", systemImage: "paintpalette")
                    .foregroundColor(themeManager.textPrimary)
            }
        } header: {
            Text("Extras")
        }
    }

    // MARK: - Theme Picker

    private var themePicker: some View {
        ZStack {
            themeManager.background.ignoresSafeArea()

            List {
                ForEach(AppTheme.allThemes) { theme in
                    Button {
                        themeManager.selectTheme(theme)
                    } label: {
                        HStack {
                            Circle()
                                .fill(theme.accentColor)
                                .frame(width: 24, height: 24)
                            Text(theme.name)
                                .foregroundColor(themeManager.textPrimary)
                            Spacer()
                            if themeManager.theme.id == theme.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(themeManager.theme.accentColor)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Themes")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Version

    private var versionFooter: some View {
        Section {
            HStack {
                Spacer()
                Text("Aria v\(appVersion)")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondary)
                Spacer()
            }
        }
    }
}
