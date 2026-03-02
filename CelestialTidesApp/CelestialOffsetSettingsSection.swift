import SwiftUI

struct CelestialOffsetSettingsSection: View {
    @Binding var offsetHours: Int
    @Binding var offsetMinutes: Int
    @Binding var nextHighTide: Date
    @Binding var showingInfoAlert: Bool
    
    let resolvedTimeZone: TimeZone
    let isInternalUpdate: Bool
    let calculateOffset: () -> Void
    let updateNextHighTideFromOffset: () -> Void
    let normalizeOffsetFieldsIfNeeded: () -> Bool
    
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
                
                DatePicker("", selection: $nextHighTide, displayedComponents: [.hourAndMinute])
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .environment(\.timeZone, resolvedTimeZone)
                    .onChange(of: nextHighTide) { _, _ in
                        if !isInternalUpdate {
                            calculateOffset()
                        }
                    }
            }
            .padding(.vertical, 4)
            
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
        } header: {
            Text("Celestial Offset")
        }
    }
}
