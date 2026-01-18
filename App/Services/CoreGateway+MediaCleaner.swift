import Foundation

// MARK: - CoreGateway MediaCleaner Compatibility
// In the current architecture, MediaCleanerAPI uses Endpoints.coreBaseURL,
// which is derived from Info.plist via ConfigReader.
// This method is kept for backward compatibility and pre-warming.

extension CoreGateway {

    func configureMediaCleanerAPI() {
        // Pre-warm config readers / session store if needed
        _ = ConfigReader.shared.coreBaseUrlString
        SessionStore.shared.load()

        Logger.shared.info("MediaCleanerAPI configured (compat). coreBaseURL=\(Endpoints.coreBaseURL.absoluteString)")
    }
}