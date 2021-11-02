//
//  ColimaSettingsView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI

struct ColimaSettingsView: View {
    var body: some View {
        PageView {
            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)

            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)
            Text("Settings UI!").font(.title)

            ForEach((1...100).reversed(), id: \.self) {
                Text("Settings \($0)").font(.title)
            }
        }
    }
}

struct ColimaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ColimaSettingsView()
    }
}
