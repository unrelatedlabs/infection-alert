//
//  DashView.swift
//  Infection Alert
//
//  Created by Peter K on 3/17/20.
//  Copyright © 2020 Unrelatedlabs. All rights reserved.
//

import SwiftUI

struct DashCardView: View {
    var title = "Sleep Resting Heart Rate"
    var heartRate:Double? = 57.0
    var baseline:Double? = 55.0
    var elevated:Bool? = false
    
    var elevatedText:String{
        guard let elevated = elevated else{
            return "No enough data"
        }
        if elevated{
            return "ELEVATED"
        }else{
            return "NORMAL"
        }
    }
    
    var elevatedColor:Color{
        guard let elevated = elevated else{
            return Color.gray
        }
        if elevated{
            return Color.red
        }else{
            return Color.green
        }
    }
    
    var body: some View {
        VStack{
            VStack{
                HStack(alignment:.firstTextBaseline){
                    //                    Spacer()
                    Text( heartRate != nil ? "\(Int(heartRate!))" : "~"  ).font(.system(size: 50)).alignmentGuide(HorizontalAlignment.center) { (d) -> CGFloat in
                        6
                    }
                    Text("bpm")
                    //                    Spacer()
                }
                Text( elevatedText).padding(5).font(.system(size: 20)).foregroundColor(elevatedColor)
                
                HStack(alignment:.firstTextBaseline){
                    Text("Baseline").font(.system(size: 14))
                    Text(baseline != nil ? "\(Int(baseline!))" : "~" ).font(.system(.headline))
                    Text("bpm").font(.system(size: 14))
                }
            }.padding()
            Text(title).frame(maxWidth:.infinity).padding(4).font(.system(size: 16, weight: .bold, design: .default)).background(Color.gray.opacity(0.2))
        }
        .background(Color.white)
        .cornerRadius(7)
        .shadow(radius: 8)
        .padding(10)
    }
}
struct DashView: View {
    @ObservedObject var analyzer = (UIApplication.shared.delegate as! AppDelegate).analyzer
    var data:DayData?{
        return analyzer.lastData.last
    }
    var dataLoaded:Bool{
        return analyzer.dataLoaded
    }
    
    var body: some View {
        
        VStack(alignment: .center){
            if dataLoaded && analyzer.lastData.count > 0{
                Text("YOUR HEART RATE\nTODAY").font(.title).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true).padding(.leading,10).padding(.top,10).padding(.bottom,10)
                DashCardView(title: "Sleep Heart Rate", heartRate: data?.sleepHeartRate, baseline: data?.sleepBaseline, elevated: data?.sleepHeartRateElevated)
                DashCardView(title: "Day Heart Rate", heartRate: data?.dayHeartRate, baseline: data?.dayBaseline, elevated: data?.dayHeartRateElevated)
//                DashCardView(title: "Resting Heart Rate", heartRate: data?.restingHeartRate, baseline: data?.baseline, elevated: data?.restingHeartRateElevated)
                Spacer()
            }else if dataLoaded{
                NoDataView()
            }else{
                LoadingView()
            }
            
        }.frame(maxWidth:.infinity)
    }
}

struct DashView_Previews: PreviewProvider {
    static var previews: some View {
        DashView()
    }
}
