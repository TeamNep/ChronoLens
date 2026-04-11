import PhotosUI
import SwiftUI

struct ExploreView: View {
    @Environment(AppState.self) var appState
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isIdentifying = false
    @State private var identifiedName: String?
    @State private var identifiedSummary: String?
    @State private var errorMessage: String?
    @State private var showChat = false
    @State private var showTravelSettings = false
    @State private var savedToCollection = false
    @State private var showCamera = false
    @State private var locationManager = LocationManager()
    @State private var showLogoutConfirm = false
    @State private var showDuplicateAlert = false
    @State private var duplicateEntry: ParsePlaceEntry?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let imageData = selectedImageData,
                       let uiImage = UIImage(data: imageData) {
                        // Image selected
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        if let name = identifiedName, let summary = identifiedSummary {
                            // Identified
                            VStack(alignment: .leading, spacing: 8) {
                                Text(name)
                                    .font(.title2.bold())
                                Text(summary)
                                    .foregroundStyle(.secondary)

                                if let loc = locationManager.locationName {
                                    Label(loc, systemImage: "location.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                Button {
                                    showChat = true
                                } label: {
                                    Label(
                                        "Learn More",
                                        systemImage: "bubble.left.and.text.bubble.right")
                                }
                                .buttonStyle(.borderedProminent)

                                Button {
                                    saveToCollection()
                                } label: {
                                    Label(
                                        savedToCollection ? "Saved" : "Save",
                                        systemImage: savedToCollection
                                            ? "checkmark.circle.fill" : "square.and.arrow.down"
                                    )
                                }
                                .buttonStyle(.bordered)
                                .disabled(savedToCollection)
                            }

                            Button("Scan Another") {
                                resetState()
                            }
                            .font(.subheadline)
                        } else if isIdentifying {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .controlSize(.large)
                                Text("Identifying landmark...")
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 20)
                        } else {
                            Button {
                                identifyLandmark()
                            } label: {
                                Label(
                                    "Identify This Place", systemImage: "sparkle.magnifyingglass"
                                )
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                    } else {
                        // No image selected
                        VStack(spacing: 20) {
                            Image(systemName: "building.columns")
                                .font(.system(size: 64))
                                .foregroundStyle(.secondary)

                            Text("Discover Historical Places")
                                .font(.title2.bold())

                            Text(
                                "Take or select a photo of a landmark, building, or artwork to learn its history."
                            )
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                            HStack(spacing: 16) {
                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Camera", systemImage: "camera.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)

                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Label("Photos", systemImage: "photo.on.rectangle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                            }
                        }
                        .padding(.top, 60)
                    }

                    if let error = errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
            }
            .navigationTitle("Explore")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button {
                            showTravelSettings = true
                        } label: {
                            Label("Settings", systemImage: "gear")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showLogoutConfirm = true
                        } label: {
                            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if selectedImageData != nil {
                        Button {
                            showCamera = true
                        } label: {
                            Image(systemName: "camera")
                        }
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            Image(systemName: "photo.badge.plus")
                        }
                    }
                }
            }
            .onChange(of: selectedItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        setImage(data)
                    }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { data in
                    setImage(data)
                }
                .ignoresSafeArea()
            }
            .navigationDestination(isPresented: $showChat) {
                if let name = identifiedName,
                   let summary = identifiedSummary,
                   let imageData = selectedImageData {
                    LandmarkChatView(
                        placeName: name,
                        summary: summary,
                        imageData: imageData,
                        latitude: locationManager.latitude,
                        longitude: locationManager.longitude,
                        locationName: locationManager.locationName
                    )
                }
            }
            .sheet(isPresented: $showTravelSettings) {
                TravelModeSettingsView()
            }
            .alert("Log Out", isPresented: $showLogoutConfirm) {
                Button("Log Out", role: .destructive) {
                    appState.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Already in Collection", isPresented: $showDuplicateAlert) {
                Button("Replace") {
                    if let existing = duplicateEntry {
                        replaceDuplicate(existing)
                    }
                }
                Button("Keep Both") {
                    forceAddToCollection()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\"\(identifiedName ?? "This place")\" is already in your collection. Would you like to replace it or keep both?")
            }
            .onAppear {
                locationManager.requestPermission()
            }
        }
    }

    private func setImage(_ data: Data) {
        selectedImageData = data
        identifiedName = nil
        identifiedSummary = nil
        errorMessage = nil
        savedToCollection = false
        locationManager.requestLocation()
    }

    private func identifyLandmark() {
        guard let imageData = selectedImageData else { return }
        isIdentifying = true
        errorMessage = nil

        Task {
            do {
                let result = try await NVIDIAVisionService().identifyLandmark(imageData: imageData)
                identifiedName = result.name
                identifiedSummary = result.summary
            } catch {
                errorMessage = error.localizedDescription
            }
            isIdentifying = false
        }
    }

    private func saveToCollection() {
        guard let name = identifiedName else { return }

        if let existing = appState.collection.first(where: {
            $0.placeName?.lowercased() == name.lowercased()
        }) {
            duplicateEntry = existing
            showDuplicateAlert = true
        } else {
            forceAddToCollection()
        }
    }

    private func forceAddToCollection() {
        guard let imageData = selectedImageData,
              let name = identifiedName,
              let summary = identifiedSummary else { return }
        appState.saveToCollection(
            imageData: imageData,
            placeName: name,
            summary: summary,
            latitude: locationManager.latitude,
            longitude: locationManager.longitude,
            locationName: locationManager.locationName
        )
        savedToCollection = true
    }

    private func replaceDuplicate(_ existing: ParsePlaceEntry) {
        guard let imageData = selectedImageData,
              let name = identifiedName,
              let summary = identifiedSummary else { return }
        appState.replaceInCollection(
            existing: existing,
            imageData: imageData,
            placeName: name,
            summary: summary,
            latitude: locationManager.latitude,
            longitude: locationManager.longitude,
            locationName: locationManager.locationName
        )
        savedToCollection = true
    }

    private func resetState() {
        selectedItem = nil
        selectedImageData = nil
        identifiedName = nil
        identifiedSummary = nil
        errorMessage = nil
        savedToCollection = false
    }
}

// MARK: - Travel Mode Settings

struct TravelModeSettingsView: View {
    @Environment(AppState.self) var appState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            Form {
                Section {
                    Toggle("Travel Mode", isOn: $appState.travelModeEnabled)
                } header: {
                    Text("Daily Reminders")
                } footer: {
                    Text(
                        "When enabled, you'll get a daily reminder to scan and learn about one unique historical place."
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
