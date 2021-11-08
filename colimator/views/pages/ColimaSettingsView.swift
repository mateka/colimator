//
//  ColimaSettingsView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI


class MountData: ObservableObject, Identifiable, Hashable, Equatable {
    @Published public var path: String
    @Published public var writeable: Bool

    init(path: URL, writeable: Bool) {
        self.path = path.path
        self.writeable = writeable
    }

    static func == (lhs: MountData, rhs: MountData) -> Bool {
        (lhs.path, lhs.writeable) == (rhs.path, rhs.writeable)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        hasher.combine(writeable)
    }
}

struct ColimaMountView: View {
    @ObservedObject var mount: MountData

    var body: some View {
        HStack{
            Text(mount.path)
            Spacer()
            Toggle("", isOn: $mount.writeable)
        }.padding(.horizontal)
    }
}


struct ColimaSettingsView: View {
    @EnvironmentObject var colimaStatusPublisher: ColimaStatusPublisher
//    @State var settings: ColimaStatus = ColimaStatus(
//        updated: Date.now, running: false, runtime: "UNKNOWN",
//        kubernetesEnabled: false
//    )

    @State var cpus: Int = 1 // TODO: Requires only restart
    var cpusBinding: Binding<Double>{
        Binding<Double>(get: {Double(cpus)}, set: {cpus = Int($0)})
    }

    @State var memory: Int = 2 // TODO: Requires only restart
    var memoryBinding: Binding<Double>{
        Binding<Double>(get: {Double(memory)}, set: {memory = Int($0)})
    }

    @State var architecture: Colima.Architecture = Colima.Architecture.aarch64

    @State var mounts: [MountData] = [
        MountData(path: URL(fileURLWithPath: "/tmp/test"), writeable: false),
        MountData(path: URL(fileURLWithPath: "/tmp/test2"), writeable: true),
//        MountData(path: URL(fileURLWithPath: "/tmp/test"), writeable: false),
//        MountData(path: URL(fileURLWithPath: "/tmp/test2"), writeable: true),
//        MountData(path: URL(fileURLWithPath: "/tmp/test"), writeable: false),
//        MountData(path: URL(fileURLWithPath: "/tmp/test2"), writeable: true),
//        MountData(path: URL(fileURLWithPath: "/tmp/test"), writeable: false),
//        MountData(path: URL(fileURLWithPath: "/tmp/test2"), writeable: true),
//        MountData(path: URL(fileURLWithPath: "/tmp/test"), writeable: false),
//        MountData(path: URL(fileURLWithPath: "/tmp/test2"), writeable: true),
//        MountData(path: URL(fileURLWithPath: "/tmp/test"), writeable: false),
//        MountData(path: URL(fileURLWithPath: "/tmp/test2"), writeable: true),
    ]


    var body: some View {
        PageView {
            GroupBox("Resources") {
                HStack {
                    let maxCPUs = ProcessInfo.processInfo.processorCount
                    Slider(value: cpusBinding, in: 1...Double(maxCPUs), step: 1.0) {
                        Text("CPUs: ")
                    }
                    minimumValueLabel: {
                        Text("1")
                    }
                    maximumValueLabel: {
                        Text("\(maxCPUs)")
                    }
                    .padding()

                    Text("\(cpus)CPU").padding()  // TODO: Editable
                }

                HStack {
                    let maxMemory = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
                    Slider(value: memoryBinding, in: 1...maxMemory, step: 1.0) {
                        Text("RAM")
                    }
                    minimumValueLabel: {
                        Text("1GB")
                    }
                    maximumValueLabel: {
                        Text(String(format: "%.2fGB", maxMemory))
                    }
                    .padding()

                    Text("\(memory)GB").padding()  // TODO: Editable
                }

                HStack{
                    Text("Mounts:").font(.title2)
                    Spacer()
                }.padding(.horizontal)
                List {
                    Section(
                        content: {
                            ForEach(mounts, id: \.self) { mount in
                                ColimaMountView(mount: mount)
                            }
                        },
                        header: {
                            HStack {
                                Text("Path")
                                Spacer()
                                Text("Writeable")
                            }.font(.title3).padding()
                        }
                    )
                }.padding(.horizontal).frame(minHeight: 150)

                //let x = NXGetLocalArchInfo().pointee.description

                //Text("\(NXGetLocalArchInfo()?.pointee.description!)")
//
//                print(NXGetLocalArchInfo().pointee.cputype)
//
//                let x =  ProcessInfo.processInfo.
//
                Picker(selection: $architecture, label: Text("Architecture")) {
                    ForEach(Colima.Architecture.allCases as [Colima.Architecture], id: \.rawValue) {
                        Text("\($0.rawValue)").tag($0)
                    }
                }
                .padding()
            }


            // settings (restart => colima stop; colima start;):
            // - disk: int  GiB -> into start; read from lima; requires delete and start (all args...)
            // - runtime containerd (default docker): String (containerd, docker) -> into start; from colima status; requires delete and start (all args...)
            // - with-kubernetes: Bool -> into start; from colima status; requires restart
            // - arch aarch64: String/Enum -> into start; from colima status;  requires delete and start (all args...)
            // - mount [$HOME/projects:w]: [String/Path/URL?] -> into start; .colima/colima.yaml!;requires restart
            // - dns [8.8.8.8]: [String/IP] -> into start; .colima/colima.yaml ?;requires restart
            // port-interface ip   interface to use for forwarded ports (default 127.0.0.1); colima/colima.yaml; into start;requires restart

            // docker/daemon.json <- docker settings

            // TODO: different colima profiles




//            Toggle("Kubernetes", isOn: $settings.kubernetesEnabled)
            HStack {
                Spacer()
                Button(action: {
                    Task {
                        try await Colima().stop()
                        try await Colima().start(
                            cpu: cpus, memory: memory
                        )
                        await colimaStatusPublisher.updateStatus()
                    }
                }) {
                    Text("Save & Restart")
                }
                .buttonStyle(PlainButtonStyle())
                .background(.green)
                Button(action: {
                    cpus = 1
                    memory = 2
                    // TODO: Reset
                }) {
                    Text("Cancel")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
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
        ColimaSettingsView().environmentObject(ColimaStatusPublisher(
            fromStatus: Colima.StatusInfo(
                updated: Date.now, running: true, kubernetesEnabled: false
            )
        ))
    }
}
