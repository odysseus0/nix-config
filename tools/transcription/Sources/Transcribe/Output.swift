import Foundation

struct Segment: Codable, Equatable {
    var start: Double
    var end: Double
    var text: String
    var speaker: String
}
struct Transcript: Codable {
    var text: String
    var duration: Double
    var segments: [Segment]
    var speaker_segments: [Segment]
    enum CodingKeys: String, CodingKey { case text, duration, segments, speaker_segments }
}
extension Transcript {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        text = try values.decode(String.self, forKey: .text)
        segments = try values.decode([Segment].self, forKey: .segments)
        speaker_segments = try values.decode([Segment].self, forKey: .speaker_segments)
        duration = try values.decodeIfPresent(Double.self, forKey: .duration)
            ?? (segments + speaker_segments).map(\.end).max() ?? 0
    }
}

func speakerFor(start: Double, end: Double, turns: [Segment]) -> String {
    let midpoint = (start + end) / 2
    return turns.max {
        func score(_ turn: Segment) -> Double {
            let overlap = max(0, min(end, turn.end) - max(start, turn.start))
            if overlap > 0 { return overlap }
            return -min(abs(midpoint - turn.start), abs(midpoint - turn.end))
        }
        return score($0) < score($1)
    }?.speaker ?? "SPEAKER_00"
}

func groupWords(_ words: [Segment]) -> [Segment] {
    var groups: [Segment] = []
    for word in words {
        if let last = groups.last, last.speaker == word.speaker,
            word.start - last.end <= 1, word.end - last.start <= 15 {
            groups[groups.count - 1].end = word.end
            groups[groups.count - 1].text += " " + word.text
        } else { groups.append(word) }
    }
    return groups
}

func timestamp(_ seconds: Double, comma: Bool = false) -> String {
    let milliseconds = max(0, Int((seconds * 1000).rounded()))
    return String(format: "%02d:%02d:%02d%@%03d", milliseconds / 3_600_000,
        milliseconds / 60_000 % 60, milliseconds / 1000 % 60, comma ? "," : ".", milliseconds % 1000)
}

func render(_ result: Transcript, format: String) throws -> Data {
    if format == "json" {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(result)
    }
    let rows = result.speaker_segments
    let text: String
    switch format {
    case "txt":
        text = rows.map { "[\(timestamp($0.start))] \($0.speaker): \($0.text)" }.joined(separator: "\n") + "\n"
    case "srt":
        text = rows.enumerated().map { index, row in
            "\(index + 1)\n\(timestamp(row.start, comma: true)) --> \(timestamp(row.end, comma: true))\n\(row.speaker): \(row.text)\n"
        }.joined(separator: "\n")
    case "vtt":
        text = "WEBVTT\n\n" + rows.map {
            let escaped = $0.text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
            return "\(timestamp($0.start)) --> \(timestamp($0.end))\n<v \($0.speaker)>\(escaped)</v>\n"
        }.joined(separator: "\n")
    case "tsv":
        text = "start\tend\tspeaker\ttext\n" + rows.map {
            "\(Int(($0.start * 1000).rounded()))\t\(Int(($0.end * 1000).rounded()))\t\($0.speaker)\t\($0.text.replacingOccurrences(of: "\t", with: " ").replacingOccurrences(of: "\n", with: " "))"
        }.joined(separator: "\n") + "\n"
    default: throw Failure("Unsupported output format: \(format)")
    }
    return Data(text.utf8)
}

struct Failure: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) { self.description = description }
}
