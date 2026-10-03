import Foundation

/// Expression2 contract: the reply's first speech frame has audioTime == 0.
/// Idle frames omit audioTime. Nil must not be treated as zero.
enum AvatarSpeechStartPolicy {
    static func shouldStartReply(audioTime: Double?, alreadyStarted: Bool) -> Bool {
        audioTime == 0 && !alreadyStarted
    }
}
