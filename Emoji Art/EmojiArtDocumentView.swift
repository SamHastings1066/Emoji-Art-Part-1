//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by CS193p Instructor on 5/8/23.
//  Copyright (c) 2023 Stanford University
//

import SwiftUI

struct EmojiArtDocumentView: View {
    typealias Emoji = EmojiArt.Emoji
    
    @State var selectedEmojiIds = Set<Int>()
    
    @ObservedObject var document: EmojiArtDocument
    
    private let paletteEmojiSize: CGFloat = 40

    var body: some View {
        VStack(spacing: 0) {
            documentBody
            PaletteChooser()
                .font(.system(size: paletteEmojiSize))
                .padding(.horizontal)
                .scrollIndicators(.hidden)
        }
    }
    
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                documentContents(in: geometry)
                    .scaleEffect(zoom * (selectedEmojiIds.isEmpty ? gestureZoom: 1))
                    .offset(pan + gesturePan)
            }
            .gesture(panGesture.simultaneously(with: zoomGesture))
            .dropDestination(for: Sturldata.self) { sturldatas, location in
                return drop(sturldatas, at: location, in: geometry)
            }
        }
    }
    
    @ViewBuilder
    private func documentContents(in geometry: GeometryProxy) -> some View {
        // Adjust this to have more control over the size of the background iamge
        AsyncImage(url: document.background){ image in
            image.image?.resizable()
        }
            .position(Emoji.Position.zero.in(geometry))
            .onTapGesture {
                selectedEmojiIds.removeAll()
            }
        ForEach(document.emojis) { emoji in
            Text(emoji.string)
                .font(emoji.font)
                .border(selectedEmojiIds.contains(emoji.id) ? Color.purple : Color.clear, width: 4 )
                .contextMenu {
                    AnimatedActionButton("Delete", systemImage: "minus.circle", role: .destructive) {
                        //document.removeEmoji(withId: emoji.id)
                        removeEmoji(withId: emoji.id)
                    }
                }
                .position(emoji.position.in(geometry))
                .offset(selectedEmojiIds.contains(emoji.id) ? emojiOffset : .zero)
                .scaleEffect(selectedEmojiIds.contains(emoji.id) ? gestureZoom : 1)
                .gesture(selectedEmojiIds.contains(emoji.id) ? dragEmojiGesture : nil)
                
                .onTapGesture {
                    updateSelectedEmojiIds(with: emoji.id)
                }
        }
    }
    
    private func removeEmoji(withId id: Int) {
        document.removeEmoji(withId: id)
        if let index = selectedEmojiIds.firstIndex(where: {$0 == id}) {
            selectedEmojiIds.remove(at: index)
        }
    }
    
    
    private func includeGesture(for id: Int) -> Bool {
        return selectedEmojiIds.contains(id)
    }
    
    

    
    private func updateSelectedEmojiIds(with id: Int) {
        if selectedEmojiIds.contains(id) {
            selectedEmojiIds.remove(id)
        } else {
            selectedEmojiIds.insert(id)
        }
    }

    @State private var zoom: CGFloat = 1
    @State private var pan: CGOffset = .zero
    //@State private var emojiOffsetDictionary: [Int: CGOffset] = [:]
    
    @GestureState private var gestureZoom: CGFloat = 1
    @GestureState private var gesturePan: CGOffset = .zero
    @GestureState private var emojiOffset: CGOffset = .zero

    
    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
                gestureZoom = inMotionPinchScale
            }
            .onEnded { endingPinchScale in
                if selectedEmojiIds.isEmpty {
                    zoom *= endingPinchScale
                } else {
                    for id in selectedEmojiIds {
                        document.resize(emojiWithId: id, by: endingPinchScale)
                    }
                }
            }
    }
    
    private var panGesture: some Gesture {
        DragGesture()
            .updating($gesturePan) { inMotionDragGestureValue, gesturePan, _ in
                gesturePan = inMotionDragGestureValue.translation
            }
            .onEnded { endingDragGestureValue in
                pan += endingDragGestureValue.translation
            }
    }
    
    
    
    private var dragEmojiGesture: some Gesture {
        DragGesture()
            .updating($emojiOffset){ inMotionEmojiOffsetValue, emojiOffset, _ in
                emojiOffset = inMotionEmojiOffsetValue.translation
            }
            .onEnded { endingDragGestureValue in
                for id in selectedEmojiIds {
//                    if let currentOffset = emojiOffsetDictionary[id] {
//                        emojiOffsetDictionary[id]? += endingDragGestureValue.translation
//                    } else {
//                        emojiOffsetDictionary[id] = endingDragGestureValue.translation
//                    }
                    document.move(emojiWithId: id, by: endingDragGestureValue.translation)
                }
            }
    }
    
    private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
        for sturldata in sturldatas {
            switch sturldata {
            case .url(let url):
                document.setBackground(url)
                return true
            case .string(let emoji):
                document.addEmoji(
                    emoji,
                    at: emojiPosition(at: location, in: geometry),
                    size: paletteEmojiSize / zoom
                )
                return true
            default:
                break
            }
        }
        return false
    }
    
    private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> Emoji.Position {
        let center = geometry.frame(in: .local).center
        return Emoji.Position(
            x: Int((location.x - center.x - pan.width) / zoom),
            y: Int(-(location.y - center.y - pan.height) / zoom)
        )
    }
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
    static var previews: some View {
        EmojiArtDocumentView(document: EmojiArtDocument())
            .environmentObject(PaletteStore(named: "Preview"))
    }
}
