import SwiftUI

struct DraggableQueueRow: View {
    let track: Track
    let index: Int
    let isCurrent: Bool
    let onTap: () -> Void
    let onReorder: (Int, Int) -> Void
    @Binding var rowFrames: [CGRect]
    @Binding var draggingIndex: Int?
    @Binding var dragOffset: CGFloat

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            Text("\(index + 1)")
                .font(DS.Typography.captionStrong)
                .foregroundColor(.secondary)
                .frame(width: 24)
            TrackThumbnail(url: track.thumbnailURL, size: 44, cornerRadius: DS.Radius.sm)
            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(DS.Typography.bodyEm)
                    .lineLimit(1)
                Text(track.artist)
                    .font(DS.Typography.caption)
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .offset(y: (draggingIndex == index) ? dragOffset : 0)
        .opacity((draggingIndex == index) ? 0.85 : 1.0)
        .scaleEffect((draggingIndex == index) ? 1.03 : 1.0)
        .shadow(color: .black.opacity((draggingIndex == index) ? 0.2 : 0), radius: 8, y: 4)
        .onTapGesture { onTap() }
        .gesture(
            LongPressGesture(minimumDuration: 0.3)
                .sequenced(before: DragGesture(minimumDistance: 0))
                .onChanged { value in
                    switch value {
                    case .second(true, let drag?):
                        if draggingIndex == nil {
                            Haptics.medium()
                            draggingIndex = index
                        }
                        dragOffset = drag.translation.height
                        if let result = QueueDragEngine.update(
                            currentOrder: rowFrames.indices.map { String($0) },
                            rowFrames: rowFrames,
                            pointerY: rowFrames[index].midY + dragOffset
                        ) {
                            let newIndex = result.newIndex
                            if newIndex != index {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    onReorder(index, newIndex)
                                    draggingIndex = newIndex
                                }
                            }
                        }
                    default:
                        break
                    }
                }
                .onEnded { _ in
                    draggingIndex = nil
                    dragOffset = 0
                }
        )
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear { rowFrames[index] = geo.frame(in: .named("QueueList")) }
                    .onChange(of: geo.frame(in: .named("QueueList"))) { newFrame in
                        rowFrames[index] = newFrame
                    }
            }
        )
    }
}
