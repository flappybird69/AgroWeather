import Foundation

struct RSSItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let link: String
    let pubDate: Date?
    let source: RSSSource

    init(title: String, description: String, link: String, pubDate: Date?, source: RSSSource) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.link = link
        self.pubDate = pubDate
        self.source = source
    }
}

struct RSSSource: Identifiable, Codable {
    let id: UUID
    let name: String
    let url: String
    let icon: String

    static let capReform = RSSSource(
        id: UUID(), name: "CAP Reform EU", url: "https://www.capreform.eu/feed/",
        icon: "star.fill"
    )

    static let all: [RSSSource] = [.capReform]
}
