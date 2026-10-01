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

    func validatePackage(visualCatalog: [Visual]? = nil) throws {
        let lessonId = lessonId.trimmingCharacters(in: .whitespacesAndNewlines)
        let language = language.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if lessonId.isEmpty { throw CanonicalLessonLoadError.emptyLessonId }
        if language.isEmpty { throw CanonicalLessonLoadError.emptyLanguage }
        if title.isEmpty { throw CanonicalLessonLoadError.emptyTitle }
        if sections.isEmpty { throw CanonicalLessonLoadError.missingAssignment }
        var sectionIDs = Set<String>()
        for section in sections {
            let id = section.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if id.isEmpty || !sectionIDs.insert(id).inserted {
                throw CanonicalLessonLoadError.duplicateSectionId(section.id)
            }
        }
        guard let assignment = assignmentSection,
              !assignment.narration.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw CanonicalLessonLoadError.missingAssignment
        }
        var visualIDs = Set<String>()
        for visual in visuals {
            let id = visual.id.trimmingCharacters(in: .whitespacesAndNewlines)
            if id.isEmpty || !visualIDs.insert(id).inserted {
                throw CanonicalLessonLoadError.duplicateVisualId(visual.id)
            }
        }
        for section in sections {
            for ref in section.visualRefs where !visualIDs.contains(ref) {
                throw CanonicalLessonLoadError.danglingVisualReference(ref)
            }
        }
        if tts.scriptFile.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw CanonicalLessonLoadError.missingTTSResource
        }
        if let visualCatalog {
            let catalogIDs = Set(visualCatalog.map(\.id))
            if catalogIDs != visualIDs {
                throw CanonicalLessonLoadError.danglingVisualReference(
                    visualIDs.symmetricDifference(catalogIDs).sorted().first ?? "visuals.json"
                )
            }
        }
    }
}

enum CanonicalLessonLoadError: Error, Equatable {
    case missingResource(String)
    case malformedJSON
    case emptyLessonId
    case emptyLanguage
    case emptyTitle
    case duplicateSectionId(String)
    case missingAssignment
    case duplicateVisualId(String)
    case danglingVisualReference(String)
    case missingTTSResource
    case unexpectedCanonicalIdentity(String)
}

enum CanonicalLessonMapping {
    static let lesson01PilotId = "wk01-l01-computer-system"
    static let lesson01CanonicalId = "week01.lesson01.computer-as-system"

    static func canonicalId(forPilotLessonId pilotLessonId: String) -> String? {
        pilotLessonId == lesson01PilotId ? lesson01CanonicalId : nil
    }
}

struct CanonicalLessonLoader {
    static let lesson01Subdirectory = "Education/Lessons/week01/lesson01"
    static let lesson01ResourceName = "lesson"
    static let visualsResourceName = "visuals"
    static let lesson01TTSResourceName = "lesson01_ru_tts"

    func loadLesson01(from bundle: Bundle = .main) throws -> CanonicalLesson {
        guard let url = bundle.url(
            forResource: Self.lesson01ResourceName,
            withExtension: "json",
            subdirectory: Self.lesson01Subdirectory
        ) else {
            throw CanonicalLessonLoadError.missingResource("lesson.json")
        }
        guard bundle.url(
            forResource: Self.visualsResourceName,
            withExtension: "json",
            subdirectory: Self.lesson01Subdirectory
        ) != nil else {
            throw CanonicalLessonLoadError.missingResource("visuals.json")
        }
        guard bundle.url(
            forResource: Self.lesson01TTSResourceName,
            withExtension: "txt",
            subdirectory: Self.lesson01Subdirectory
        ) != nil else {
            throw CanonicalLessonLoadError.missingResource("lesson01_ru_tts.txt")
        }
        let lesson = try load(from: url)
        guard lesson.lessonId == CanonicalLessonMapping.lesson01CanonicalId else {
            throw CanonicalLessonLoadError.unexpectedCanonicalIdentity(lesson.lessonId)
        }
        return lesson
    }

    func load(from url: URL) throws -> CanonicalLesson {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CanonicalLessonLoadError.missingResource(url.lastPathComponent)
        }
        let lesson: CanonicalLesson
        do {
            lesson = try JSONDecoder().decode(CanonicalLesson.self, from: Data(contentsOf: url))
        } catch let error as CanonicalLessonLoadError {
            throw error
        } catch {
            throw CanonicalLessonLoadError.malformedJSON
        }
        let directory = url.deletingLastPathComponent()
        let visualsURL = directory.appendingPathComponent("visuals.json")
        let catalog = try loadVisualCatalog(at: visualsURL)
        try lesson.validatePackage(visualCatalog: catalog)
        try requireReadableResource(named: lesson.tts.scriptFile, in: directory)
        return lesson
    }

    private func loadVisualCatalog(at url: URL) throws -> [CanonicalLesson.Visual] {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw CanonicalLessonLoadError.missingResource("visuals.json")
        }
        do {
            return try JSONDecoder().decode([CanonicalLesson.Visual].self, from: Data(contentsOf: url))
        } catch let error as CanonicalLessonLoadError {
            throw error
        } catch {
            throw CanonicalLessonLoadError.malformedJSON
        }
    }

    private func requireReadableResource(named name: String, in directory: URL) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw CanonicalLessonLoadError.missingTTSResource }
        let url = directory.appendingPathComponent(trimmed)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              !data.isEmpty else {
            throw CanonicalLessonLoadError.missingTTSResource
        }
    }
}
