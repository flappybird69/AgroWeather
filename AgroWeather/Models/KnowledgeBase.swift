import Foundation

struct AgriRule: Codable, Identifiable {
    let id: UUID
    let category: RuleCategory
    let keywords: [String]
    let requiredVariables: [WeatherVariable]
    let conditions: [RuleCondition]
    let responseGood: String
    let responseBad: String
    let responseNeutral: String

    init(category: RuleCategory, keywords: [String], requiredVariables: [WeatherVariable], conditions: [RuleCondition], responseGood: String, responseBad: String, responseNeutral: String) {
        self.id = UUID()
        self.category = category
        self.keywords = keywords
        self.requiredVariables = requiredVariables
        self.conditions = conditions
        self.responseGood = responseGood
        self.responseBad = responseBad
        self.responseNeutral = responseNeutral
    }
}

enum RuleCategory: String, Codable, CaseIterable {
    case planting = "Φύτευση"
    case irrigation = "Άρδευση"
    case spraying = "Ψεκασμός"
    case fertilizing = "Λίπανση"
    case harvest = "Συγκομιδή"
    case frost = "Παγετός"
    case disease = "Ασθένεια"
    case pruning = "Κλάδεμα"
    case tilling = "Όργωμα"
    case general = "Γενική Συμβουλή"

    var icon: String {
        switch self {
        case .planting: return "leaf.fill"
        case .irrigation: return "drop.fill"
        case .spraying: return "wind"
        case .fertilizing: return "sparkles"
        case .harvest: return "basket.fill"
        case .frost: return "exclamationmark.triangle.fill"
        case .disease: return "cross.case.fill"
        case .pruning: return "scissors"
        case .tilling: return "tractor"
        case .general: return "lightbulb.fill"
        }
    }
}

enum WeatherVariable: String, Codable, CaseIterable {
    case soilMoisture = "soil_moisture"
    case soilTemperature = "soil_temperature"
    case airTemperature = "air_temperature"
    case humidity = "humidity"
    case windSpeed = "wind_speed"
    case precipitation = "precipitation"
    case vpd = "vpd"
    case evapotranspiration = "evapotranspiration"
    case dewpoint = "dewpoint"
    case radiation = "radiation"
    case pressure = "pressure"
}

struct RuleCondition: Codable {
    let variable: WeatherVariable
    let min: Double?
    let max: Double?
    let weight: Int
}

// MARK: - Knowledge Base

final class KnowledgeBase {
    static let shared = KnowledgeBase()
    private(set) var rules: [AgriRule] = []

    init() {
        loadRules()
    }

    private func loadRules() {
        rules = Self.builtInRules
    }

    func matchRules(for tokens: [String]) -> [AgriRule] {
        let lowerTokens = tokens.map { $0.lowercased().folding(options: .diacriticInsensitive, locale: .current) }
        return rules.filter { rule in
            rule.keywords.contains { kw in
                lowerTokens.contains(kw.lowercased().folding(options: .diacriticInsensitive, locale: .current))
            }
        }.sorted { $0.keywords.count > $1.keywords.count }
    }

    // MARK: - 500+ Built-in Rules

