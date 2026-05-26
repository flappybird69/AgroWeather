import SwiftUI

struct FarmLogView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var logEntries: [FarmLogEntry] = []
    @State private var showAddEntry = false
    @State private var sprayMode = false

    private var filteredEntries: [FarmLogEntry] {
        sprayMode ? logEntries.filter { $0.type == .spraying } : logEntries
    }

    private let logKey = "farm_log_entries"
    private let cloudLogKey = "icloud_farm_log_entries"

    var body: some View {
        Group {
            if logEntries.isEmpty {
                emptyState
            } else {
                content
            }
        }
        .task {
            loadEntries()
            await preloadImages()
        }
        .sheet(isPresented: $showAddEntry) {
            AddLogEntryView { entry in
                logEntries.insert(entry, at: 0)
                saveEntries()
                        if entry.reminderDate != nil {
                            let enabled = UserDefaults.standard.bool(forKey: "reminders_enabled")
                            if enabled { Task { await ReminderManager.shared.scheduleReminder(for: entry) } }
                        }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "book.fill")
                .font(.system(size: 48))
                .foregroundColor(.agroGreen.opacity(0.3))
            Text("Ημερολόγιο Εργασιών")
                .font(.headline)
            Text("Καταγράψτε κάθε εργασία στο χωράφι σας\nμε χρόνο, ποσότητες, κόστη και υπενθυμίσεις")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            Button {
                showAddEntry = true
            } label: {
                Label("Νέα Καταγραφή", systemImage: "plus.circle.fill")
                    .font(.headline).foregroundColor(.white)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(Color.agroGreen).clipShape(Capsule())
            }
            Spacer()
        }
        .padding()
    }

    private var content: some View {
        List {
            if sprayMode && filteredEntries.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "wind").font(.system(size: 36)).foregroundColor(.orange.opacity(0.3))
                        Text("Δεν υπάρχουν καταγεγραμμένοι ψεκασμοί")
                            .font(.subheadline).foregroundColor(.secondary)
                        Text("Οι ψεκασμοί καταγράφονται από το Ημερολόγιο → Νέα Καταγραφή → Ψεκασμός")
                            .font(.caption).foregroundColor(.secondary.opacity(0.7)).multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity).padding(20)
                    .listRowBackground(Color.clear)
                }
            }
            ForEach(filteredEntries) { entry in
                logRow(entry)
            }
            .onDelete { indexSet in
                indexSet.forEach {
                    let entry = logEntries[$0]
                    Task { await ReminderManager.shared.cancelReminder(for: entry) }
                    logEntries.remove(at: $0)
                }
                saveEntries()
            }
        }
        .background(Color(.systemGroupedBackground))
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack { Spacer(); ChatBubble(); Spacer() }
                .padding(.top, 4).padding(.bottom, 4)
                .background(Color(.systemGroupedBackground))
        }
        .scrollContentBackground(.hidden)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 4) {
                    Button {
                        sprayMode.toggle()
                    } label: {
                        Image(systemName: sprayMode ? "wind.circle.fill" : "wind")
                            .font(.title3).foregroundColor(sprayMode ? .orange : .agroGreen)
                    }
                    Button {
                        exportCSV()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3).foregroundColor(.agroGreen)
                    }
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3).foregroundColor(.agroGreen)
                    }
                }
            }
        }
    }

    private func logRow(_ entry: FarmLogEntry) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(entry.type.color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: entry.type.icon)
                        .font(.subheadline)
                        .foregroundColor(entry.type.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.type.rawValue)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(entry.date, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if entry.reminderDate != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.orange)
                            Text("Υπενθύμιση")
                                .font(.system(size: 9))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }

            if !entry.notes.isEmpty {
                Text(entry.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let crop = entry.crop {
                HStack(spacing: 6) {
                    Image(systemName: "leaf.fill").font(.system(size: 8)).foregroundColor(.green)
                    Text(crop).font(.system(size: 10)).foregroundColor(.secondary)
                    if let stage = entry.growthStage {
                        Text("· \(stage)").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }

            if let phiRemaining = entry.phiRemainingDays {
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 8))
                        .foregroundColor(phiRemaining == 0 ? .red : .orange)
                    Text("PHI: \(phiRemaining) ημέρες")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(phiRemaining == 0 ? .red : .orange)
                    if let name = entry.chemicalName {
                        Text("· \(name)").font(.system(size: 9)).foregroundColor(.secondary)
                    }
                }
            }

            if let yield = entry.yieldAmount {
                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill").font(.system(size: 8)).foregroundColor(.yellow)
                    Text("Απόδοση: \(String(format: "%.1f", yield)) \(entry.yieldUnit ?? "kg")")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                    if let q = entry.yieldQuality {
                        Text("· \(q)").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }

            if entry.totalExpenses > 0 || entry.income != nil {
                HStack(spacing: 6) {
                    if let inc = entry.income {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.down").font(.system(size: 7)).foregroundColor(.green)
                            Text("\(String(format: "%.0f€", inc))").font(.system(size: 10)).foregroundColor(.green)
                        }
                    }
                    if entry.totalExpenses > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up").font(.system(size: 7)).foregroundColor(.red)
                            Text("\(String(format: "%.0f€", entry.totalExpenses))").font(.system(size: 10)).foregroundColor(.red)
                        }
                    }
                    if let profit = entry.netProfit {
                        HStack(spacing: 3) {
                            Image(systemName: profit >= 0 ? "plus" : "minus").font(.system(size: 7))
                            Text("Καθαρό: \(String(format: "%.0f€", profit))")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(profit >= 0 ? .green : .red)
                        }
                    }
                }
            }

            if let hours = entry.equipmentHours {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill").font(.system(size: 8)).foregroundColor(.secondary)
                    Text("\(hours) ώρες λειτ.").font(.system(size: 10)).foregroundColor(.secondary)
                    if let eqNotes = entry.equipmentNotes {
                        Text("· \(eqNotes)").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                if let duration = entry.formattedDuration {
                    HStack(spacing: 3) {
                        Image(systemName: "clock.fill").font(.system(size: 8))
                        Text(duration).font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                if let amount = entry.formattedAmount {
                    HStack(spacing: 3) {
                        Image(systemName: "scalemass.fill").font(.system(size: 8))
                        Text(amount).font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                if let cost = entry.formattedCost {
                    HStack(spacing: 3) {
                        Image(systemName: "eurosign.circle.fill").font(.system(size: 8))
                        Text(cost).font(.system(size: 10))
                    }
                    .foregroundColor(.secondary)
                }
                if let fieldName = entry.fieldName {
                    HStack(spacing: 3) {
                        Image(systemName: "map.fill").font(.system(size: 8))
                        Text(fieldName).font(.system(size: 10))
                    }
                    .foregroundColor(.agroGreen.opacity(0.7))
                }
                Spacer()
            }

            if !entry.imageFilenames.isEmpty {
                logImages(entry)
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func logImages(_ entry: FarmLogEntry) -> some View {
        if !entry.imageFilenames.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 6) {
                    ForEach(entry.imageFilenames, id: \.self) { name in
                        if let img = ImageManager.shared.cachedImage(name) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
                .frame(height: 60)
            }
        }
    }

    private func loadEntries() {
        if let data = cloudStore.data(forKey: cloudLogKey),
           let cloud = try? JSONDecoder().decode([FarmLogEntry].self, from: data) {
            logEntries = cloud.sorted { $0.date > $1.date }
            saveLocal()
            return
        }
        guard let data = UserDefaults.standard.data(forKey: logKey) else { return }
        logEntries = (try? JSONDecoder().decode([FarmLogEntry].self, from: data)) ?? []
    }

    private func saveEntries() {
        saveLocal()
        pushToCloud()
    }

    private func saveLocal() {
        guard let data = try? JSONEncoder().encode(logEntries) else { return }
        UserDefaults.standard.set(data, forKey: logKey)
    }

    private func pushToCloud() {
        guard let data = try? JSONEncoder().encode(logEntries) else { return }
        cloudStore.set(data, forKey: cloudLogKey)
        cloudStore.synchronize()
    }

    private func exportCSV() {
        var csv = "Ημερομηνία,Τύπος,Περιγραφή,Χωράφι,Διάρκεια,Ποσότητα,Κόστος,Έσοδα,Έξοδα,Φυτό,Φάρμακο,PHI,Απόδοση\n"
        let f = DateFormatter()
        f.locale = Locale(identifier: "el_GR")
        f.dateFormat = "dd/MM/yyyy HH:mm"

        for e in logEntries {
            let date = f.string(from: e.date)
            let type = e.type.rawValue
            let notes = e.notes.replacingOccurrences(of: ",", with: " ")
            let field = e.fieldName ?? ""
            let duration = e.formattedDuration ?? ""
            let amount = e.formattedAmount ?? ""
            let cost = e.formattedCost ?? ""
            let income = e.income.map { String(format: "%.2f€", $0) } ?? ""
            let expenses = e.totalExpenses > 0 ? String(format: "%.2f€", e.totalExpenses) : ""
            let crop = e.crop ?? ""
            let chem = e.chemicalName ?? ""
            let phi = e.phiDays.map { "\($0) ημέρες" } ?? ""
            let yield_ = e.yieldAmount.map { "\($0) \(e.yieldUnit ?? "kg")" } ?? ""
            csv += "\(date),\(type),\(notes),\(field),\(duration),\(amount),\(cost),\(income),\(expenses),\(crop),\(chem),\(phi),\(yield_)\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("AgroWeather_Ημερολόγιο.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)

        let av = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = windowScene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }

    private func preloadImages() async {
        let names = logEntries.flatMap(\.imageFilenames).filter {
            ImageManager.shared.cachedImage($0) == nil
        }
        await withTaskGroup(of: Void.self) { group in
            for name in names {
                group.addTask { _ = await ImageManager.shared.loadImage(name) }
            }
        }
    }

    private var cloudStore: NSUbiquitousKeyValueStore { .default }
}

// MARK: - Add Entry View

struct AddLogEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(WeatherViewModel.self) private var viewModel
    @State private var selectedType: ActivityType = .watering
    @State private var notes = ""
    @State private var selectedField: String? = nil
    @State private var duration: Int? = nil
    @State private var amount: Double? = nil
    @State private var cost: Double? = nil
    @State private var enableReminder = false
    @State private var reminderDate = Date().addingTimeInterval(3600)
    @State private var showDurationField = false
    @State private var showAmountField = false
    @State private var attachedImages: [UIImage] = []
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var crop = ""
    @State private var growthStage = ""
    @State private var chemicalName = ""
    @State private var dosage: Double? = nil
    @State private var phiDays: Int? = nil
    @State private var yieldAmount: Double? = nil
    @State private var yieldQuality = ""
    @State private var yieldUnit = "kg"
    @State private var income: Double? = nil
    @State private var expenseAmount: Double? = nil
    @State private var expenseCategory: ExpenseCategory = .supplies
    @State private var expenseNotes = ""
    @State private var equipmentHours: Int? = nil
    @State private var equipmentNotes = ""
    let onSave: (FarmLogEntry) -> Void
    @FocusState private var focusedField: String?

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    typePicker
                    formFields
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.immediately)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Νέα Καταγραφή")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Ακύρωση") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) { Button("Αποθήκευση") { Task { await save() } }.fontWeight(.semibold) }
                ToolbarItem(placement: .keyboard) {
                    Button("Τέλος") { focusedField = nil }
                        .fontWeight(.medium)
                        .foregroundColor(.agroGreen)
                }
            }
            .onChange(of: selectedType) { _, _ in resetFields() }
        }
        .tint(.agroGreen)
        .task { _ = await ReminderManager.shared.requestAuthorization() }
    }

    private func resetFields() {
        notes = ""
        duration = nil
        amount = nil
        cost = nil
        crop = ""
        growthStage = ""
        chemicalName = ""
        dosage = nil
        phiDays = nil
        yieldAmount = nil
        yieldQuality = ""
        income = nil
        expenseAmount = nil
        expenseNotes = ""
        equipmentHours = nil
        equipmentNotes = ""
        attachedImages = []
        enableReminder = false
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ΤΥΠΟΣ ΕΡΓΑΣΙΑΣ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
                .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 95))], spacing: 10) {
                ForEach(ActivityType.allCases, id: \.rawValue) { type in
                    Button {
                        selectedType = type
                        showDurationField = type.showDuration
                        showAmountField = type.amountLabel != nil
                        HapticManager.selection()
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: type.icon)
                                .font(.title3)
                            Text(type.rawValue)
                                .font(.system(size: 10, weight: .medium))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .padding(6)
                        .background(selectedType == type ? type.color.opacity(0.15) : Color(.secondarySystemGroupedBackground))
                        .foregroundColor(selectedType == type ? type.color : .primary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedType == type ? type.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var formFields: some View {
        VStack(spacing: 14) {
            section("ΠΕΡΙΓΡΑΦΗ") {
                TextField("Π.χ. Πότισμα ελιών, 2 ώρες, 3 στρέμματα", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
            }

            if showDurationField || showAmountField {
                section("ΠΟΣΟΤΗΤΕΣ") {
                    if showDurationField {
                        row(label: "Διάρκεια") {
                            Picker("", selection: $duration) {
                                Text("—").tag(nil as Int?)
                                ForEach(Array(stride(from: 15, to: 481, by: 15)), id: \.self) { min in
                                    Text("\(min / 60) ώρ. \(min % 60) λεπ.").tag(min as Int?)
                                }
                            }
                            .tint(.agroGreen)
                        }
                    }
                    if showAmountField, let label = selectedType.amountLabel {
                        row(label: label) {
                            TextField("0", value: $amount, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    row(label: "Κόστος (€)") {
                        TextField("0", value: $cost, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            if selectedType == .planting {
                section("ΚΑΛΛΙΕΡΓΕΙΑ") {
                    row(label: "Ποικιλία") {
                        Picker("", selection: $crop) {
                            Text("—").tag("")
                            ForEach(cropOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .tint(.agroGreen)
                    }
                    row(label: "Στάδιο") {
                        Picker("", selection: $growthStage) {
                            Text("—").tag("")
                            ForEach(GrowthStage.allCases, id: \.rawValue) { stage in
                                Text(stage.rawValue).tag(stage.rawValue)
                            }
                        }
                        .tint(.agroGreen)
                    }
                }
            }

            if selectedType == .spraying {
                section("ΦΥΤΟΠΡΟΣΤΑΣΙΑ") {
                    row(label: "Σκεύασμα") {
                        TextField("Όνομα φαρμάκου", text: $chemicalName)
                            .multilineTextAlignment(.trailing)
                    }
                    row(label: "Δοσολογία") {
                        HStack {
                            TextField("0", value: $dosage, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 50)
                            Text("γρ./στρ.")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    row(label: "PHI") {
                        Picker("", selection: $phiDays) {
                            Text("—").tag(nil as Int?)
                            ForEach([0, 1, 2, 3, 5, 7, 10, 14, 21, 30, 45, 60], id: \.self) { d in
                                Text("\(d) ημέρες").tag(d as Int?)
                            }
                        }
                        .tint(.agroGreen)
                    }
                }
            }

            if selectedType == .harvest {
                section("ΣΥΓΚΟΜΙΔΗ") {
                    row(label: "Ποσότητα") {
                        HStack {
                            TextField("0", value: $yieldAmount, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Picker("", selection: $yieldUnit) {
                                Text("kg").tag("kg")
                                Text("τόνοι").tag("τόνοι")
                            }
                            .tint(.agroGreen)
                        }
                    }
                    row(label: "Ποιότητα") {
                        Picker("", selection: $yieldQuality) {
                            Text("—").tag("")
                            Text("Έξτρα Παρθένο").tag("Έξτρα Παρθένο")
                            Text("Κατηγορία Α").tag("Κατηγορία Α")
                            Text("Κατηγορία Β").tag("Κατηγορία Β")
                            Text("Βιολογικό").tag("Βιολογικό")
                            Text("Συμβατικό").tag("Συμβατικό")
                        }
                        .tint(.agroGreen)
                    }
                }
            }

            if selectedType == .finance {
                section("ΟΙΚΟΝΟΜΙΚΑ") {
                    row(label: "Έσοδα (€)") {
                        TextField("0", value: $income, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    row(label: "Κατηγορία εξόδου") {
                        Picker("", selection: $expenseCategory) {
                            ForEach(ExpenseCategory.allCases, id: \.rawValue) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .tint(.agroGreen)
                    }
                    row(label: "Ποσό εξόδου (€)") {
                        TextField("0", value: $expenseAmount, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    row(label: "Σημείωση") {
                        TextField("Π.χ. πετρέλαιο 50L", text: $expenseNotes)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            if selectedType == .equipment {
                section("ΜΗΧΑΝΗΜΑΤΑ") {
                    row(label: "Ώρες λειτουργίας") {
                        Picker("", selection: $equipmentHours) {
                            Text("—").tag(nil as Int?)
                            ForEach(Array(stride(from: 1, to: 101, by: 1)), id: \.self) { h in
                                Text("\(h) ώρες").tag(h as Int?)
                            }
                        }
                        .tint(.agroGreen)
                    }
                    row(label: "Εργασία") {
                        TextField("Π.χ. αλλαγή λαδιών", text: $equipmentNotes)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }

            section("ΧΩΡΑΦΙ") {
                if viewModel.fields.isEmpty {
                    Text("Δεν υπάρχουν αποθηκευμένα χωράφια")
                        .foregroundColor(.secondary)
                        .padding(8)
                } else {
                    Picker("Επιλογή", selection: $selectedField) {
                        Text("—").tag(nil as String?)
                        ForEach(viewModel.fields) { field in
                            Text(field.name).tag(field.name as String?)
                        }
                    }
                    .tint(.agroGreen)
                    .pickerStyle(.menu)
                }
            }

            section("ΥΠΕΝΘΥΜΙΣΗ") {
                Toggle(isOn: $enableReminder) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                        Text("Ενεργοποίηση")
                    }
                }
                .tint(.agroGreen)
                if enableReminder {
                    DatePicker("Ημερομηνία & Ώρα", selection: $reminderDate, in: Date()...)
                        .tint(.agroGreen)
                }
            }

            photoSection
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ΦΩΤΟΓΡΑΦΙΕΣ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        if UIImagePickerController.isSourceTypeAvailable(.camera) {
                            showCamera = true
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                            Text("Φωτογραφία")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.agroGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    Button {
                        showPhotoPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "photo.on.rectangle")
                            Text("Από άλμπουμ")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.agroGreen)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.agroGreen.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }

                if !attachedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(attachedImages.enumerated()), id: \.offset) { index, img in
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                    Button {
                                        attachedImages.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                            .font(.caption)
                                    }
                                    .offset(x: 4, y: -4)
                                }
                            }
                        }
                    }
                }

                if attachedImages.isEmpty {
                    Text("Προσθέστε φωτογραφίες από την κάμερα ή το άλμπουμ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPicker(images: $attachedImages)
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker(image: Binding<UIImage?>(
                get: { nil },
                set: { img in if let i = img { attachedImages.append(i) } }
            ))
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
                    .padding(12)
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func row(label: String, @ViewBuilder content: () -> some View) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.primary)
            Spacer()
            content()
                .frame(width: 100)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func save() async {
        var imageFilenames: [String] = []
        for image in attachedImages {
            if let filename = await ImageManager.shared.saveImage(image) {
                imageFilenames.append(filename)
            }
        }

        let entry = FarmLogEntry(
            type: selectedType,
            notes: notes,
            fieldName: selectedField,
            duration: duration,
            amount: amount,
            amountUnit: selectedType.amountLabel?.contains("(L)") == true ? "L" :
                        selectedType.amountLabel?.contains("(kg)") == true ? "kg" : nil,
            cost: cost,
            reminderDate: enableReminder ? reminderDate : nil,
            imageFilenames: imageFilenames,
            crop: crop.isEmpty ? nil : crop,
            growthStage: growthStage.isEmpty ? nil : growthStage,
            chemicalName: chemicalName.isEmpty ? nil : chemicalName,
            dosage: dosage,
            phiDays: phiDays,
            phiDate: phiDays.flatMap { Calendar.current.date(byAdding: .day, value: $0, to: Date()) },
            yieldAmount: yieldAmount,
            yieldUnit: selectedType == .harvest ? yieldUnit : nil,
            yieldQuality: yieldQuality.isEmpty ? nil : yieldQuality,
            income: selectedType == .finance ? income : nil,
            expenses: selectedType == .finance && expenseAmount.map { $0 > 0 } == true
                ? [ExpenseItem(category: expenseCategory, amount: expenseAmount ?? 0, notes: expenseNotes)] : [],
            equipmentHours: equipmentHours,
            equipmentNotes: equipmentNotes.isEmpty ? nil : equipmentNotes
        )
        onSave(entry)
        HapticManager.success()
        dismiss()
    }
}
