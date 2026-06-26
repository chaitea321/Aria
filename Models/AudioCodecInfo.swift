import Foundation

struct AudioCodecInfo: Codable, Hashable {
    let codec: String
    let containerExtension: String
    let lossless: Bool

    init(codec: String, containerExtension: String, lossless: Bool) {
        self.codec = codec
        self.containerExtension = containerExtension
        self.lossless = lossless
    }

    var displayName: String { "\(codec) • \(containerExtension.uppercased())" }
}
