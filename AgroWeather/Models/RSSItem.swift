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
    static let agriLand = RSSSource(
        id: UUID(), name: "AgriLand EU", url: "https://www.agriland.ie/farming-news/feed/",
        icon: "newspaper.fill"
    )
    static let euractiv = RSSSource(
        id: UUID(), name: "Euractiv Agri", url: "https://www.euractiv.com/sections/agriculture-food/feed/",
        icon: "eurosign.circle.fill"
    )
    static let ecAgriculture = RSSSource(
        id: UUID(), name: "EC Agriculture", url: "https://agriculture.ec.europa.eu/news/all_en.rss",
        icon: "building.columns.fill"
    )
    static let farmingUK = RSSSource(
        id: UUID(), name: "Farming UK", url: "https://www.farminguk.com/rss.php",
        icon: "tractor.fill"
    )

    static let all: [RSSSource] = [.capReform]
}
