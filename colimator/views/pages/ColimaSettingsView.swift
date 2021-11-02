//
//  ColimaSettingsView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI

struct ColimaSettingsView: View {
    @EnvironmentObject var colimaStatusPublisher: ColimaStatusPublisher
//    @State var settings: ColimaStatus = ColimaStatus(
//        updated: Date.now, running: false, runtime: "UNKNOWN",
//        kubernetesEnabled: false
//    )

    @State var cpus: Int = 1
    var intProxy: Binding<Double>{
        Binding<Double>(get: {
            //returns the cpus as a Double
            return Double(cpus)
        }, set: {
            //rounds the double to an Int
            cpus = Int($0)
        })
    }

    var body: some View {
        PageView {

            HStack {
                Slider(value: intProxy, in: 1...Double(ProcessInfo.processInfo.processorCount), step: 1.0) {
                    Text("CPUS")
                }
                minimumValueLabel: {
                    Text("1")
                } maximumValueLabel: {
                    Text(ProcessInfo.processInfo.processorCount.description)
                }
                Text("CPUS \(cpus)")
            }

            Picker(selection: /*@START_MENU_TOKEN@*/.constant(1)/*@END_MENU_TOKEN@*/, label: Text("Architecture")) {
                Text("ARM").tag(1)
                Text("x64").tag(2)
            }

//            Toggle("Kubernetes", isOn: $settings.kubernetesEnabled)
        }
        .onAppear {
//            if colimaStatusPublisher.status != nil {
//                self.settings = colimaStatusPublisher.status!
//            }
//            else {
//                settings = ColimaStatus(
//                    updated: Date.now, running: false, runtime: "UNKNOWN",
//                    kubernetesEnabled: false
//                )
//            }
        }
    }
}

struct ColimaSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ColimaSettingsView().environmentObject(ColimaStatusPublisher(fromStatus: ColimaStatus(
            updated: Date.now, running: true, runtime: "Some runtime", kubernetesEnabled: false
        )))
    }
}
