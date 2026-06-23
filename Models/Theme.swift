import SwiftUI

struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let accentColor: Color
}

extension AppTheme {
    static let allThemes: [AppTheme] = [
        AppTheme(id: "blue",    name: "Aria Blue",  accentColor: Color(red: 0.35, green: 0.65, blue: 0.95)),
        AppTheme(id: "orange",  name: "Amber",      accentColor: Color(red: 0.98, green: 0.60, blue: 0.20)),
        AppTheme(id: "teal",    name: "Ocean",      accentColor: Color(red: 0.25, green: 0.80, blue: 0.75)),
        AppTheme(id: "mono",    name: "Mono",       accentColor: Color(red: 0.85, green: 0.85, blue: 0.85)),
        AppTheme(id: "rose",    name: "Rose",       accentColor: Color(red: 0.95, green: 0.35, blue: 0.50)),
        AppTheme(id: "forest",  name: "Forest",     accentColor: Color(red: 0.30, green: 0.80, blue: 0.45)),
    ]

    static let `default` = allThemes[0]
}
