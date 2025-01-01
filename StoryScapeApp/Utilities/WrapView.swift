//
//  WrapView.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import SwiftUI

/// A custom layout that wraps items (e.g. chips).
/// Typically used to display selected genres or tags.
struct WrapView<Data: RandomAccessCollection, Content: View, ID: Hashable>: View where Data.Element: Hashable {
    let data: Data
    let id: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content

    @State private var totalHeight = CGFloat.zero

    var body: some View {
        VStack {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(data, id: id) { item in
                content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == data.last! {
                            width = 0
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { _ in
                        let result = height
                        if item == data.last! {
                            height = 0
                        }
                        return result
                    })
            }
        }
        .background(heightReader($totalHeight))
    }

    private func heightReader(_ binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
        }
        .onPreferenceChange(HeightPreferenceKey.self) { value in
            binding.wrappedValue = value
        }
    }
}

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
