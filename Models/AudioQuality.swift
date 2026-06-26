import Foundation

struct AudioQuality: Codable, Hashable {
    let bitDepth: Int?
    let sampleRateHz: Int?
    let bitrateKbps: Int?

    init(bitDepth: Int? = nil, sampleRateHz: Int? = nil, bitrateKbps: Int? = nil) {
        self.bitDepth = bitDepth
        self.sampleRateHz = sampleRateHz
        self.bitrateKbps = bitrateKbps
    }

    var isHiRes: Bool {
        (sampleRateHz ?? 0) > 48000 || (bitDepth ?? 0) > 16
    }

    var pillText: String {
        if let bd = bitDepth, let sr = sampleRateHz {
            let srShort = sr >= 1000 ? "\(sr / 1000)k" : "\(sr)"
            return "\(bd)/\(srShort)"
        } else if let br = bitrateKbps {
            return "\(br) kbps"
        } else {
            return ""
        }
    }
}
