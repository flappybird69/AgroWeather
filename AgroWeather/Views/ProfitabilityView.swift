import SwiftUI

struct ProfitabilityView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var logEntries: [FarmLogEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ΑΠΟΔΟΤΙΚΟΤΗΤΑ ΧΩΡΑΦΙΩΝ")
                .font(.caption.weight(.semibold)).foregroundColor(.secondary).tracking(1).padding(.leading, 4)

            VStack(spacing: 0) {
                if viewModel.fields.isEmpty {
                    Text("Δεν υπάρχουν χωράφια ή καταγραφές").font(.caption).foregroundColor(.secondary).padding(20)
                } else {
                    ForEach(viewModel.fields) { field in
                        let data = fieldData(field)
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(field.name).font(.subheadline.weight(.semibold))
                                HStack(spacing: 8) {
                                    Label("\(String(format: "%.0f€", data.income))", systemImage: "arrow.down")
                                        .font(.caption).foregroundColor(.green)
                                    Label("\(String(format: "%.0f€", data.expenses))", systemImage: "arrow.up")
                                        .font(.caption).foregroundColor(.red)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(data.profit >= 0 ? "Κέρδος" : "Ζημιά")
                                    .font(.caption.weight(.medium))
                                    .foregroundColor(data.profit >= 0 ? .green : .red)
                                Text("\(String(format: "%.0f€", data.profit))")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(data.profit >= 0 ? .green : .red)
                            }
                        }
                        .padding(12)
                        if field.id != viewModel.fields.last?.id { Divider().padding(.leading, 12) }
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .task { loadEntries() }
        }
    }

    private var allEntries: [FarmLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: "farm_log_entries") else { return [] }
        return (try? JSONDecoder().decode([FarmLogEntry].self, from: data)) ?? []
    }

    private func loadEntries() {
        logEntries = allEntries
    }

    private func fieldData(_ field: Field) -> (income: Double, expenses: Double, profit: Double) {
        let entries = logEntries.filter { $0.fieldName == field.name }
        let income = entries.compactMap(\.income).reduce(0, +)
        let expenses = entries.reduce(0) { $0 + $1.totalExpenses + ($1.cost ?? 0) }
        return (income, expenses, income - expenses)
    }
}
