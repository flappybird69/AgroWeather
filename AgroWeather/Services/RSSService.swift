import Foundation

actor RSSService {
    static let shared = RSSService()

    func fetchRSS(source: RSSSource) async throws -> [RSSItem] {
        guard let url = URL(string: source.url) else {
            throw RSSError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw RSSError.networkError
        }

        let parser = RSSXMLParser(data: data, source: source)
        return try parser.parse()
    }
}

enum RSSError: Error, LocalizedError {
    case invalidURL
    case networkError
    case parseError

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Μη έγκυρη διεύθυνση RSS"
        case .networkError: return "Αδυναμία λήψης νέων"
        case .parseError: return "Σφάλμα ανάγνωσης RSS"
        }
    }
}

private final class RSSXMLParser: NSObject, XMLParserDelegate {
    private let parser: XMLParser
    private let source: RSSSource
    private var items: [RSSItem] = []
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentDateStr = ""
    private var insideItem = false
    private var parseError: Error?

    init(data: Data, source: RSSSource) {
        self.parser = XMLParser(data: data)
        self.source = source
        super.init()
        self.parser.delegate = self
    }

    func parse() throws -> [RSSItem] {
        parser.parse()
        if let error = parseError { throw error }
        return items
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        currentElement = elementName
        if elementName == "item" {
            insideItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentDateStr = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard insideItem else { return }
        switch currentElement {
        case "title": currentTitle += string
        case "description": currentDescription += string
        case "link": currentLink += string
        case "pubDate": currentDateStr += string
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "item" {
            let date = Self.dateFormatter.date(from: currentDateStr.trimmingCharacters(in: .whitespacesAndNewlines))
            let cleanTitle = currentTitle
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanDesc = currentDescription
                .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            items.append(RSSItem(
                title: cleanTitle,
                description: String(cleanDesc.prefix(200)),
                link: currentLink.trimmingCharacters(in: .whitespacesAndNewlines),
                pubDate: date,
                source: source
            ))
            insideItem = false
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        return f
    }()
}
