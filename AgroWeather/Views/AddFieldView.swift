import SwiftUI
import MapKit

struct AddFieldView: View {
    @Environment(WeatherViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var fieldName = ""
    @State private var searchText = ""
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var position: MapCameraPosition = .automatic
    @State private var searchResults: [MKMapItem] = []
    @State private var showSearchResults = false
    @State private var isDetectingLocation = false
    @State private var locationError = false

    private let defaultCoordinate = CLLocationCoordinate2D(latitude: 38.0, longitude: 23.7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    nameField
                    locationSection
                    mapPreview
                    saveButton
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Νέο Χωράφι")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Ακύρωση") { dismiss() }
                }
            }
        }
        .tint(Color.agroGreen)
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ΟΝΟΜΑ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)

            TextField("π.χ. Κτήμα στις Ελιές", text: $fieldName)
                .font(.body)
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var locationSection: some View {
        VStack(spacing: 10) {
            Text("ΤΟΠΟΘΕΣΙΑ")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                detectCurrentLocation()
            } label: {
                HStack(spacing: 10) {
                    if isDetectingLocation {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.body)
                    }
                    Text("Χρήση τρέχουσας τοποθεσίας")
                        .font(.body.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
                .foregroundColor(.white)
                .padding(14)
                .background(Color.agroGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isDetectingLocation)

            if locationError {
                Text("Δεν ήταν δυνατή η εύρεση της τοποθεσίας σας. Δοκιμάστε αναζήτηση.")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Αναζήτηση τοποθεσίας...", text: $searchText)
                    .font(.subheadline)
                    .autocorrectionDisabled()
                    .onSubmit { searchLocation() }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        showSearchResults = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            if showSearchResults && !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(searchResults, id: \.self) { item in
                        Button {
                            selectResult(item)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name ?? "")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundColor(.primary)
                                    Text(item.placemark.title ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        if item != searchResults.last {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var mapPreview: some View {
        MapReader { reader in
            Map(position: $position) {
                if let coord = selectedCoordinate {
                    Marker(coordinate: coord) {
                        Label("Το χωράφι μου", systemImage: "tree.fill")
                    }
                    .tint(Color.agroGreen)
                }
            }
            .onTapGesture { pos in
                if let coord = reader.convert(pos, from: .local) {
                    selectedCoordinate = coord
                    showSearchResults = false
                }
            }
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(alignment: .bottomTrailing) {
            if let coord = selectedCoordinate {
                Text(String(format: "%.4f, %.4f", coord.latitude, coord.longitude))
                    .font(.caption2)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(8)
            }
        }
    }

    private var saveButton: some View {
        Button {
            saveField()
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Αποθήκευση")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(canSave ? Color.agroGreen : Color.gray.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!canSave)
        .padding(.top, 8)
    }

    private var canSave: Bool {
        !fieldName.trimmingCharacters(in: .whitespaces).isEmpty && selectedCoordinate != nil
    }

    private func detectCurrentLocation() {
        isDetectingLocation = true
        locationError = false
        let loc = CLLocationManager()
        if loc.authorizationStatus == .notDetermined {
            loc.requestWhenInUseAuthorization()
        }
        loc.startUpdatingLocation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let coord = loc.location?.coordinate {
                selectedCoordinate = coord
                position = .camera(MapCamera(centerCoordinate: coord, distance: 5000))
                isDetectingLocation = false
            } else {
                locationError = true
                isDetectingLocation = false
            }
            loc.stopUpdatingLocation()
        }
    }

    private func searchLocation() {
        guard !searchText.isEmpty else { return }
        showSearchResults = true
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = searchText
        req.region = MKCoordinateRegion(
            center: selectedCoordinate ?? defaultCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1)
        )
        Task {
            let res = try? await MKLocalSearch(request: req).start()
            searchResults = res?.mapItems ?? []
        }
    }

    private func selectResult(_ item: MKMapItem) {
        selectedCoordinate = item.placemark.coordinate
        searchText = item.name ?? ""
        showSearchResults = false
        withAnimation {
            position = .camera(MapCamera(centerCoordinate: item.placemark.coordinate, distance: 5000))
        }
    }

    private func saveField() {
        guard let coord = selectedCoordinate else { return }
        let name = fieldName.trimmingCharacters(in: .whitespaces).isEmpty
            ? String(format: "Χωράφι (%.4f, %.4f)", coord.latitude, coord.longitude)
            : fieldName.trimmingCharacters(in: .whitespaces)
        viewModel.addField(name: name, latitude: coord.latitude, longitude: coord.longitude)
        dismiss()
    }
}
