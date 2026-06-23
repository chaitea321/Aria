import SwiftUI
import Combine

@MainActor final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme = .default
    @Published var isDarkMode: Bool = true

    private let settings: SettingsManager

    init(settings: SettingsManager) {
        self.settings = settings
        self.isDarkMode = settings.isDarkMode
        if let t = AppTheme.allThemes.first(where: { $0.id == settings.selectedThemeID }) {
            self.theme = t
        }
    }

    func selectTheme(_ theme: AppTheme) {
        self.theme = theme
        settings.setTheme(theme.id)
    }

    func toggleDarkMode() {
        isDarkMode.toggle()
        settings.isDarkMode = isDarkMode
        settings.save()
    }

    var background: Color {
        isDarkMode ? Color.black : Color.white
    }

    var surface: Color {
        isDarkMode ? Color(white: 0.08) : Color(white: 0.95)
    }

    var elevatedSurface: Color {
        isDarkMode ? Color(white: 0.12) : Color.white
    }

    var textPrimary: Color {
        isDarkMode ? Color.white : Color.black
    }

    var textSecondary: Color {
        isDarkMode ? Color(white: 0.6) : Color(white: 0.4)
    }

    var dividerColor: Color {
        isDarkMode ? Color(white: 0.15) : Color(white: 0.85)
    }
}
