//
//  TabView.swift
//  Infection Alert
//
//  Created by Peter K on 3/15/20.
//  Copyright © 2020 Unrelatedlabs. All rights reserved.
//

import SwiftUI

struct InfectionTabView: View {
    @State var selectedTab = 1
    var body: some View {
        TabView(selection:$selectedTab){
           
            WebView(url:"https://unrelatedlabs.github.io/infection-alert/content/info.html")
                .tabItem {
                    Image(systemName: "info")
                    Text("Info")
            }.tag(0)
        
            VStack{
                DashView()
                ShareView()
            }.tabItem {
                Image(systemName: "sun.max")
                Text("Today")
            }.tag(1)
            VStack{
                ContentHolderView()
                ShareView()
            }.tabItem {
                               Image(systemName: "staroflife")
                               Text("Data")
                           }.tag(2)
            
//            Text("Settings")
//                .tabItem {
//                    Image(systemName: "slider.horizontal.3")
//                    Text("Settings")
//                }.tag(3)
        }.font(.headline)
    }
}

struct InfectionTabView_Previews: PreviewProvider {
    static var previews: some View {
        InfectionTabView()
    }
}
