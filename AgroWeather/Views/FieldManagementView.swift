import SwiftUI

struct FieldManagementView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showAddField = false
    @State private var renameField: Field?
    @State private var showRenameAlert = false
    @State private var newName = ""

    var body: some View {
        List {
            if viewModel.fields.isEmpty {
                emptySection
            } else {
                fieldsSection
            }
            infoSection
        }
        .navigationTitle("Τα Χωράφια Μου")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if viewModel.canAddMoreFields {
                    Button { showAddField = true } label: { Image(systemName: "plus") }
                }
            }
        }
        .sheet(isPresented: $showAddField) { AddFieldView() }
        .alert("Μετονομασία χωραφιού", isPresented: $showRenameAlert) {
            TextField("Νέο όνομα", text: $newName)
            Button("Ακύρωση", role: .cancel) { }
            Button("Αποθήκευση") {
                if let f = renameField, !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                    viewModel.renameField(f, newName: newName.trimmingCharacters(in: .whitespaces))
                }
            }
        } message: { Text("Εισάγετε το νέο όνομα για το χωράφι.") }
    }

    private var emptySection: some View {
        Section {
            VStack(spacing: 16) {
                Spacer().frame(height: 20)
                Image(systemName: "mappin.and.ellipse").font(.system(size: 44)).foregroundColor(.agroGreen.opacity(0.3))
                Text("Δεν έχετε αποθηκευμένα χωράφια").font(.headline).foregroundColor(.secondary)
                Text("Προσθέστε το πρώτο σας χωράφι").font(.subheadline).foregroundColor(.secondary.opacity(0.7))
                Button { showAddField = true } label: {
                    Label("Προσθήκη", systemImage: "plus.circle.fill").font(.headline).foregroundColor(.white)
                        .padding(.horizontal, 24).padding(.vertical, 12).background(Color.agroGreen).clipShape(Capsule())
                }
                Spacer().frame(height: 20)
            }
            .frame(maxWidth: .infinity).listRowBackground(Color.clear)
        }
    }

    private var fieldsSection: some View {
        Section {
            ForEach(viewModel.fields) { field in
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color.agroGreen.opacity(0.1)).frame(width: 44, height: 44)
                        Image(systemName: "tree.fill").font(.title3).foregroundColor(.agroGreen)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(field.name).font(.body.weight(.semibold))
                        Text(String(format: "%.4f°N, %.4f°E", field.latitude, field.longitude)).font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    if field.id == viewModel.selectedField?.id {
                        Image(systemName: "checkmark.circle.fill").font(.title3).foregroundColor(.agroGreen)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture { viewModel.selectField(field); dismiss(); HapticManager.selection() }
                .contextMenu {
                    Button { renameField = field; newName = field.name; showRenameAlert = true } label: { Label("Μετονομασία", systemImage: "pencil") }
                }
            }
            .onDelete { indexSet in indexSet.forEach { viewModel.deleteField(viewModel.fields[$0]) } }
        } header: {
            HStack {
                Text("ΑΠΟΘΗΚΕΥΜΕΝΑ ΧΩΡΑΦΙΑ")
                Spacer()
                Text("\(viewModel.fields.count)/5").font(.caption).foregroundColor(.secondary)
            }
        }
    }

    private var infoSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 6) {
                Label("Δεδομένα από Open-Meteo", systemImage: "cloud.fill").font(.subheadline).foregroundColor(.secondary)
                Text("Δωρεάν αγρομετεωρολογικά δεδομένα χωρίς χρέωση ή API key.").font(.caption).foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.vertical, 4)
        }
    }
}
