import XCTest
@testable import Aria___Music_Browser

@MainActor
final class PlayerManagerMissingTrackTests: XCTestCase {
    private var mockSession: MockURLSession!
    private var player: PlayerManager!

    override func setUp() {
        super.setUp()
        mockSession = MockURLSession()
        player = PlayerManager(urlSession: mockSession)
    }

    override func tearDown() {
        player = nil
        mockSession = nil
        super.tearDown()
    }

    func test_playSlice_skipsMissingTracks() throws {
        let presentURL = FileManager.default.temporaryDirectory.appendingPathComponent("p_\(UUID().uuidString).mp3")
        try Data(repeating: 0, count: 100).write(to: presentURL)
        defer { try? FileManager.default.removeItem(at: presentURL) }
        let presentLocal = LocalTrack(
            id: UUID(), title: "Present", artist: "A", artworkURL: nil,
            fileName: presentURL.lastPathComponent, importedAt: Date(),
            fileSizeBytes: 100, durationSeconds: 30
        )
        let missingLocal = LocalTrack(
            id: UUID(), title: "Missing", artist: "A", artworkURL: nil,
            fileName: "nope.mp3", importedAt: Date(),
            fileSizeBytes: 100, durationSeconds: 30,
            isMissing: true
        )
        let presentTrack = presentLocal.asPlayerTrack(fileURL: presentURL)
        let missingTrack = missingLocal.asPlayerTrack(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("nope.mp3")
        )

        player.playSlice([missingTrack, presentTrack], startIndex: 0)

        XCTAssertEqual(player.currentTrack?.title, "Present")
        XCTAssertTrue(player.queue.isEmpty, "queue should not contain skipped missing track")
    }

    func test_playSlice_skippedMissingTracks_preservesStartIndex() throws {
        // Library layout (interleaved): [P1, M1, P2, M2].
        // User taps the second present track (P2), which is at index 2
        // in the unfiltered list. `LibraryView.playTrack` is responsible
        // for pre-filtering missing entries and re-locating the index
        // in the playable array; this test pins the *contract* that the
        // resulting call must start playback on the intended track and
        // queue only the tracks that follow it in the playable list.
        let presentURL1 = FileManager.default.temporaryDirectory
            .appendingPathComponent("p1_\(UUID().uuidString).mp3")
        let presentURL2 = FileManager.default.temporaryDirectory
            .appendingPathComponent("p2_\(UUID().uuidString).mp3")
        try Data(repeating: 0, count: 100).write(to: presentURL1)
        try Data(repeating: 0, count: 100).write(to: presentURL2)
        defer {
            try? FileManager.default.removeItem(at: presentURL1)
            try? FileManager.default.removeItem(at: presentURL2)
        }
        let p1 = LocalTrack(
            id: UUID(), title: "P1", artist: "A", artworkURL: nil,
            fileName: presentURL1.lastPathComponent, importedAt: Date(),
            fileSizeBytes: 100, durationSeconds: 30
        )
        let m1 = LocalTrack(
            id: UUID(), title: "M1", artist: "A", artworkURL: nil,
            fileName: "m1.mp3", importedAt: Date(),
            fileSizeBytes: 100, durationSeconds: 30,
            isMissing: true
        )
        let p2 = LocalTrack(
            id: UUID(), title: "P2", artist: "A", artworkURL: nil,
            fileName: presentURL2.lastPathComponent, importedAt: Date(),
            fileSizeBytes: 100, durationSeconds: 30
        )
        let m2 = LocalTrack(
            id: UUID(), title: "M2", artist: "A", artworkURL: nil,
            fileName: "m2.mp3", importedAt: Date(),
            fileSizeBytes: 100, durationSeconds: 30,
            isMissing: true
        )
        let library = [p1, m1, p2, m2]
        let urls: [UUID: URL] = [p1.id: presentURL1, p2.id: presentURL2]
        let playable = library
            .filter { !$0.isMissing }
            .map { local in
                local.asPlayerTrack(fileURL: urls[local.id]!)
            }
        let tappedIndex = playable.firstIndex { $0.id == "local:\(p2.id.uuidString)" }

        XCTAssertNotNil(tappedIndex, "P2 must be present in the playable array")
        player.playSlice(playable, startIndex: tappedIndex!)

        XCTAssertEqual(player.currentTrack?.id, "local:\(p2.id.uuidString)",
                       "playback must start on the second present track (P2), not the third unfiltered entry")
        XCTAssertTrue(player.queue.isEmpty,
                      "queue should be empty — P2 is the last playable track")
    }

    func test_playLocalTrack_missingFile_setsPlayerError() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing_\(UUID().uuidString).mp3")
        // Intentionally do NOT write the file — it does not exist on disk.
        defer { /* no-op: file was never created */ }

        let local = LocalTrack(
            id: UUID(),
            title: "Ghost",
            artist: "A",
            artworkURL: nil,
            fileName: url.lastPathComponent,
            importedAt: Date(),
            fileSizeBytes: 100,
            durationSeconds: 30,
            isMissing: true
        )

        player.play(localTrack: local, fileURL: url)

        XCTAssertEqual(player.playerError, .trackMissing(trackID: "local:\(local.id.uuidString)"))
        XCTAssertEqual(player.playbackState, .ended)
        XCTAssertFalse(player.isPlaying)
    }
}
