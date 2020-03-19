//
//  ShareView.swift
//  Infection Alert
//
//  Created by Peter K on 3/17/20.
//  Copyright © 2020 Unrelatedlabs. All rights reserved.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    typealias Callback = (_ activityType: UIActivity.ActivityType?, _ completed: Bool, _ returnedItems: [Any]?, _ error: Error?) -> Void
      
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    let excludedActivityTypes: [UIActivity.ActivityType]? = nil
    let callback: Callback? = nil
      
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities)
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }
      
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // nothing to do here
    }
}

struct ShareView: View {
    @State private var showShareSheet = false
    var body: some View {
        VStack{
            Button(action: {
                self.showShareSheet = true
            }){
            VStack{
                Text("To track the spread of the infections through the population, we need anonymized heart rate data from as many people as possible. Please help by sharing the app with your friends.").foregroundColor(Color.black).fixedSize(horizontal: false, vertical: true)
                HStack{
                     Spacer()
                        Text("Share the App")
                        Image(systemName: "envelope")
                    
                }
            }
            }.frame(maxWidth:.infinity).sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: [String("To track the spread of the infections through the population, we need anonymized heart rate data from as many people as possible. Please download this app."), URL(string: "https://bit.ly/infection-alert")])
            }.padding(20).background(Color.white).cornerRadius(8).shadow(radius: 8).padding(10).background(Color.clear).padding(.top,-10)
        }
    }
}

struct ShareView_Previews: PreviewProvider {
    static var previews: some View {
        ShareView()
    }
}
