import XCTest
@testable import Transcribe
final class OutputTests: XCTestCase {
    func testSpeakerOverlapAndGap() {
        let turns = [Segment(start: 0, end: 1, text: "", speaker: "A"), Segment(start: 2, end: 4, text: "", speaker: "B")]
        XCTAssertEqual(speakerFor(start: 0.9, end: 2.5, turns: turns), "B")
        XCTAssertEqual(speakerFor(start: 1.7, end: 1.8, turns: turns), "B")
        XCTAssertEqual(speakerFor(start: 0, end: 1, turns: []), "SPEAKER_00")
    }
    func testGroupingPreservesSpeakerChangesAndPauses() {
        let words = [Segment(start: 0, end: 1, text: "Hello", speaker: "A"), Segment(start: 1, end: 2, text: "world", speaker: "A"), Segment(start: 2, end: 3, text: "Yes", speaker: "B"), Segment(start: 6, end: 7, text: "Again", speaker: "B")]
        XCTAssertEqual(groupWords(words).map(\.text), ["Hello world", "Yes", "Again"])
    }
    func testTimestampCarryAndVoiceEscaping() throws {
        XCTAssertEqual(timestamp(59.9996, comma: true), "00:01:00,000")
        let row = Segment(start: 0, end: 1, text: "a < b & c", speaker: "SPEAKER_00")
        let result = Transcript(text: row.text, duration: 1, segments: [row], speaker_segments: [row])
        let vtt = String(decoding: try render(result, format: "vtt"), as: UTF8.self)
        XCTAssertTrue(vtt.contains("<v SPEAKER_00>a &lt; b &amp; c</v>"))
        XCTAssertEqual(try JSONDecoder().decode(Transcript.self, from: render(result, format: "json")).segments, [row])
    }
    func testLegacyJSONAndFormatterDestination() throws {
        let json = #"{"text":"Hi","segments":[{"start":0,"end":1,"text":"Hi","speaker":"A"}],"speaker_segments":[{"start":0,"end":1,"text":"Hi","speaker":"A"}]}"#
        XCTAssertEqual(try JSONDecoder().decode(Transcript.self, from: Data(json.utf8)).duration, 1)
        XCTAssertEqual(try Options(["/tmp/old.json", "--format-json"]).output.path, "/tmp")
    }
    func testInvalidArgumentsFail() {
        XCTAssertThrowsError(try Options(["test.wav", "--num-speakers", "0"]))
        XCTAssertThrowsError(try Options(["test.wav", "--output-format", "bogus"]))
        XCTAssertThrowsError(try Options(["test.wav", "--batch-size", "8"]))
    }
}
