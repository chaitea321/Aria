import SwiftUI

struct AddToQueueModifier: ViewModifier {
    @ObservedObject var playerManager: PlayerManager
    let track: Track

    @State private var showConfirmation = false

    func body(content: Content) -> some View {
        content
            .contextMenu {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    playerManager.addToQueue(track)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        showConfirmation = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            showConfirmation = false
                        }
                    }
                } label: {
                    Label("Add to Queue", systemImage: "text.badge.plus")
                }
            }
            .overlay {
                if showConfirmation {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("Added to Queue")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .transition(.scale.combined(with: .opacity))
                }
            }
    }
}

extension View {
    func addToQueueGesture(playerManager: PlayerManager, track: Track) -> some View {
        modifier(AddToQueueModifier(playerManager: playerManager, track: track))
    }
}
