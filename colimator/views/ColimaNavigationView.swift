//
//  NavigationView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI

struct ColimaNavigationView: View {
    var body: some View {
        List {
            Spacer()

            NavigationLink(destination: ContainersView()) {
                Image(systemName: "server.rack").font(.largeTitle)
            }

            NavigationLink(destination: ColimaSettingsView()) {
                Image(systemName: "gearshape").font(.largeTitle)
            }
            .frame(alignment: .bottomLeading)
        }
        .listStyle(.sidebar)
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ColimaNavigationView()
    }
}
