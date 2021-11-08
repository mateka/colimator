//
//  ColimaStatusView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 31/10/2021.
//

import SwiftUI


struct StatusBarElement<Content: View> : View {
    var color: Color = Color.primary
    var background: Color = Color.secondary
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(alignment: .center, spacing: 1) {
            content()
            .padding(.horizontal, 0)
            .padding(.vertical, 2)
        }
        .padding(.horizontal, 5)
        .foregroundColor(color)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 7))
    }
}


struct StatusBadge<Content: View> : View {
    var iconName: String
    var color: Color = Color.primary
    var background: Color = Color.secondary
    @ViewBuilder let content: () -> Content

    var body: some View {
        StatusBarElement(color: self.color, background: self.background) {
            Image(systemName: iconName)
            content()
        }
    }
}


func makeStatus<T: View>(isOk: Bool?, @ViewBuilder content: @escaping () -> T) -> StatusBadge<T> {
    var iconName: String = ""
    var backgroundColor: Color = Color.secondary
    switch isOk {
    case nil:
        iconName = "questionmark.circle"
        backgroundColor = Color.secondary
    case .some(false):
        iconName = "multiply.circle"
        backgroundColor = Color.red
    case .some(true):
        iconName = "hand.thumbsup.circle"
        backgroundColor = Color.green
    }

    return StatusBadge(
        iconName: iconName,
        color: Color.primary,
        background: backgroundColor,
        content: content
    )
}


struct ColimaStatusView: View {
    @EnvironmentObject var colimaStatusPublisher: ColimaStatusPublisher

    var body: some View {
        ZStack {
            HStack {
                StatusBadge(iconName: "multiply.circle", background: Color.red) {
                    Text("Unable to query colima")
                }
                // Tooltip: .help("Test")

                Spacer()
            }
            .opacity(colimaStatusPublisher.status != nil ? 0 : 1)

            HStack {
                makeStatus(isOk: colimaStatusPublisher.status?.running ?? false) {
                    Text("colima")
                }

                makeStatus(isOk: colimaStatusPublisher.status?.kubernetesEnabled ?? false) {
                    Image(systemName: "helm")  // k8s icon
                }

//                StatusBarElement(color: .primary, background: .gray) {
//                    Text("runtime:")
//                    Image(systemName: "questionmark.circle")
//                }

                Spacer()
            }
            .opacity(colimaStatusPublisher.status != nil ? 1 : 0)
        }
        .padding(5)
        .background(Color.gray)
        .border(Color.gray, width: 0)
    }
}

struct ColimaStatusView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StatusBadge(iconName: "questionmark.circle.fill", color: Color.red, background: Color.yellow) {
                Text("Sample content")
            }
            .font(.largeTitle)

            ColimaStatusView().environmentObject(
                ColimaStatusPublisher(fromStatus: Colima.StatusInfo(
                    updated: Date.now, running: false, kubernetesEnabled: false
                )))
        }
    }
}
