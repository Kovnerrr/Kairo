//
//  JournalPhotoViewer.swift
//  Kairo
//
//  Created by Andrii Kovner on 02.11.26.
//

import SwiftUI
import SwiftData
import UIKit

struct JournalPhotoViewer: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let photos: [JournalPhoto]

    // MARK: - State

    @State private var selectedPhotoID: UUID

    // MARK: - Initialization

    init(
        photos: [JournalPhoto],
        selectedPhotoID: UUID
    ) {
        self.photos = photos
        _selectedPhotoID = State(initialValue: selectedPhotoID)
    }

    // MARK: - Computed Properties

    private var currentPhotoIndex: Int {
        photos.firstIndex {
            $0.id == selectedPhotoID
        } ?? 0
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            TabView(selection: $selectedPhotoID) {
                ForEach(
                    Array(photos.enumerated()),
                    id: \.element.id
                ) { index, photo in
                    ZoomableJournalPhoto(
                        photo: photo,
                        isSelected: photo.id == selectedPhotoID,
                        photoLabel: String(
                            localized: "Photo \(index + 1) of \(photos.count)"
                        ),
                        onDismiss: {
                            guard selectedPhotoID == photo.id else {
                                return
                            }

                            dismiss()
                        }
                    )
                    .tag(photo.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(
                                .black.opacity(0.5),
                                in: Circle()
                            )
                    }
                    .accessibilityLabel("Close photo viewer")
                }

                Spacer()

                Text("\(currentPhotoIndex + 1) / \(photos.count)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        .black.opacity(0.5),
                        in: Capsule()
                    )
            }
            .padding()
        }
        .statusBarHidden()
    }
}

// MARK: - Zoomable Photo

