//
//  ContentView.swift
//  Infection Alert
//
//  Created by Peter Kuhar on 3/11/20.
//  Copyright © 2020 Peter Kuhar. All rights reserved.
//

import SwiftUI
import Promises

public class PreviewHeartRateDataObserver: ObservableObject {
    @Published var data = [DayData]()
    
    init(){
        loadPreview()
    }
    
    func loadPreview() {
        do{
            let decoder = JSONDecoder()
            let url = Bundle.main.url(forResource: "sample.json", withExtension: nil)!
            let data = try decoder.decode([DayData].self, from: Data(contentsOf: url))
            self.data = data
        }catch{
            self.data = [DayData(day: "Error \(error)", timestamp: Date.init(timeIntervalSinceNow: 0), timezone: "PST", location: "", heartrates: [], baseline: 0, restingHeartRate: 0,dayBaseline: 0,dayHeartRate: 0,sleepBaseline: 0,sleepHeartRate: 0)]
        }
    }
}


import SigmaSwiftStatistics


 
import CareKit

 

struct ScatterView: View{
    var heartrates:[(Double,Double,Int)]
    var colors = [Color.red,Color.red,Color.red,Color.red]// [Color.blue,Color.green, Color.red,Color.black]
    var body: some View{
        VStack{
            GeometryReader { geometry in
    //            let w = geometry.size.width
    //            let h = geometry.size.height
    //
                //Text("Hello")
    //            Circle()
    //            .fill(Color.blue)
    //                .frame(width: 3, height: 3, alignment: .topLeading).offset(x: 0, y: 0)
                ZStack{
                    ForEach(0..<self.colors.count){ color in
                        Path{ path in
                           guard self.heartrates.count > 0 else{
                               return
                           }
                           
                           let miny = Sigma.min(self.heartrates.map{v in v.1})!
                           let maxy = Sigma.max(self.heartrates.map{v in v.1})!
                           
                           var minRange = 60
                           var range = max(1,maxy-miny)
                           
                            for (x,y,c) in self.heartrates.filter({v in v.2 == color}) {
                               path.addEllipse(in: CGRect(x: Double(geometry.size.width) * x / 24.0 , y: Double(geometry.size.height) - (y-miny)/range * Double(geometry.size.height), width: 4.0, height: 4.0))
                           }
                           //return path
                        }.fill(self.colors[color % self.colors.count])
                    }
                }
            }.frame(height:100)
            HStack{
                Text("12am").font(.system(.subheadline))
                Spacer()
                Text("12pm").font(.system(.subheadline))
                Spacer()
                Text("12am").font(.system(.subheadline))
            }.foregroundColor(Color.gray)
        }
    }
    
}

struct ChartView: UIViewRepresentable {
    var data:[OCKDataSeries] = []
    var labels:[String] = []
    func makeUIView(context: Context) -> OCKCartesianChartView {
        let chartView = OCKCartesianChartView(type: .scatter)

       // chartView.headerView.titleLabel.text = "Doxylamine"
        
        chartView.graphView.dataSeries = data
//        chartView.graphView.xMinimum = 0
//        chartView.graphView.xMaximum = 24
        chartView.graphView.horizontalAxisMarkers = labels
        chartView.translatesAutoresizingMaskIntoConstraints = true
        chartView.headerView.detailLabel.text = "Heart Rate Trends"
        return chartView
    }

    func updateUIView(_ uiView: OCKCartesianChartView, context: Context) {
        uiView.graphView.dataSeries = data
        uiView.graphView.horizontalAxisMarkers = labels
    }
}

let noDataMessage = """
You either have no heart rate data from the Apple Watch, or you did not give Infection Alert permission to access it.

Please open your Apple Healt app and give Infection Alert permission to access your heart rate.
"""

struct NoDataView: View{
    var body: some View {
        VStack{
            Spacer()
            Text("No data available").font(.title)
            Text(noDataMessage)
            Spacer()
        }.padding(20)
    }
}

struct LoadingView: View{
    var body: some View {
        VStack{
            Spacer()
            Text("Loading...")
            Spacer()
        }
    }
}

struct ValueStackView: View {
    var top:Double?
    var bottom:Double?
    var title = "Sleep"
    var elevated:Bool?
    
