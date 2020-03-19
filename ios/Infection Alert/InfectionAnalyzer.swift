//
//  InfectionAnalyzer.swift
//  Infection Alert
//
//  Created by Peter Kuhar on 3/11/20.
//  Copyright © 2020 Peter Kuhar All rights reserved.
//
import SigmaSwiftStatistics

import UIKit
import CoreLocation
import Promises

struct Location:Codable{
    var lat:Double
    var lon:Double
}

struct DayData:Codable,Identifiable{
    var id: String{
        return day
    }
    var day:String
    var timestamp:Date
    var timezone:String
    var location:String
    var heartrates:[HeartRate]
    var baseline:Double?
    var restingHeartRate:Double?
    var dayBaseline:Double?
    var dayHeartRate:Double?
    var sleepBaseline:Double?
    var sleepHeartRate:Double?
    
    var sleepHeartRateElevated:Bool?
    var restingHeartRateElevated:Bool?
    var dayHeartRateElevated:Bool?

    
    static func from_heartrate(_ heartrates:[HeartRate],location:CLLocationCoordinate2D) -> DayData{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var data =  DayData(day: dateFormatter.string(from: heartrates[0].timestamp), timestamp: Calendar.current.startOfDay(for: heartrates[0].timestamp) , timezone: NSTimeZone.system.identifier, location: "POINT(\(location.longitude) \(location.latitude))", heartrates: heartrates, baseline: -1, restingHeartRate: -1,dayBaseline: 0,dayHeartRate: 0,sleepBaseline: 0,sleepHeartRate: 0)
        
        data = analyze_day(data)
        
        return data
    }
    
    static func analyze_day(_ day:DayData) -> DayData{
        //Find if there if we have sleep heart rate
        var day = day
        
    
        
        let sleepTimeCheckRange = 2.0...5.0
        let sleepTimeCalculation = 0.0...8.0

        
        let dayTime = 15.0...20.0
        let dayTimeCalculation = 15.0...20.0

        let sleepData = day.heartrates.filter({hr in sleepTimeCheckRange ~= hr.timeOfDay && hr.motion == 1  })
        let dayData = day.heartrates.filter({hr in dayTime ~= hr.timeOfDay && hr.motion == 1  })

        
        let hasSleepData = sleepData.count > 10
        let hasDayData = dayData.count > 10
        let hasData = day.heartrates.count > 10
        
        day.dayHeartRate =  hasDayData ? Sigma.percentile(day.heartrates.filter({hr in dayTimeCalculation ~= hr.timeOfDay && hr.motion == 1  }).map{ hr in hr.heartrate}, percentile: 0.1)  : nil
        day.sleepHeartRate = hasSleepData ? Sigma.percentile(day.heartrates.filter({hr in sleepTimeCalculation ~= hr.timeOfDay && hr.motion == 1  }).map{ hr in hr.heartrate}, percentile: 0.1) : nil
        day.restingHeartRate = hasData ? Sigma.percentile(day.heartrates.filter({hr in  hr.motion == 1  }).map{ hr in hr.heartrate}, percentile: 0.04) : nil //this should match what apple does


        return day
    }
}

class InfectionAnalyzer: NSObject,ObservableObject {
    
    override init() {
        
    }
    
    @Published var lastData = [DayData]()
    @Published var dataLoaded = false

    var listeners:[([DayData]) -> Promise<Bool>] = []
    
    func addListener(_ listener:@escaping ([DayData])->Promise<Bool>){
        listeners.append(listener)
    }
    
 
    
    func saveSampleData(_ days:[DayData]) {
        let documentDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                    .userDomainMask,
                                                                    true)
        
        
        
