//
//  PageView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI

struct PageView<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack{
                content()
            }
        }
        .frame(minWidth: 500, minHeight: 450)
    }
}

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        PageView() {
            Text("Content").font(.largeTitle)
        }
    }
}
