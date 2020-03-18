//
//  OnboardingView.swift
//  Infection Alert
//
//  Created by Peter K on 3/15/20.
//  Copyright © 2020 Peter Kuhar. All rights reserved.
//

import Foundation
import SwiftUI
import CoreLocation
import WebKit

struct WebView: UIViewRepresentable {
    var url:String
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
//        webView.scrollView.isScrollEnabled = false
        
        print("url \(url)")

//        if let url = URL(string: url) {
//            let request = URLRequest(url: url)
//            webView.load(request)
//        }
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
}
class OnboardingModel:NSObject,CLLocationManagerDelegate,ObservableObject{
    private let locationManager = CLLocationManager()
    override init() {
        super.init()
        self.locationManager.delegate = self
        updateState()
    }
    
    @Published var heartrateEnabled:Bool = false
    
    func triggerHeartRatePermision() {
        (UIApplication.shared.delegate as! AppDelegate).datasource.askPermission().then{ success in
            self.updateState()
            (UIApplication.shared.delegate as! AppDelegate).datasource.registerUpdates()
            (UIApplication.shared.delegate as! AppDelegate).requestNotifications()
        }
    }
    
    func triggerLocationPermission(){
        locationManager.requestAlwaysAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        updateState()
    }
    
    private func updateState(){
        self.locationEnabled = Set([CLAuthorizationStatus.authorizedAlways,CLAuthorizationStatus.authorizedWhenInUse]).contains( CLLocationManager.authorizationStatus() )
        self.heartrateEnabled = (UIApplication.shared.delegate as! AppDelegate).datasource.isAuthorizationRequested
        print("Update state locationEnabled: \(self.locationEnabled) heartrateEnabled:\(self.heartrateEnabled)")
        self.complete = self.locationEnabled && self.heartrateEnabled
    }
    
    @Published var locationEnabled:Bool = false
    
    @Published var complete:Bool = false{
        willSet{
            print("complete \(newValue)")
            objectWillChange.send()
        }
    }
}

struct OnboardingView:View{
    @ObservedObject var onboarding:OnboardingModel
    var body: some View {
        VStack(alignment: .leading){
            //            ScrollView{
            //                VStack(alignment: .leading){
            //                    Text("Infection Alert").font(.largeTitle).padding(.top,30).padding(.bottom,20)
            //
            //                    Text("Lets write some text, to see what happens if it doesssssssssss")
            //                    Text("Y")
            //                    Text(
            //                        """
            //                        Can I just put all content here
            //                        This is sooo weird
            //                        Ah makes more sense
            //                        """).lineLimit(nil)
            //                }
            //
            //            }
            WebView(url:"https://unrelatedlabs.github.io/infection-alert/content/intro.html")
            Spacer()
            Divider()
            VStack(alignment: .leading){
                Text("Please enable Heart Rate and Location to get started.").padding(.bottom,6)
            HStack{
                Text("Heart Rate")
                Spacer()
                if !onboarding.heartrateEnabled{
                    Button(action:{
                        self.onboarding.triggerHeartRatePermision()
                    }){
                        Text("Enable").padding(6).padding(.leading,10).padding(.trailing,10).background(Color.blue).foregroundColor(Color.white).cornerRadius(7)
                    }
                }else{
                    Text("Enabled").padding(6).padding(.leading,10).padding(.trailing,6)
                }
            }
            HStack{
                Text("Location")
                Spacer()
                if !onboarding.locationEnabled{
                    Button(action:{
                        self.onboarding.triggerLocationPermission()
                    }){
                        Text("Enable").padding(6).padding(.leading,10).padding(.trailing,10).background(Color.blue).foregroundColor(Color.white).cornerRadius(7)
                    }
                }else{
                    Text("Enabled").padding(6).padding(.leading,10).padding(.trailing,6)
                }
            }.padding(.top,15).padding(.bottom,15)
            }.padding(10).background(Color.white)
//            Toggle(isOn: $onboarding.heartrateEnabled) {
//                Text("Enable Heart Rate")
//            }.padding(.vertical,10)
//            Toggle(isOn: $onboarding.locationEnabled) {
//                Text("Enable Location")
//            }.padding(.vertical,10)
            }
        
    }
}


struct OnboardingView_Previews: PreviewProvider {
    
    static var previews: some View {
        OnboardingView(onboarding: OnboardingModel())
    }
}
