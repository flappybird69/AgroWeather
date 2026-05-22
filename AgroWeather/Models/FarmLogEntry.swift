import Foundation
import SwiftUI

struct ExpenseItem: Identifiable, Codable {
    let id: UUID
    var category: ExpenseCategory
    var amount: Double
    var notes: String

    init(category: ExpenseCategory, amount: Double, notes: String = "") {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.notes = notes
    }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case fuel = "Καύσιμα"
    case supplies = "Εφόδια"
    case labor = "Εργατικά"
    case maintenance = "Συντήρηση"
    case equipment = "Μηχανήματα"
    case other = "Άλλο"
}

enum GrowthStage: String, Codable, CaseIterable {
    case germination = "Βλάστηση"
    case flowering = "Ανθοφορία"
    case fruitSet = "Καρπόδεση"
    case ripening = "Ωρίμανση"
    case harvest = "Συγκομιδή"
}

struct FarmLogEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let type: ActivityType
    let notes: String
    let fieldName: String?
    let duration: Int?
    let amount: Double?
    let amountUnit: String?
    let cost: Double?
    let reminderDate: Date?
    let imageFilenames: [String]

    // New — Καλλιέργεια
    let crop: String?
    let growthStage: String?
    let plantingDate: Date?

    // New — Φυτοπροστασία (spraying)
    let chemicalName: String?
    let dosage: Double?
    let phiDays: Int?
    let phiDate: Date?

    // New — Συγκομιδή
    let yieldAmount: Double?
    let yieldUnit: String?
    let yieldQuality: String?

    // New — Οικονομικά
    let income: Double?
    let expenses: [ExpenseItem]

    // New — Μηχανήματα
    let equipmentHours: Int?
    let equipmentNotes: String?

    // Computed — PHI countdown
    var phiRemainingDays: Int? {
        guard let phi = phiDate else { return nil }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: phi).day
        return remaining.map { max(0, $0) }
    }

    var formattedDuration: String? {
        guard let d = duration else { return nil }
        if d < 60 { return "\(d) λεπτά" }
        return "\(d / 60) ώρες \(d % 60) λεπτά"
    }

    var formattedAmount: String? {
        guard let a = amount else { return nil }
        return "\(String(format: "%.1f", a)) \(amountUnit ?? "")"
    }

    var formattedCost: String? {
        guard let c = cost else { return nil }
        return String(format: "%.2f€", c)
    }

    var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    var netProfit: Double? {
        guard let inc = income else { return nil }
        return inc - totalExpenses
    }

    init(type: ActivityType, notes: String, fieldName: String?,
         duration: Int? = nil, amount: Double? = nil, amountUnit: String? = nil,
         cost: Double? = nil, reminderDate: Date? = nil,
         imageFilenames: [String] = [],
         crop: String? = nil, growthStage: String? = nil, plantingDate: Date? = nil,
         chemicalName: String? = nil, dosage: Double? = nil,
         phiDays: Int? = nil, phiDate: Date? = nil,
         yieldAmount: Double? = nil, yieldUnit: String? = nil, yieldQuality: String? = nil,
         income: Double? = nil, expenses: [ExpenseItem] = [],
         equipmentHours: Int? = nil, equipmentNotes: String? = nil) {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.notes = notes
        self.fieldName = fieldName
        self.duration = duration
        self.amount = amount
        self.amountUnit = amountUnit
        self.cost = cost
        self.reminderDate = reminderDate
        self.imageFilenames = imageFilenames
        self.crop = crop
        self.growthStage = growthStage
        self.plantingDate = plantingDate
        self.chemicalName = chemicalName
        self.dosage = dosage
        self.phiDays = phiDays
        self.phiDate = phiDate
        self.yieldAmount = yieldAmount
        self.yieldUnit = yieldUnit
        self.yieldQuality = yieldQuality
        self.income = income
        self.expenses = expenses
        self.equipmentHours = equipmentHours
        self.equipmentNotes = equipmentNotes
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case watering = "Πότισμα"
    case spraying = "Ψεκασμός"
    case planting = "Φύτευση"
    case harvest = "Συγκομιδή"
    case fertilizing = "Λίπανση"
    case pruning = "Κλάδεμα"
    case tilling = "Όργωμα"
    case disease = "Ασθένεια"
    case observation = "Παρατήρηση"
    case installation = "Εγκατάσταση"
    case finance = "Οικονομικά"
    case equipment = "Μηχανήματα"
    case other = "Άλλο"

    var icon: String {
        switch self {
        case .watering: return "drop.fill"
        case .spraying: return "wind"
        case .planting: return "leaf.fill"
        case .harvest: return "shippingbox.fill"
        case .fertilizing: return "sparkles"
        case .pruning: return "scissors"
        case .tilling: return "wrench.adjustable.fill"
        case .disease: return "cross.case.fill"
        case .observation: return "eye.fill"
        case .installation: return "puzzlepiece.extension.fill"
        case .finance: return "eurosign.circle.fill"
        case .equipment: return "gearshape.fill"
        case .other: return "clipboard.fill"
        }
    }

    var color: Color {
        switch self {
        case .watering: return .blue
        case .spraying: return .orange
        case .planting: return .green
        case .harvest: return .yellow
        case .fertilizing: return .purple
        case .pruning: return .brown
        case .tilling: return .brown
        case .disease: return .red
        case .observation: return .teal
        case .installation: return .cyan
        case .finance: return .green
        case .equipment: return .gray
        case .other: return .gray
        }
    }

    var amountLabel: String? {
        switch self {
        case .watering: return "Ποσότητα νερού (L)"
        case .spraying: return "Ποσότητα ψεκαστικού (L)"
        case .planting: return "Αριθμός φυτών"
        case .harvest: return "Ποσότητα (kg)"
        case .fertilizing: return "Ποσότητα λιπάσματος (kg)"
        default: return nil
        }
    }

    var showDuration: Bool {
        switch self {
        case .watering, .spraying, .tilling, .pruning, .installation: return true
        default: return false
        }
    }
}

let cropOptions = [
    "Ελιά Κορωνέικη", "Ελιά Λαδοελιά", "Ελιά Καλαμών",
    "Αμπέλι Σαββατιανό", "Αμπέλι Αγιωργίτικο", "Αμπέλι Ξινόμαυρο",
    "Πορτοκαλιά", "Λεμονιά", "Μανταρινιά",
    "Βαμβάκι", "Καλαμπόκι", "Σιτάρι", "Κριθάρι",
    "Ντομάτα", "Αγγούρι", "Πιπεριά", "Μελιτζάνα",
    "Καρπούζι", "Πεπόνι", "Κολοκύθι",
    "Τριφύλλι", "Μηδική",
    "Αμυγδαλιά", "Καρυδιά", "Φιστικιά",
    "Άλλο"
]
