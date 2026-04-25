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
                    // Badge & streak card
                    if let badge = appState.userBadge {
                        HStack(spacing: 14) {
                            Text(AppState.badgeEmoji(for: badge.badgeLevel ?? "beginner"))
                                .font(.system(size: 32))
                                .frame(width: 48, height: 48)
                                .background(
                                    Circle()
                                        .fill(Color(.systemGray6))
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(AppState.badgeTitle(for: badge.badgeLevel ?? "beginner"))
                                    .font(.subheadline.bold())

                                HStack(spacing: 12) {
                                    Label("\(badge.currentStreak ?? 0) day streak", systemImage: "flame.fill")
                                        .foregroundStyle(.orange)
                                    Label("\(badge.totalScans ?? 0) scans", systemImage: "binoculars")
                                        .foregroundStyle(.secondary)
                                }
                                .font(.caption)
                            }

                            Spacer()

                            if let next = AppState.nextBadgeInfo(currentScans: badge.totalScans ?? 0) {
                                VStack(spacing: 2) {
                                    Text("\(next.scansNeeded)")
                                        .font(.title3.bold())
                                        .foregroundStyle(.blue)
                                    Text("to next")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                        .padding(14)
                        .background(Color(.systemGray6).opacity(0.7))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    if let imageData = selectedImageData,
                       let uiImage = UIImage(data: imageData) {
                        // Image selected
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

                        if let name = identifiedName, let summary = identifiedSummary {
                            // Identified result card
                            VStack(alignment: .leading, spacing: 10) {
                                Text(name)
                                    .font(.title2.bold())
                                Text(summary)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .lineSpacing(2)

                                if let loc = locationManager.locationName {
                                    Label(loc, systemImage: "location.fill")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .padding(.top, 2)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 14))

                            HStack(spacing: 12) {
                                Button {
                                    showChat = true
                                } label: {
                                    Label(
                                        "Learn More",
                                        systemImage: "bubble.left.and.text.bubble.right")
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                Button {
                                    saveToCollection()
                                } label: {
                                    Label(
                                        savedToCollection ? "Saved" : "Save",
                                        systemImage: savedToCollection
                                            ? "checkmark.circle.fill" : "square.and.arrow.down"
                                    )
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .disabled(savedToCollection)
                            }

                            Button {
                                resetState()
                            } label: {
                                Text("Scan Another")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.top, 4)
                        } else if isIdentifying {
                            VStack(spacing: 14) {
                                ProgressView()
                                    .controlSize(.large)
                                Text("Identifying landmark...")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
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
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .blue.opacity(0.2), radius: 6, y: 3)
                        }
                    } else {
                        // No image selected — empty state
                        VStack(spacing: 24) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue.opacity(0.12), .indigo.opacity(0.08)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 120, height: 120)

                                Image(systemName: "building.columns")
                                    .font(.system(size: 48))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .indigo],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }

                            VStack(spacing: 8) {
                                Text("Discover Historical Places")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))

                                Text(
                                    "Take or select a photo of a landmark, building, or artwork to learn its history."
                                )
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                            }

                            HStack(spacing: 14) {
                                Button {
                                    showCamera = true
                                } label: {
                                    Label("Camera", systemImage: "camera.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .blue.opacity(0.2), radius: 6, y: 3)

                                PhotosPicker(selection: $selectedItem, matching: .images) {
                                    Label("Photos", systemImage: "photo.on.rectangle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.top, 60)
                    }

                    if let error = errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.callout)
                            Text(error)
                                .font(.callout)
                        }
                        .foregroundStyle(.red)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
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
                appState.recordDiscovery()
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
    @State private var reminderTime = Date()

    private func timeFromComponents() -> Date {
        var components = DateComponents()
        components.hour = appState.reminderHour
        components.minute = appState.reminderMinute
        return Calendar.current.date(from: components) ?? Date()
    }

    var body: some View {
        @Bindable var appState = appState

        NavigationStack {
            Form {
                Section {
                    Toggle("Travel Mode", isOn: $appState.travelModeEnabled)
                } header: {
                    Text("Travel Mode")
                } footer: {
                    Text(
                        "When enabled, you'll get one notification per day to scan and learn about a unique historical place."
                    )
                }

                if appState.travelModeEnabled {
                    Section {
                        DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, newValue in
                                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                                appState.reminderHour = components.hour ?? 9
                                appState.reminderMinute = components.minute ?? 0
                            }
                    } header: {
                        Text("Preferred Time")
                    } footer: {
                        Text("Choose when you'd like to receive your daily discovery reminder.")
                    }
                }

                if let badge = appState.userBadge {
                    Section {
                        HStack {
                            Text("Current Badge")
                            Spacer()
                            Text("\(AppState.badgeEmoji(for: badge.badgeLevel ?? "beginner")) \(AppState.badgeTitle(for: badge.badgeLevel ?? "beginner"))")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Total Discoveries")
                            Spacer()
                            Text("\(badge.totalScans ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Current Streak")
                            Spacer()
                            Text("\(badge.currentStreak ?? 0) day\(badge.currentStreak == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Text("Longest Streak")
                            Spacer()
                            Text("\(badge.longestStreak ?? 0) day\(badge.longestStreak == 1 ? "" : "s")")
                                .foregroundStyle(.secondary)
                        }
                        if let next = AppState.nextBadgeInfo(currentScans: badge.totalScans ?? 0) {
                            HStack {
                                Text("Next Badge")
                                Spacer()
                                Text("\(next.nextLevel) (\(next.scansNeeded) more)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } header: {
                        Text("Your Progress")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                reminderTime = timeFromComponents()
                if appState.travelModeEnabled {
                    appState.requestNotificationPermission()
                }
            }
            .onChange(of: appState.travelModeEnabled) { _, enabled in
                if enabled {
                    appState.requestNotificationPermission()
                }
            }
        }
    }
}