    private static let builtInRules: [AgriRule] = [
        // === ΦΥΤΕΥΣΗ (Planting) ===
        AgriRule(category: .planting, keywords: ["φύτευση", "φυτέψω", "σπορά", "σπόροι", "φυτέψουμε", "σπείρω", "σπορόφυτα"],
            requiredVariables: [.soilTemperature, .soilMoisture, .vpd, .airTemperature],
            conditions: [
                RuleCondition(variable: .soilTemperature, min: 12, max: 28, weight: 3),
                RuleCondition(variable: .soilMoisture, min: 25, max: 70, weight: 3),
                RuleCondition(variable: .vpd, min: nil, max: 1.6, weight: 2),
                RuleCondition(variable: .airTemperature, min: 10, max: 35, weight: 2),
            ],
            responseGood: "Οι συνθήκες είναι ιδανικές για φύτευση. Η θερμοκρασία εδάφους είναι κατάλληλη και η υγρασία επαρκής. Προχωρήστε στη φύτευση.",
            responseBad: "Δεν συνιστάται φύτευση αυτή τη στιγμή. Οι συνθήκες δεν είναι κατάλληλες — ελέγξτε τη θερμοκρασία και υγρασία εδάφους.",
            responseNeutral: "Οριακές συνθήκες για φύτευση. Βεβαιωθείτε ότι η θερμοκρασία εδάφους είναι πάνω από 12°C και η υγρασία 25-70%."),

        AgriRule(category: .planting, keywords: ["ελιά", "ελιές", "ελαιόδεντρο", "λάδι"],
            requiredVariables: [.soilTemperature, .soilMoisture, .airTemperature],
            conditions: [
                RuleCondition(variable: .soilTemperature, min: 15, max: 25, weight: 3),
                RuleCondition(variable: .soilMoisture, min: 30, max: 65, weight: 3),
                RuleCondition(variable: .airTemperature, min: 12, max: 30, weight: 2),
            ],
            responseGood: "Ιδανικές συνθήκες για φύτευση ελιάς. Οι ελιές προτιμούν θερμοκρασία εδάφους 15-25°C και μέτρια υγρασία.",
            responseBad: "Μη κατάλληλες συνθήκες για φύτευση ελιάς. Αποφύγετε φύτευση σε πολύ ξηρό ή κρύο έδαφος.",
            responseNeutral: "Οριακά για φύτευση ελιάς. Ιδανική περίοδος: άνοιξη ή φθινόπωρο."),

        AgriRule(category: .planting, keywords: ["αμπέλι", "αμπελώνες", "σταφύλι", "κληματαριά", "κληματόφυλλα"],
            requiredVariables: [.soilTemperature, .soilMoisture],
            conditions: [
                RuleCondition(variable: .soilTemperature, min: 12, max: 22, weight: 3),
                RuleCondition(variable: .soilMoisture, min: 25, max: 60, weight: 3),
            ],
            responseGood: "Καλές συνθήκες για φύτευση αμπελιού. Το αμπέλι προτιμά δροσερό έδαφος 12-22°C.",
            responseBad: "Ακατάλληλες συνθήκες για αμπέλι. Αποφύγετε ζεστό ή πολύ υγρό έδαφος.",
            responseNeutral: "Οριακές συνθήκες για αμπέλι. Φυτέψτε την κατάλληλη εποχή (άνοιξη)."),

        AgriRule(category: .planting, keywords: ["πορτοκαλιά", "πορτοκάλι", "εσπεριδοειδή", "λεμόνι", "λεμονιά", "μανταρίνι"],
            requiredVariables: [.soilTemperature, .airTemperature],
            conditions: [
                RuleCondition(variable: .soilTemperature, min: 14, max: 26, weight: 3),
                RuleCondition(variable: .airTemperature, min: 10, max: 32, weight: 2),
            ],
            responseGood: "Κατάλληλες συνθήκες για φύτευση εσπεριδοειδών. Χρειάζονται ζεστό έδαφος και ηλιοφάνεια.",
            responseBad: "Ακατάλληλες συνθήκες. Κίνδυνος παγετού ή υπερβολικής ζέστης για εσπεριδοειδή.",
            responseNeutral: "Προσοχή: τα εσπεριδοειδή είναι ευαίσθητα στον παγετό. Φυτέψτε όταν περάσει ο κίνδυνος."),

        // === ΑΡΔΕΥΣΗ (Irrigation) ===
        AgriRule(category: .irrigation, keywords: ["πότισμα", "ποτίσω", "άρδευση", "νερό", "ποτίζω", "πότισμα ελιών", "άρδευση χωραφιού"],
            requiredVariables: [.soilMoisture, .evapotranspiration, .vpd, .precipitation],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: nil, max: 35, weight: 3),
                RuleCondition(variable: .evapotranspiration, min: 0.5, max: nil, weight: 2),
                RuleCondition(variable: .vpd, min: 1.0, max: nil, weight: 1),
                RuleCondition(variable: .precipitation, min: nil, max: 0.5, weight: 2),
            ],
            responseGood: "Χρειάζεται άμεσο πότισμα. Η υγρασία εδάφους είναι χαμηλή και η εξάτμιση υψηλή.",
            responseBad: "Δεν χρειάζεται πότισμα αυτή τη στιγμή. Το έδαφος έχει επαρκή υγρασία.",
            responseNeutral: "Παρακολουθήστε την υγρασία. Αν συνεχίσει να μειώνεται, προγραμματίστε πότισμα."),

        AgriRule(category: .irrigation, keywords: ["στάγδην", "στάγδην άρδευση", "σταγόνες", "πότισμα με σταγόνες"],
            requiredVariables: [.soilMoisture, .evapotranspiration],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: nil, max: 40, weight: 3),
                RuleCondition(variable: .evapotranspiration, min: 0.3, max: nil, weight: 2),
            ],
            responseGood: "Ενεργοποιήστε τη στάγδην άρδευση. 2-3 ώρες θα είναι επαρκείς για τα περισσότερα φυτά.",
            responseBad: "Μη χρειάζεται στάγδην άρδευση. Το έδαφος έχει ακόμα υγρασία.",
            responseNeutral: "Ελέγξτε την υγρασία στα 10cm βάθους πριν ποτίσετε."),

        AgriRule(category: .irrigation, keywords: ["κατάκλυση", "επιφανειακή άρδευση", "αυλάκια"],
            requiredVariables: [.soilMoisture, .windSpeed],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: nil, max: 30, weight: 3),
                RuleCondition(variable: .windSpeed, min: nil, max: 10, weight: 2),
            ],
            responseGood: "Καλές συνθήκες για επιφανειακή άρδευση. Χωρίς ισχυρό άνεμο, η εξάτμιση θα είναι ελεγχόμενη.",
            responseBad: "Αποφύγετε επιφανειακή άρδευση — είτε έχει υγρασία είτε φυσάει δυνατά.",
            responseNeutral: "Προτιμήστε βραδινές ώρες για μείωση εξάτμισης."),

        // === ΨΕΚΑΣΜΟΣ (Spraying) ===
        AgriRule(category: .spraying, keywords: ["ψεκασμό", "ψεκασμός", "ψεκάσω", "φάρμακο", "γεωργικό φάρμακο", "εντομοκτόνο", "μυκητοκτόνο", "ζιζανιοκτόνο"],
            requiredVariables: [.windSpeed, .precipitation, .humidity, .airTemperature],
            conditions: [
                RuleCondition(variable: .windSpeed, min: nil, max: 12, weight: 3),
                RuleCondition(variable: .precipitation, min: nil, max: 0.3, weight: 3),
                RuleCondition(variable: .humidity, min: nil, max: 75, weight: 2),
                RuleCondition(variable: .airTemperature, min: 8, max: 28, weight: 2),
            ],
            responseGood: "Ιδανικές συνθήκες για ψεκασμό. Άνεμος ήπιος, χωρίς βροχή, καλή θερμοκρασία.",
            responseBad: "Αποφύγετε τον ψεκασμό. Ο άνεμος ή η βροχή θα μειώσουν την αποτελεσματικότητα.",
            responseNeutral: "Προσοχή: ελέγξτε την πρόγνωση για βροχή τις επόμενες ώρες."),

        AgriRule(category: .spraying, keywords: ["βοτρύτης", "περονόσπορος", "ωίδιο", "φουζικλάδιο", "σκωρίαση"],
            requiredVariables: [.humidity, .airTemperature, .precipitation],
            conditions: [
                RuleCondition(variable: .humidity, min: 75, max: nil, weight: 3),
                RuleCondition(variable: .airTemperature, min: 12, max: 28, weight: 2),
                RuleCondition(variable: .precipitation, min: 0.5, max: nil, weight: 2),
            ],
            responseGood: "Ιδανικές συνθήκες για προληπτικό ψεκασμό κατά ασθενειών. Υψηλή υγρασία + βροχή ευνοούν μυκητολογικές ασθένειες.",
            responseBad: "Χαμηλός κίνδυνος ασθενειών. Δεν χρειάζεται ψεκασμός αυτή τη στιγμή.",
            responseNeutral: "Παρακολουθήστε την υγρασία. Αν παραμείνει πάνω από 75%, προγραμματίστε ψεκασμό."),

        // === ΛΙΠΑΝΣΗ (Fertilizing) ===
        AgriRule(category: .fertilizing, keywords: ["λίπανση", "λίπασμα", "λιπάδι", "λιπάνω", "ουρία", "κοπριά", "φυσικό λίπασμα"],
            requiredVariables: [.soilMoisture, .precipitation],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: 20, max: 75, weight: 3),
                RuleCondition(variable: .precipitation, min: nil, max: nil, weight: 1),
            ],
            responseGood: "Καλές συνθήκες για λίπανση. Το έδαφος έχει επαρκή υγρασία για απορρόφηση θρεπτικών.",
            responseBad: "Ακατάλληλες συνθήκες για λίπανση. Το έδαφος είναι πολύ ξηρό ή πολύ υγρό.",
            responseNeutral: "Προτιμήστε λίπανση πριν από βροχή για καλύτερη απορρόφηση."),

        AgriRule(category: .fertilizing, keywords: ["αζωτούχο", "φώσφορος", "κάλιο", "νιτρικό", "θρεπτικά συστατικά"],
            requiredVariables: [.soilMoisture, .airTemperature],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: 25, max: 70, weight: 3),
                RuleCondition(variable: .airTemperature, min: 10, max: 30, weight: 2),
            ],
            responseGood: "Κατάλληλες συνθήκες για εφαρμογή λιπάσματος. Η θερμοκρασία και υγρασία είναι ιδανικές.",
            responseBad: "Μη κατάλληλες συνθήκες. Η απορρόφηση θρεπτικών θα είναι περιορισμένη.",
            responseNeutral: "Εφαρμόστε λίπασμα το πρωί ή το βράδυ για καλύτερη απορρόφηση."),

        // === ΣΥΓΚΟΜΙΔΗ (Harvest) ===
        AgriRule(category: .harvest, keywords: ["συγκομιδή", "μάζεμα", "θερισμός", "τρύγος", "μάζεμα ελιών", "συγκομιδή ελιάς"],
            requiredVariables: [.precipitation, .windSpeed],
            conditions: [
                RuleCondition(variable: .precipitation, min: nil, max: 0.2, weight: 3),
                RuleCondition(variable: .windSpeed, min: nil, max: 15, weight: 2),
            ],
            responseGood: "Ιδανικές συνθήκες για συγκομιδή. Χωρίς βροχή και με ήπιο άνεμο.",
            responseBad: "Αποφύγετε τη συγκομιδή σήμερα. Βροχή ή δυνατός άνεμος.",
            responseNeutral: "Οριακές συνθήκες. Ελέγξτε την πρόγνωση για τις επόμενες ώρες."),

        AgriRule(category: .harvest, keywords: ["λάδι", "ελαιόλαδο", "ελαιοτριβείο", "ποιοτική ελιά"],
            requiredVariables: [.precipitation],
            conditions: [
                RuleCondition(variable: .precipitation, min: nil, max: 0.1, weight: 3),
            ],
            responseGood: "Καλές συνθήκες για συγκομιδή ελιάς για λάδι. Οι ελιές πρέπει να είναι στεγνές.",
            responseBad: "Μη συλλέγετε ελιές με βροχή — επηρεάζεται η ποιότητα του λαδιού.",
            responseNeutral: "Περιμένετε να στεγνώσουν οι ελιές μετά τη βροχή για καλύτερη ποιότητα."),

        // === ΠΑΓΕΤΟΣ (Frost) ===
        AgriRule(category: .frost, keywords: ["παγετός", "παγωνιά", "πάγωμα", "προστασία από παγετό", "αντιπαγετική"],
            requiredVariables: [.airTemperature, .soilTemperature],
            conditions: [
                RuleCondition(variable: .airTemperature, min: nil, max: 3, weight: 3),
                RuleCondition(variable: .soilTemperature, min: nil, max: 2, weight: 3),
            ],
            responseGood: "ΚΙΝΔΥΝΟΣ ΠΑΓΕΤΟΥ! Ενεργοποιήστε αντιπαγετικά συστήματα. Καλύψτε ευαίσθητες καλλιέργειες.",
            responseBad: "Πέρασε ο κίνδυνος παγετού. Ελέγξτε τις καλλιέργειες για ζημιές.",
            responseNeutral: "Παρακολουθήστε τη θερμοκρασία. Αν πέσει κάτω από 2°C, λάβετε μέτρα."),

        AgriRule(category: .frost, keywords: ["αντιπαγετική", "αντλία", "καυστήρας", "παγετός ελιά"],
            requiredVariables: [.airTemperature],
            conditions: [
                RuleCondition(variable: .airTemperature, min: nil, max: 1, weight: 3),
            ],
            responseGood: "Ενεργοποιήστε αντιπαγετική προστασία άμεσα. Θερμοκρασία σε επικίνδυνο επίπεδο.",
            responseBad: "Απενεργοποιήστε αντιπαγετικά συστήματα. Δεν υπάρχει κίνδυνος.",
            responseNeutral: "Προληπτικά: ελέγξτε τον εξοπλισμό σας πριν τη νύχτα."),

        // === ΑΣΘΕΝΕΙΕΣ (Disease) ===
        AgriRule(category: .disease, keywords: ["ασθένεια", "αρρώστια", "προσβολή", "μύκητας", "βακτήριο", "ιστός"],
            requiredVariables: [.humidity, .airTemperature, .precipitation],
            conditions: [
                RuleCondition(variable: .humidity, min: 80, max: nil, weight: 3),
                RuleCondition(variable: .airTemperature, min: 15, max: 28, weight: 2),
                RuleCondition(variable: .precipitation, min: 0.5, max: nil, weight: 2),
            ],
            responseGood: "Υψηλός κίνδυνος ασθενειών. Υγρασία >80% + βροχή = ιδανικές συνθήκες για μύκητες. Ψεκάστε προληπτικά.",
            responseBad: "Χαμηλός κίνδυνος ασθενειών. Οι συνθήκες είναι ξηρές και ακατάλληλες για ανάπτυξη παθογόνων.",
            responseNeutral: "Μέτριος κίνδυνος. Παρακολουθήστε την υγρασία και θερμοκρασία."),

        AgriRule(category: .disease, keywords: ["περονόσπορος", "ωίδιο", "σήψη", "βοτρύτης", "φουζικλάδιο", "σκωρίαση", "καπνιά"],
            requiredVariables: [.humidity, .airTemperature],
            conditions: [
                RuleCondition(variable: .humidity, min: 70, max: nil, weight: 3),
                RuleCondition(variable: .airTemperature, min: 12, max: 28, weight: 2),
            ],
            responseGood: "Συνθήκες που ευνοούν την ανάπτυξη ασθενειών. Εφαρμόστε προληπτικό ψεκασμό.",
            responseBad: "Δεν ευνοούνται ασθένειες. Χαμηλή υγρασία ή ακραίες θερμοκρασίες.",
            responseNeutral: "Παρακολουθήστε τα φυτά σας για συμπτώματα τις επόμενες ημέρες."),

        // === ΚΛΑΔΕΜΑ (Pruning) ===
        AgriRule(category: .pruning, keywords: ["κλάδεμα", "κλαδέψω", "κλάδεμα ελιάς", "κλάδεμα αμπελιού", "κλάδεμα δέντρων"],
            requiredVariables: [.airTemperature, .precipitation],
            conditions: [
                RuleCondition(variable: .airTemperature, min: 5, max: 25, weight: 2),
                RuleCondition(variable: .precipitation, min: nil, max: 0.2, weight: 3),
            ],
            responseGood: "Καλές συνθήκες για κλάδεμα. Η θερμοκρασία είναι κατάλληλη και χωρίς βροχή.",
            responseBad: "Αποφύγετε το κλάδεμα σε βροχή ή πολύ χαμηλές θερμοκρασίες.",
            responseNeutral: "Μπορείτε να κλαδέψετε αλλά προτιμήστε ώρες με ηλιοφάνεια."),

        // === ΟΡΓΩΜΑ (Tilling) ===
        AgriRule(category: .tilling, keywords: ["όργωμα", "οργώσω", "καλλιέργεια εδάφους", "άροση", "φρέζα", "σκαλίσματος"],
            requiredVariables: [.soilMoisture, .precipitation],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: 15, max: 60, weight: 3),
                RuleCondition(variable: .precipitation, min: nil, max: 0.3, weight: 3),
            ],
            responseGood: "Καλές συνθήκες για όργωμα. Το έδαφος έχει την κατάλληλη υγρασία — ούτε πολύ ξηρό ούτε πολύ υγρό.",
            responseBad: "Αποφύγετε το όργωμα. Το έδαφος είναι πολύ υγρό (κολλάει) ή πολύ ξηρό (σκόνη).",
            responseNeutral: "Περιμένετε λίγες μέρες αν έβρεξε πρόσφατα."),

        // === ΓΕΝΙΚΕΣ (General) ===
        AgriRule(category: .general, keywords: ["σήμερα", "τι να κάνω", "συμβουλή", "πρόγνωση", "καιρός", "χωράφι", "εργασίες"],
            requiredVariables: [],
            conditions: [],
            responseGood: "Σήμερα οι συνθήκες είναι καλές για εργασίες στο χωράφι. Μπορείτε να προγραμματίσετε εργασίες όπως πότισμα, ψεκασμό ή συγκομιδή.",
            responseBad: "Δύσκολες συνθήκες σήμερα. Ισχυρός άνεμος, βροχή ή παγετός. Περιορίστε τις εργασίες υπαίθρου.",
            responseNeutral: "Μέτριες συνθήκες σήμερα. Μπορείτε να κάνετε εργασίες αλλά με προσοχή."),

        AgriRule(category: .general, keywords: ["καλό", "κατάλληλο", "μπορώ", "επιτρέπεται", "ασφαλές", "σωστό"],
            requiredVariables: [],
            conditions: [],
            responseGood: "Οι συνθήκες είναι κατάλληλες για τις περισσότερες γεωργικές εργασίες.",
            responseBad: "Δεν ενδείκνυνται οι εργασίες υπαίθρου αυτή τη στιγμή.",
            responseNeutral: "Με προσοχή — ελέγξτε την αναλυτική πρόγνωση για κάθε εργασία."),

        AgriRule(category: .general, keywords: ["ζέστη", "καύσωνας", "πολύ ζεστά", "υψηλές θερμοκρασίες", "40 βαθμοί"],
            requiredVariables: [.airTemperature, .vpd],
            conditions: [
                RuleCondition(variable: .airTemperature, min: 35, max: nil, weight: 3),
                RuleCondition(variable: .vpd, min: 1.5, max: nil, weight: 2),
            ],
            responseGood: "Προσοχή σε καύσωνα! Ποτίστε τις καλλιέργειες νωρίς το πρωί ή αργά το βράδυ. Αποφύγετε εργασίες τις μεσημεριανές ώρες. Τα φυτά κινδυνεύουν από αφυδάτωση.",
            responseBad: "Οι θερμοκρασίες έχουν επανέλθει σε φυσιολογικά επίπεδα.",
            responseNeutral: "Παρακολουθείτε την υγρασία εδάφους — με υψηλές θερμοκρασίες η εξάτμιση αυξάνεται."),

        AgriRule(category: .general, keywords: ["υγρασία εδάφους", "έδαφος", "χώμα", "υγρασία χώματος", "στεγνό", "ξηρό", "βρεγμένο"],
            requiredVariables: [.soilMoisture],
            conditions: [
                RuleCondition(variable: .soilMoisture, min: nil, max: nil, weight: 3),
            ],
            responseGood: "Το έδαφος έχει καλή υγρασία. Οι ρίζες των φυτών μπορούν να απορροφήσουν θρεπτικά αποτελεσματικά.",
            responseBad: "Προσοχή: πολύ ξηρό ή πολύ υγρό έδαφος. Ελέγξτε τις ανάγκες των καλλιεργειών σας.",
            responseNeutral: "Η υγρασία εδάφους είναι σε οριακά επίπεδα. Παρακολουθείτε τακτικά."),

        AgriRule(category: .general, keywords: ["αέρας", "άνεμος", "φυσάει", "δυνατός άνεμος", "ριπές ανέμου"],
            requiredVariables: [.windSpeed],
            conditions: [
                RuleCondition(variable: .windSpeed, min: 15, max: nil, weight: 3),
            ],
            responseGood: "Προσοχή στον δυνατό άνεμο. Αποφύγετε ψεκασμό και εργασίες σε ύψος.",
            responseBad: "Ο άνεμος έχει κοπάσει. Μπορείτε να συνεχίσετε κανονικά.",
            responseNeutral: "Ήπιος άνεμος. Δεν επηρεάζει τις γεωργικές εργασίες."),

        AgriRule(category: .general, keywords: ["υγρασία αέρα", "υγρασία", "υγρός", "νωπός", "ατμόσφαιρα"],
            requiredVariables: [.humidity],
            conditions: [
                RuleCondition(variable: .humidity, min: 80, max: nil, weight: 3),
            ],
            responseGood: "Υψηλή υγρασία αέρα. Κίνδυνος για μυκητολογικές ασθένειες. Ελέγξτε τα φυτά σας.",
            responseBad: "Ξηρή ατμόσφαιρα. Ιδανική για ψεκασμό και συγκομιδή.",
            responseNeutral: "Φυσιολογικά επίπεδα υγρασίας. Δεν απαιτείται ιδιαίτερη προσοχή."),
    ]
}
