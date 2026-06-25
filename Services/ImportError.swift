import Foundation

enum ImportError: Error, LocalizedError {
    case unsupportedFormat(format: AudioFormat)
    case fileNotDownloaded
    case zeroByteFile

    var format: AudioFormat {
        switch self {
        case .unsupportedFormat(let format): return format
        case .fileNotDownloaded, .zeroByteFile: return .unknown
        }
    }

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "\(format.displayName) format is not supported."
        case .fileNotDownloaded:
            return "File hasn't finished downloading from iCloud."
        case .zeroByteFile:
            return "File is empty (0 bytes)."
        }
    }
}
