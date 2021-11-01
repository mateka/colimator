//
//  ContainersView.swift
//  colimator
//
//  Created by Mateusz Adamczyk on 01/11/2021.
//

import SwiftUI

struct ContainersView: View {
    var body: some View {
        Text("docker ps -A").font(.title)
    }
}

struct ContainersView_Previews: PreviewProvider {
    static var previews: some View {
        ContainersView()
    }
}
