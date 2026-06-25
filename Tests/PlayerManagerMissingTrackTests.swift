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
