import SwiftUI

struct TopNavigationView: View {
    let onSettingsTap: () -> Void
    let onInfoTap: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Text("Celestial Tides")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 8)

            Button(action: onInfoTap) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Information")

            Button(action: onSettingsTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.08))
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.96))
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(Color.white.opacity(0.08))
        }
    }
}
