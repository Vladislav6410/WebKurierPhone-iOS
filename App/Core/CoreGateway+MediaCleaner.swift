import Foundation

// MARK: - CoreGateway + MediaCleaner
// Purpose:
// - Bind MediaCleanerAPI baseURL to the CoreGateway configuration
// - Keep routing responsibility inside CoreGateway (WebKurier rule)

extension CoreGateway {

    /// Call this after CoreGateway has loaded its configuration (bootstrap).
    /// It wires MediaCleanerAPI to the same Core base URL used by the app.
    func configureMediaCleanerAPI() {
        if let url = resolvedCoreBaseURL() {
            MediaCleanerAPI.shared.baseURL = url
        }
    }

    /// Resolve Core base URL from CoreGateway.
    /// Adjust this implementation to match YOUR CoreGateway fields.
    /// This is deliberately conservative and avoids guessing property names.
    private func resolvedCoreBaseURL() -> URL? {
        // ✅ Option A: if your CoreGateway already has something like `baseURL: URL`
        // return self.baseURL

        // ✅ Option B: if you store base url as String (common)
        // return URL(string: self.baseURLString)

        // ✅ Option C: if you keep config object (common)
        // return URL(string: self.config.coreBaseURL)

        // Fallback: do nothing if not available
        return nil
    }
}