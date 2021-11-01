//
//  ColimaStatusView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 31/10/2021.
//

import SwiftUI

struct ColimaStatusView: View {
    @EnvironmentObject var colimaStatusPublisher: ColimaStatusPublisher

    var body: some View {
        VStack {
            if colimaStatusPublisher.status != nil {
                if colimaStatusPublisher.status!.running {
                    Text("Colima is running")
                    Text("Container runtime: \(colimaStatusPublisher.status!.runtime)")
                    Text("Kubernetes is \(colimaStatusPublisher.status!.kubernetesEnabled ? "" : "not ")enabled")
                    Text("Last checked at \(colimaStatusPublisher.status!.updated.ISO8601Format())").font(.footnote)
                }
                else {
                    Text("Colima is not running").font(.title)
                }
            }
            else {
                Text("Unable to query colima").font(.title)
            }
        }
        .padding()
    }
}

struct ColimaStatusView_Previews: PreviewProvider {
    static var previews: some View {
        ColimaStatusView().environmentObject(
            ColimaStatusPublisher(fromStatus: ColimaStatus(
                updated: Date.now, running: true, runtime: "Some runtime", kubernetesEnabled: false
            )))
    }
}
