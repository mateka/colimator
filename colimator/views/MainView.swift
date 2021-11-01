//
//  MainView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 31/10/2021.
//

import SwiftUI

struct MainView: View {
    @EnvironmentObject var colimaStatusPublisher: ColimaStatusPublisher

    var body: some View {
        VStack{
            NavigationView {
                ColimaNavigationView()
            }
            .frame(minWidth: 300)

            ColimaStatusView().frame(alignment: .bottom)
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(ColimaStatusPublisher(fromStatus: ColimaStatus(
            updated: Date.now, running: true, runtime: "Some runtime", kubernetesEnabled: false
        )))
    }
}
