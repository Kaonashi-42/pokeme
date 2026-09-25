import PokeMeCore
import SwiftUI

/// The full-screen "you have a meeting" card.
struct OverlayView: View {
    let meeting: Meeting
    let color: Color
    let onJoin: (URL) -> Void
    let onSnooze: () -> Void
    let onDismiss: () -> Void

    /// Buttons and shortcuts stay inactive for a moment after the overlay appears, so a Return or click meant for the
    /// app the user was typing in doesn't join a call by accident.
    private static let armingDelay: Duration = .milliseconds(800)
    @State private var isArmed = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.9)
            RadialGradient(colors: [color.opacity(0.6), .clear], center: .top, startRadius: 0, endRadius: 1_000)
            VStack(spacing: 26) {
                if let calendarTitle = meeting.calendarTitle {
                    calendarChip(calendarTitle)
                }
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(Format.countdown(to: meeting.start, now: context.date).uppercased())
                        .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                        .tracking(4)
                        .foregroundStyle(color)
                }
                Text(meeting.title)
                    .font(.system(size: 80, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.4)
                Text(Format.timeRange(meeting.start, meeting.end))
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                details
                actions
                    .padding(.top, 20)
                    .allowsHitTesting(isArmed)
                Text(meeting.joinURL == nil ? "esc to dismiss" : "return to join  ·  esc to dismiss")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
            .padding(80)
            .frame(maxWidth: 1_200)
        }
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
        .ignoresSafeArea()
        .task {
            try? await Task.sleep(for: Self.armingDelay)
            isArmed = true
        }
    }

    private func calendarChip(_ title: String) -> some View {
        Label {
            Text(title)
        } icon: {
            Circle().fill(color).frame(width: 10, height: 10)
        }
        .font(.system(size: 16, weight: .medium))
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08), in: Capsule())
    }

    private var details: some View {
        HStack(spacing: 28) {
            if let location = meeting.displayLocation {
                Label(location, systemImage: "mappin.and.ellipse")
            }
            if meeting.attendeeCount > 0 {
                Label("\(meeting.attendeeCount) people", systemImage: "person.2.fill")
            }
        }
        .font(.system(size: 20))
        .foregroundStyle(.secondary)
    }

    private var actions: some View {
        HStack(spacing: 14) {
            if let url = meeting.joinURL {
                Button {
                    onJoin(url)
                } label: {
                    Label("Join \(MeetingLink.serviceName(for: url) ?? "call")", systemImage: "video.fill")
                }
                .buttonStyle(PillButtonStyle(isPrimary: true))
                .keyboardShortcut(isArmed ? .defaultAction : nil)
            }
            Button("Snooze 1 min", action: onSnooze)
                .buttonStyle(PillButtonStyle())
            Button("Dismiss", action: onDismiss)
                .buttonStyle(PillButtonStyle())
                .keyboardShortcut(isArmed ? .cancelAction : nil)
        }
    }
}

private struct PillButtonStyle: ButtonStyle {
    var isPrimary = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .semibold, design: .rounded))
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
            .background(isPrimary ? Color.white : Color.white.opacity(0.12), in: Capsule())
            .foregroundStyle(isPrimary ? Color.black : Color.white)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
    }
}
