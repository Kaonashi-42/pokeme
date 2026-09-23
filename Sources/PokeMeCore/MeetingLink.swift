import Foundation

/// Finds video-call links (Zoom, Meet, Teams…) in free-form event fields.
public enum MeetingLink {
    /// Known video services, matched on the host or any of its subdomains.
    static let services: [(host: String, name: String)] = [
        ("zoom.us", "Zoom"),
        ("meet.google.com", "Google Meet"),
        ("teams.microsoft.com", "Teams"),
        ("teams.live.com", "Teams"),
        ("webex.com", "Webex"),
        ("whereby.com", "Whereby"),
        ("facetime.apple.com", "FaceTime"),
        ("chime.aws", "Chime"),
    ]

    private static let detector = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue
    )

    /// Only web links are opened: a calendar invite is untrusted input and could carry other schemes.
    static let allowedSchemes: Set<String> = ["https", "http"]

    /// The first web link to a known video service found across `texts` (typically the event URL, location and notes).
    public static func find(in texts: [String?]) -> URL? {
        guard let detector else { return nil }
        let text = texts.compactMap { $0 }.joined(separator: "\n")
        return detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
            .lazy
            .compactMap(\.url)
            .first { allowedSchemes.contains($0.scheme?.lowercased() ?? "") && serviceName(for: $0) != nil }
    }

    /// Human-readable service name ("Zoom", "Google Meet"…) or nil if the link is not a known video service.
    public static func serviceName(for url: URL) -> String? {
        guard let host = url.host?.lowercased() else { return nil }
        return services.first { host == $0.host || host.hasSuffix("." + $0.host) }?.name
    }
}
