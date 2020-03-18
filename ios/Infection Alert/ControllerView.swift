//
//  ControllerView.swift
//  Infection Alert
//
//  Created by Peter K on 3/15/20.
//  Copyright © 2020 Unrelatedlabs. All rights reserved.
//

import SwiftUI

struct ControllerView: View {
    @ObservedObject var onboarding = OnboardingModel()
    
//    private var mainView: some View {
//        if self.onboardingComplete{
//            return ContentHolderView()
//        }else{
//            return OnboardingView()
//        }
//    }
    
    var body: some View {
        VStack{
            if onboarding.complete {
                InfectionTabView()
            }else{
                OnboardingView(onboarding: onboarding)
            }
        }
    }
}

struct ControllerView_Previews: PreviewProvider {
    static var previews: some View {
        ControllerView()
    }
}
