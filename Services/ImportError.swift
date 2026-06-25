import Foundation

enum ImportError: Error, LocalizedError {
    case unsupportedFormat(format: AudioFormat)

    var format: AudioFormat {
        switch self {
        case .unsupportedFormat(let format): return format
        }
    }

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "\(format.displayName) format is not supported."
        }
    }
}
