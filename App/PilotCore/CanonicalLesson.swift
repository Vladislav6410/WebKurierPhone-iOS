import Foundation

struct CanonicalLesson: Codable, Equatable, Sendable {
    struct Section: Codable, Equatable, Sendable, Identifiable {
        let id: String
        let kind: String
        let narration: String
        let visualRefs: [String]
    }

    struct Visual: Codable, Equatable, Sendable, Identifiable {
        let id: String
        let description: String
        let sourcePolicy: String
    }

    struct TTS: Codable, Equatable, Sendable {
        let scriptFile: String
    }

    let lessonId: String
    let language: String
    let title: String
    let objectives: [String]
    let sections: [Section]
    let visuals: [Visual]
    let tts: TTS

    var assignmentSection: Section? {
        sections.first { $0.kind == "assignment" }
    }
}

enum CanonicalLessonLoadError: Error, Equatable {
    case missingResource(String)
    case malformedJSON
}

struct CanonicalLessonLoader {
    static let lesson01Subdirectory = "Education/Lessons/week01/lesson01"

    func loadLesson01(from bundle: Bundle = .main) throws -> CanonicalLesson {
        guard let url = bundle.url(
            forResource: "lesson",
            withExtension: "json",
            subdirectory: Self.lesson01Subdirectory
        ) else {
            throw CanonicalLessonLoadError.missingResource("lesson.json")
        }
        return try load(from: url)
    }

    func load(from url: URL) throws -> CanonicalLesson {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CanonicalLessonLoadError.missingResource(url.lastPathComponent)
        }
        do {
            return try JSONDecoder().decode(CanonicalLesson.self, from: Data(contentsOf: url))
        } catch let error as CanonicalLessonLoadError {
            throw error
        } catch {
            throw CanonicalLessonLoadError.malformedJSON
        }
    }
}
