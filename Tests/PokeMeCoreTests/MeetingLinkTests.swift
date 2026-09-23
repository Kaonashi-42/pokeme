import Foundation
import Testing

@testable import PokeMeCore

struct MeetingLinkTests {
    @Test(arguments: [
        ("Join: https://us02web.zoom.us/j/123?pwd=x thanks", "us02web.zoom.us"),
        ("<https://teams.microsoft.com/l/meetup-join/abc>", "teams.microsoft.com"),
        ("https://meet.google.com/abc-defg-hij", "meet.google.com"),
        ("Dial in: https://acme.webex.com/meet/bob", "acme.webex.com"),
    ])
    func findsKnownServices(text: String, host: String) {
        #expect(MeetingLink.find(in: [text])?.host == host)
    }

    @Test func skipsNonVideoLinksBeforeTheVideoLink() {
        let url = MeetingLink.find(in: ["Agenda https://docs.google.com/doc then https://meet.google.com/abc-defg-hij"])
        #expect(url?.absoluteString == "https://meet.google.com/abc-defg-hij")
    }

    @Test func searchesEveryField() {
        let url = MeetingLink.find(in: [nil, "Room 4", "Notes:\nhttps://zoom.us/j/42"])
        #expect(url?.host == "zoom.us")
    }

    @Test(arguments: [
        "Room 4, no link",
        "https://example.com/zoom.us",
        "https://notzoom.us/j/1",
        "ftp://zoom.us/j/1",
        "file://zoom.us/j/1",
        "",
    ])
    func ignoresNonVideoText(text: String) {
        #expect(MeetingLink.find(in: [text]) == nil)
    }

    @Test func returnsNilWithNoFields() {
        #expect(MeetingLink.find(in: []) == nil)
        #expect(MeetingLink.find(in: [nil, nil]) == nil)
    }

    @Test(arguments: [
        ("https://zoom.us/j/1", "Zoom"),
        ("https://US02WEB.ZOOM.US/j/1", "Zoom"),
        ("https://meet.google.com/x", "Google Meet"),
        ("https://teams.live.com/meet/1", "Teams"),
        ("https://facetime.apple.com/join#v=1", "FaceTime"),
    ])
    func namesTheService(link: String, name: String) throws {
        let url = try #require(URL(string: link))
        #expect(MeetingLink.serviceName(for: url) == name)
    }

    @Test func unknownHostHasNoServiceName() throws {
        let url = try #require(URL(string: "https://example.com"))
        #expect(MeetingLink.serviceName(for: url) == nil)
    }
}
