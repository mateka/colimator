//
//  NavigationView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI


enum Pages {
    case Home
    case Containers
    case Settings
}


struct ColimaNavigationView: View {
    @State var selection: Pages? = .Home

    var body: some View {
        List {
            Spacer()

            NavigationLink(
                destination: Text("Home Page?").font(.largeTitle),
                tag: Pages.Home, selection: $selection
            ) {
                Image(systemName: "info.circle").font(.largeTitle)
            }

            NavigationLink(
                destination: ContainersView(),
                tag: Pages.Containers, selection: $selection
            ) {
                Image(systemName: "server.rack").font(.largeTitle)
            }

            NavigationLink(
                destination: ColimaSettingsView(),
                tag: Pages.Settings, selection: $selection
            ) {
                Image(systemName: "gearshape").font(.largeTitle)
            }
            .frame(alignment: .bottomLeading)
        }
        .frame(width: 200)
        .frame(minWidth: 200)
        .listStyle(.sidebar)
    }
}

struct NavigationView_Previews: PreviewProvider {
    static var previews: some View {
        ColimaNavigationView()
    }
}