        do{
            let data = try JSONEncoder().encode(days)
            try data.write(to: URL(fileURLWithPath: "sample.json", relativeTo: URL(fileURLWithPath:documentDirectory[0])))
        }catch{
            print("error saving \(error)")
        }
        
    }
    
    func updateBaselines(_ days:[DayData]) -> [DayData]{
        let baselineDays = 21.0
        let minBaselineDays = 7
        
        return days.map { day in
            var day = day
            //look back for x days to see what the baseline is
            let interval = DateInterval(start: day.timestamp.addingTimeInterval(-baselineDays*24*3600),end:day.timestamp.advanced(by: -24*3600))
            let pastdays = days.filter{ day in interval.contains(day.timestamp)}
            print(pastdays.count)
            let restingHeartRateValues = pastdays.filter{ $0.restingHeartRate != nil }.map{ $0.restingHeartRate!}
            if restingHeartRateValues.count < minBaselineDays{
                day.baseline = nil
            }else{
                day.baseline = Sigma.average(restingHeartRateValues)
                
                if let variance = Sigma.standardDeviationSample(restingHeartRateValues),let baseline = day.baseline, let heartrate = day.restingHeartRate{
                    day.restingHeartRateElevated = heartrate > baseline + max(6,variance * 2)
                }
            }
            
            let sleepHeartRateValues = pastdays.filter{ $0.sleepHeartRate != nil }.map{ $0.sleepHeartRate! }
            if sleepHeartRateValues.count < minBaselineDays{
                day.sleepBaseline = nil
            }else{
                day.sleepBaseline = Sigma.average(sleepHeartRateValues)
                if let variance = Sigma.standardDeviationSample(sleepHeartRateValues),let baseline = day.sleepBaseline, let heartrate = day.sleepHeartRate{
                    day.sleepHeartRateElevated = heartrate > baseline + max(5,variance * 2)
                }
            }
            
            let dayHeartRateValues = pastdays.filter{ $0.dayHeartRate != nil }.map{ $0.dayHeartRate! }
            if dayHeartRateValues.count < minBaselineDays{
                day.dayBaseline = nil
            }else{
                day.dayBaseline = Sigma.average(dayHeartRateValues)
                if let variance = Sigma.standardDeviationSample(dayHeartRateValues),let baseline = day.dayBaseline, let heartrate = day.dayHeartRate{
                    day.dayHeartRateElevated = heartrate > baseline + max(6,variance * 2)
                }
            }
            
            return day
        }
    }
    
    func update(_ heartrates:[HeartRate]) -> Promise<Bool> {
        
        var days = self.split_to_days(heartrates,location: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        days = updateBaselines(days)
        #if DEBUG
        saveSampleData(days)
        #endif
        self.lastData = days
        self.dataLoaded = true
        
        return Promises.all( self.listeners.map {l in l(days)} ).then{ bools in
            LocationProvider.get().then{ location in
                return self.uploadData(days.map{  day in
                    var day = day
                    day.location = "POINT(\(location.longitude) \(location.latitude))"
                    return day
                })
            }
        }
    }
    
    func uploadData(_ days:[DayData]) -> Promise<Bool>{
        guard days.count >= 2 else {
            return Promise.init(true)
        }
        
        let daysToSave = Array(days[0..<days.count-1].filter{ d in d.day > self.lastUploadedDate })
        
        guard daysToSave.count > 0 else {
            return Promise.init(true)
        }
        
        return Api.post("/api/heartrate", data: daysToSave).then{ resp -> Bool in
            
            self.lastUploadedDate = daysToSave.last!.day
            return true
        }
    }
    
    var lastUploadedDate:String {
        set{
            UserDefaults.standard.set(newValue, forKey: "lastUploadedDate")
            UserDefaults.standard.synchronize()
        }
        get{
            return UserDefaults.standard.string(forKey: "lastUploadedDate") ?? "0"
        }
    }
    

    func split_to_days(_ heartrates:[HeartRate],location:CLLocationCoordinate2D) -> [DayData] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var days:[DayData] = []
        var prevDate = ""
        var aggregated:[HeartRate] = []
        for heartrate in heartrates{
            let date = dateFormatter.string(from: heartrate.timestamp)
            if prevDate != date{
                if aggregated.count > 0 {
                    days.append(DayData.from_heartrate(aggregated,location:location))
                }
                aggregated = []
                prevDate = date
            }
            aggregated.append(heartrate)
        }
         
        if aggregated.count > 0 {
            days.append(DayData.from_heartrate(aggregated,location:location))
        }
        return days
    }
}
