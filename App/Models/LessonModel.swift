import Foundation

struct LessonModel: Identifiable {
    let id = UUID()

    let language: String
    let level: String
    let title: String
    let description: String
    let unitId: String
}