    private var color:Color{
        switch elevated {
        case nil:
            return Color.gray
        case true:
            return Color.red
        case false:
            return Color.green
        case .some(_):
            return Color.primary
        }
    }
    var body: some View {
        HStack{
            Text(title)
            VStack{
                Text( top != nil ? "\(Int(top ?? 0))" : "~" ).foregroundColor(color)
                Text( bottom != nil ? "\(Int(bottom ?? 0))" : "~").foregroundColor(color)
            }
        }
    }
    
}


struct ContentView: View {

    
    @State private var showingAlert = false
    @State private var alertText = ""
    
    var data:[DayData]
    var dataLoaded:Bool = false
    var displayDays = 15
    var dateFormater:DateFormatter{
        let df = DateFormatter()
        df.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMMMd", options: 0, locale: Locale.current)!
        return df
    }
    
    
    var body: some View {
        VStack{
            List{
                ChartView(data:[
                                OCKDataSeries(dataPoints: self.data.filter{$0.restingHeartRate != nil}.map{ d in CGPoint(x:CGFloat(d.timestamp.timeIntervalSinceNow),y:CGFloat(d.restingHeartRate!))}.suffix(displayDays) , title: "Resting",size: 3,color: UIColor(red: 255/255.0, green: 95/255.0, blue: 95/255.0, alpha: 1)),
                                OCKDataSeries(dataPoints: self.data.filter{$0.dayHeartRate != nil}.map{ d in CGPoint(x:CGFloat(d.timestamp.timeIntervalSinceNow),y:CGFloat(d.dayHeartRate!))}.suffix(displayDays) , title: "Day",size: 3,color: UIColor(red: 255/255.0, green: 183/255.0, blue: 73/255.0, alpha: 1)),
                                OCKDataSeries(dataPoints: self.data.filter{$0.sleepHeartRate != nil}.map{ d in CGPoint(x:CGFloat(d.timestamp.timeIntervalSinceNow),y:CGFloat(d.sleepHeartRate!))}.suffix(displayDays) , title: "Sleep",size: 3,color: UIColor(red: 180/255.0, green: 212/255.0, blue: 230/255.0, alpha:1))
                            ],labels: self.data.map{ d in String(d.day.suffix(2))}.suffix(displayDays)).frame(height:200)
                ForEach(data.reversed()){item in
                    VStack{
                        HStack{
                            Text("\( self.dateFormater.string(from:  item.timestamp))").font(.system(Font.TextStyle.headline))
                            Spacer()
                        
                        }.padding(.top,6).padding(.bottom,5)
                         
                        HStack{
                            Spacer()
                            ValueStackView(top: item.sleepHeartRate, bottom: item.sleepBaseline, title: "Sleep",elevated: item.sleepHeartRateElevated)
                            Spacer()

                            ValueStackView(top: item.dayHeartRate, bottom: item.dayBaseline, title: "Day ",elevated: item.dayHeartRateElevated)
                            Spacer()

                            ValueStackView(top: item.restingHeartRate, bottom: item.baseline, title: "Resting",elevated: item.restingHeartRateElevated)
                            Spacer()

                        }
                        ScatterView(heartrates: item.heartrates.map{hr in (hr.timeOfDay,hr.heartrate,hr.motion ?? 0)})
                    }
                }
            }
            
        }
    }
}




struct ContentHolderView:View{
    @ObservedObject var analyzer = (UIApplication.shared.delegate as! AppDelegate).analyzer
    var body: some View {
        ZStack{
            if analyzer.dataLoaded && analyzer.lastData.count > 0{
                ContentView(data:analyzer.lastData,dataLoaded:analyzer.dataLoaded)
            }else if analyzer.dataLoaded{
                NoDataView()
            }else{
                LoadingView()
            }
        }
    }
}

#if DEBUG
struct PreviewHolder:View{
    @ObservedObject var data = PreviewHeartRateDataObserver()
    var body: some View {
        ContentView(data:data.data,dataLoaded: true)
    }
}


struct ContentView_Previews: PreviewProvider {
   
    static var previews: some View {
        PreviewHolder()
    }
}

//struct ChartView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChartView()
//    }
//}
#endif