private struct ZoomableJournalPhoto: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    let photo: JournalPhoto
    let isSelected: Bool
    let photoLabel: String
    let onDismiss: () -> Void

    // MARK: - State

    @State private var image: UIImage?
    @State private var loadedPhotoID: UUID?

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    
    @State private var offset: CGSize = .zero
    @GestureState private var dragTranslation: CGSize? = nil
    @GestureState private var isMagnifying = false

    // MARK: - Configuration

    private let minimumScale: CGFloat = 1
    private let maximumScale: CGFloat = 4

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .scaleEffect(scale)
                        .offset(
                            clampedOffset(
                                CGSize(
                                    width: offset.width + (dragTranslation?.width ?? 0),
                                    height: offset.height + (dragTranslation?.height ?? 0)
                                ),
                                imageSize: image.size,
                                viewportSize: geometry.size
                            )
                        )
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .clipped()
                        .contentShape(Rectangle())
                        .highPriorityGesture(
                            panGesture(
                                imageSize: image.size,
                                viewportSize: geometry.size
                            ),
                            isEnabled: scale > minimumScale
                        )
                        .simultaneousGesture(
                            MagnifyGesture()
                                .updating($isMagnifying) { _, state, _ in
                                    state = true
                                }
                                .onChanged { value in
                                    let newScale = lastScale * value.magnification

                                    scale = min(
                                        max(newScale, minimumScale),
                                        maximumScale
                                    )
                                }
                                .onEnded { _ in
                                    lastScale = scale

                                    if dragTranslation == nil {
                                        offset = clampedOffset(
                                            offset,
                                            imageSize: image.size,
                                            viewportSize: geometry.size
                                        )
                                    }
                                }
                        )
                        .onChange(of: dragTranslation == nil) { _, isInactive in
                            if isInactive {
                                offset = clampedOffset(
                                    offset,
                                    imageSize: image.size,
                                    viewportSize: geometry.size
                                )
                            }
                        }
                        .onTapGesture(count: 2) {
                            setScale(
                                scale > minimumScale
                                    ? minimumScale
                                    : 2
                            )
                        }
                        .accessibilityLabel(photoLabel)
                        .accessibilityValue(
                            Text(
                                "Zoom \(Int((scale * 100).rounded())) percent"
                            )
                        )
                        .accessibilityAction(
                            named: Text("Zoom in")
                        ) {
                            setScale(scale * 2)
                        }
                        .accessibilityAction(
                            named: Text("Zoom out")
                        ) {
                            setScale(scale / 2)
                        }
                        .accessibilityAction(
                            named: Text("Reset zoom")
                        ) {
                            setScale(minimumScale)
                        }
                } else if loadedPhotoID == photo.id {
                    ContentUnavailableView(
                        "Photo Unavailable",
                        systemImage: "photo.badge.exclamationmark",
                        description: Text(
                            "This photo could not be displayed."
                        )
                    )
                    .foregroundStyle(.white)
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .contentShape(Rectangle())
            .simultaneousGesture(
                swipeToDismissGesture,
                isEnabled: isSelected &&
                    scale == minimumScale &&
                    !isMagnifying
            )
            .onChange(of: geometry.size) { _, _ in
                setScale(minimumScale, animated: false)
            }
        }
        .task(id: photo.id) {
            guard loadedPhotoID != photo.id else {
                return
            }

            image = UIImage(data: photo.imageData)
            loadedPhotoID = photo.id
        }
        .onChange(of: isSelected) { _, _ in
            setScale(minimumScale, animated: false)
        }
        .onDisappear {
            setScale(minimumScale, animated: false)
        }
    }

    // MARK: - Swipe to Dismiss

    private var swipeToDismissGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard isSelected,
                      scale == minimumScale,
                      !isMagnifying else {
                    return
                }

                let verticalDistance = value.translation.height
                let horizontalDistance = abs(value.translation.width)

                guard verticalDistance > 100,
                      verticalDistance > horizontalDistance * 1.5 else {
                    return
                }

                onDismiss()
            }
    }
    
    // MARK: - Panning

    private func panGesture(
        imageSize: CGSize,
        viewportSize: CGSize
    ) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .updating($dragTranslation) { value, state, _ in
                state = value.translation
            }
            .onEnded { value in
                let proposedOffset = CGSize(
                    width: offset.width + value.translation.width,
                    height: offset.height + value.translation.height
                )

                offset = clampedOffset(
                    proposedOffset,
                    imageSize: imageSize,
                    viewportSize: viewportSize
                )
            }
    }

    private func clampedOffset(
        _ proposedOffset: CGSize,
        imageSize: CGSize,
        viewportSize: CGSize
    ) -> CGSize {
        guard imageSize.width > 0,
              imageSize.height > 0,
              viewportSize.width > 0,
              viewportSize.height > 0 else {
            return .zero
        }

        let fitScale = min(
            viewportSize.width / imageSize.width,
            viewportSize.height / imageSize.height
        )

        let displayedWidth = imageSize.width * fitScale * scale
        let displayedHeight = imageSize.height * fitScale * scale

        let maximumX = max(
            (displayedWidth - viewportSize.width) / 2,
            0
        )

        let maximumY = max(
            (displayedHeight - viewportSize.height) / 2,
            0
        )

        return CGSize(
            width: min(
                max(proposedOffset.width, -maximumX),
                maximumX
            ),
            height: min(
                max(proposedOffset.height, -maximumY),
                maximumY
            )
        )
    }
    
    // MARK: - Zoom

    private func setScale(
        _ newScale: CGFloat,
        animated: Bool = true
    ) {
        let clampedScale = min(
            max(newScale, minimumScale),
            maximumScale
        )

        let animation: Animation? =
            animated && !reduceMotion ? .smooth : nil

        withAnimation(animation) {
            scale = clampedScale
            lastScale = clampedScale
            offset = .zero
        }
    }
}

// MARK: - Previews

#Preview("Photo Viewer · Three Photos") {
    let entry = SampleData.journalEntryWithPhotos

    let container = PreviewContainer.make(
        tasks: [],
        journalEntries: [entry]
    )

    let sortedPhotos = entry.photos.sorted {
        $0.position < $1.position
    }

    if let firstPhoto = sortedPhotos.first {
        JournalPhotoViewer(
            photos: sortedPhotos,
            selectedPhotoID: firstPhoto.id
        )
        .modelContainer(container)
    } else {
        ContentUnavailableView(
            "No Preview Photos",
            systemImage: "photo.on.rectangle.angled",
            description: Text("SampleData contains no journal photos.")
        )
    }
}
