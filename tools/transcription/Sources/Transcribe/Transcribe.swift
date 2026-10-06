import FluidAudio
import Foundation

struct Options {
    var input: URL?
    var output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    var format = "json"
    var speakers: Int? = 2
    var diarize = true
    var formatExisting = false

    init(_ arguments: [String]) throws {
        var index = 0
        while index < arguments.count {
            let argument = arguments[index]
            func value() throws -> String {
                index += 1
                guard index < arguments.count else { throw Failure("Missing value for \(argument)") }
                return arguments[index]
            }
            switch argument {
            case "--output-dir": output = URL(fileURLWithPath: try value())
            case "--output-format": format = try value()
            case "--num-speakers":
                guard let count = Int(try value()), count > 0 else { throw Failure("Speaker count must be positive") }
                speakers = count
            case "--auto-speakers": speakers = nil
            case "--no-diarize": diarize = false
            case "--format-json": formatExisting = true
            default:
                guard !argument.hasPrefix("-"), input == nil else { throw Failure("Unknown argument: \(argument)") }
                input = URL(fileURLWithPath: argument)
            }
            index += 1
        }
        guard input != nil else { throw Failure("Provide an audio/video file") }
        if formatExisting, !arguments.contains("--output-dir"), let input {
            output = input.deletingLastPathComponent()
        }
        guard ["json", "txt", "srt", "vtt", "tsv", "all"].contains(format) else { throw Failure("Invalid output format: \(format)") }
    }
}

@main struct Transcribe {
    static func main() async {
        if CommandLine.arguments.contains("--help") {
            print("""
            Usage: transcribe FILE [--output-dir DIR] [--output-format json|txt|srt|vtt|tsv|all]
                                  [--num-speakers N | --auto-speakers] [--no-diarize]
            Defaults: Parakeet Ultra, word timestamps, two anonymous speakers, JSON.
            transcription-format FILE.json [--output-dir DIR] renders existing speaker labels.
            """)
            return
        }
        do {
            let options = try Options(Array(CommandLine.arguments.dropFirst()))
            guard let input = options.input else { throw Failure("Missing input") }
            let result: Transcript
            if options.formatExisting {
                result = try JSONDecoder().decode(Transcript.self, from: Data(contentsOf: input))
            } else {
                result = try await recognize(input, options: options)
            }
            try FileManager.default.createDirectory(at: options.output, withIntermediateDirectories: true)
            let formats = options.format == "all" ? ["json", "txt", "srt", "vtt", "tsv"] : [options.format]
            for format in formats {
                let suffix = options.formatExisting ? ".speakers" : ""
                let path = options.output.appendingPathComponent(input.deletingPathExtension().lastPathComponent + suffix + "." + format)
                guard path.standardizedFileURL != input.standardizedFileURL else { throw Failure("Output would overwrite input") }
                try render(result, format: format).write(to: path, options: .atomic)
                print(path.path)
            }
        } catch {
            FileHandle.standardError.write(Data("transcribe: \(error)\n".utf8))
            exit(1)
        }
    }

    static func recognize(_ input: URL, options: Options) async throws -> Transcript {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let wav = temporary.appendingPathComponent("audio.wav")
        let conversion = Process()
        conversion.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        conversion.arguments = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-nostdin", "-i", input.path,
            "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", wav.path]
        try conversion.run()
        conversion.waitUntilExit()
        guard conversion.terminationStatus == 0 else { throw Failure("Audio conversion failed") }
        guard let cache = ProcessInfo.processInfo.environment["FLUID_TRANSCRIPTION_MODELS"] else { throw Failure("Model directory missing") }
        let modelDirectory = URL(fileURLWithPath: cache)
        print("Loading Parakeet Ultra…")
        let models = try await AsrModels.downloadAndLoad(to: modelDirectory.appendingPathComponent("parakeet-ultra"), version: .ultra)
        let manager = AsrManager(config: ASRConfig(tdtConfig: TdtConfig(blankId: AsrModelVersion.ultra.blankId), encoderHiddenSize: AsrModelVersion.ultra.encoderHiddenSize))
        try await manager.loadModels(models)
        var state = TdtDecoderState.make(decoderLayers: await manager.decoderLayerCount)
        print("Recognizing speech…")
        let recognized = try await manager.transcribe(wav, decoderState: &state)
        var turns: [Segment] = []
        if options.diarize {
            print("Labeling speakers…")
            let models = try await OfflineDiarizerModels.load(from: modelDirectory)
            var config = OfflineDiarizerConfig.default
            if let count = options.speakers { config = config.withSpeakers(exactly: count) }
            let diarizer = OfflineDiarizerManager(config: config)
            diarizer.initialize(models: models)
            let speakers = try await diarizer.process(wav)
            let names = Set(speakers.segments.map(\.speakerId)).sorted()
            let labels = Dictionary(uniqueKeysWithValues: names.enumerated().map { ($0.element, String(format: "SPEAKER_%02d", $0.offset)) })
            turns = speakers.segments.map { Segment(start: Double($0.startTimeSeconds), end: Double($0.endTimeSeconds), text: "", speaker: labels[$0.speakerId] ?? $0.speakerId) }
        }
        let words = buildWordTimings(from: recognized.tokenTimings ?? []).map {
            Segment(start: $0.startTime, end: $0.endTime, text: $0.word, speaker: speakerFor(start: $0.startTime, end: $0.endTime, turns: turns))
        }
        guard !words.isEmpty || recognized.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw Failure("Model returned text without timestamps") }
        return Transcript(text: recognized.text, duration: recognized.duration, segments: words, speaker_segments: groupWords(words))
    }
}
