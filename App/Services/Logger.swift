import Foundation

enum LogLevel: String {
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

final class Logger {

    static let shared = Logger()
    private init() {}

    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(level.rawValue)] \(fileName):\(line) — \(message)")
        #endif
    }

    func info(_ message: String) {
        log(message, level: .info)
    }

    func warning(_ message: String) {
        log(message, level: .warning)
    }

    func error(_ message: String) {
        log(message, level: .error)
    }
}