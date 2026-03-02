import SwiftUI

struct CelestialOffsetSettingsSection: View {
    @Binding var offsetHours: Int
    @Binding var offsetMinutes: Int
    @Binding var nextHighTide: Date?
    @Binding var showingInfoAlert: Bool
    @Binding var isTideCalibrated: Bool
    
    let resolvedTimeZone: TimeZone
    let isInternalUpdate: Bool
    let calculateOffset: () -> Void
    let updateNextHighTideFromOffset: () -> Void
    let normalizeOffsetFieldsIfNeeded: () -> Bool
    let isInternalUpdateAction: () -> Void
    let isInternalUpdateFinishedAction: () -> Void
    
    @State private var showingDatePicker = false
    @State private var tempSelectedDate: Date = Date()
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Next High Tide")
                    Spacer()
                    Button(action: { showingInfoAlert = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                if !isTideCalibrated || nextHighTide == nil {
                    Button(action: {
                        tempSelectedDate = Date()
                        showingDatePicker = true
                    }) {
                        Text("Select Next High Tide")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.vertical, 8)
                } else {
                    DatePicker("", selection: Binding(
                        get: { nextHighTide ?? Date() },
                        set: { nextHighTide = $0 }
                    ), displayedComponents: [.hourAndMinute])
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .environment(\.timeZone, resolvedTimeZone)
                        .onChange(of: nextHighTide) { _, _ in
                            if !isInternalUpdate {
                                calculateOffset()
                            }
                        }
                }
            }
            .padding(.vertical, 4)
            .sheet(isPresented: $showingDatePicker) {
                NavigationStack {
                    DatePicker(
                        "",
                        selection: $tempSelectedDate,
                        displayedComponents: [.hourAndMinute]
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .environment(\.timeZone, resolvedTimeZone)
                    .navigationTitle("Next High Tide")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                showingDatePicker = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                isInternalUpdateAction()
                                nextHighTide = tempSelectedDate
                                isTideCalibrated = true
                                Task { @MainActor in
                                    isInternalUpdateFinishedAction()
                                }
                                showingDatePicker = false
                            }
                        }
                    }
                }
                .presentationDetents([.height(350), .medium])
                .preferredColorScheme(.dark)
            }
            
            if isTideCalibrated {
                HStack {
                    Text("Offset Hours")
                    Spacer()
                    TextField("Hrs", value: $offsetHours, format: .number)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .onChange(of: offsetHours) { _, _ in
                            if normalizeOffsetFieldsIfNeeded() { return }
                            if !isInternalUpdate {
                                updateNextHighTideFromOffset()
                            }
                        }
                }
                HStack {
                    Text("Offset Minutes")
                    Spacer()
                    TextField("Min", value: $offsetMinutes, format: .number)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .onChange(of: offsetMinutes) { _, _ in
                            if normalizeOffsetFieldsIfNeeded() { return }
                            if !isInternalUpdate {
                                updateNextHighTideFromOffset()
                            }
                        }
                }
            }
        } header: {
            Text("Celestial Offset")
        }
    }
}
