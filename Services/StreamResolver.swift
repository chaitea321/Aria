import Foundation

/// Resolves a YouTube video ID to a playable stream URL by calling the
/// backend's `/api/play?video_id=...` endpoint.
///
/// The network call is the only thing this actor does. The full
/// `PlayerManager.play(_:)` flow (state update, AVAudioEngine path,
/// Now Playing, etc.) lives in `PlayerManager`; this actor is just the
/// "give me a URL" step.
///
/// The actor gives us natural isolation: in-flight requests don't race
/// with each other, and Swift's structured concurrency handles
/// cancellation when `PlayerManager` switches tracks.
protocol StreamResolving: Sendable {
    func stream(for videoID: String) async throws -> URL
}

actor StreamResolver: StreamResolving {
    let backendURL: String
    let session: URLSessionProtocol

    init(backendURL: String = PlayerManager.backendURL, session: URLSessionProtocol) {
        self.backendURL = backendURL
        self.session = session
    }

    /// Returns the absolute stream URL for a given video ID. Throws on
    /// network failure, malformed response, or unrecoverable URL parsing.
    func stream(for videoID: String) async throws -> URL {
        guard let endpoint = URL(string: "\(backendURL)/api/play?video_id=\(videoID)") else {
            throw StreamResolverError.invalidEndpoint
        }

        let (data, response) = try await session.data(from: endpoint)
        try Self.validate(response: response, data: data)

        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let streamURLString = json["url"] as? String
        else {
            throw StreamResolverError.malformedResponse
        }

        guard
            let streamURL = URL(string: streamURLString, relativeTo: URL(string: backendURL))?.absoluteURL
        else {
            throw StreamResolverError.malformedResponse
        }

        return streamURL
    }

    private static func validate(response: URLResponse, data: Data) throws {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            throw StreamResolverError.serverError(status: http.statusCode, body: body)
        }
    }
}

enum StreamResolverError: LocalizedError {
    case invalidEndpoint
    case malformedResponse
    case serverError(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:           return "Invalid backend URL"
        case .malformedResponse:         return "Server returned an unexpected response"
        case .serverError(let s, let b): return "Server error \(s): \(b)"
        }
    }
}
