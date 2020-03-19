//
//  AZHeartRateDataSource.swift
//  Infection Alert
//
//  Created by Peter Kuhar on 3/11/20.
//  Copyright © 2020 Peter Kuhar. All rights reserved.
//

import UIKit

 

struct HeartRate:Codable{
    var heartrate:Double
    var timestamp:Date
    var motion:Int?
    var deviceType:String?
    var deviceOS:String?
    
    static func from_sample(_ sample:HKSample) -> HeartRate{
        let sample = sample as! HKQuantitySample
            
        
        let motion = sample.metadata?[HKMetadataKeyHeartRateMotionContext] as? Int
        let device = sample.device?.hardwareVersion
        let os = sample.device?.softwareVersion
        let manufacturer = sample.device?.manufacturer

        var heartrate = HeartRate(heartrate: sample.quantity.doubleValue(for: .init(from: "count/min")), timestamp: sample.startDate, motion: motion, deviceType: device, deviceOS: os)
        return heartrate
    }
}

extension HeartRate{
    var timeOfDay:Double{
        return (self.timestamp.timeIntervalSince1970 - Calendar.current.startOfDay(for:self.timestamp).timeIntervalSince1970)/3600.0
    }
}

import Promises
import HealthKit


class HeartRateDataSource: NSObject {
    override init() {
        
    }
    
    var healthStore = HKHealthStore()
        
    func askPermission() -> Promise<Bool> {
        let allTypes = Set([HKObjectType.quantityType(forIdentifier: .heartRate)!])

       
        
        let promise = Promise<Bool> (on: .main) { fulfill, reject in
         // Called asynchronously on the dispatch queue specified.
         
            self.healthStore.requestAuthorization(toShare: nil, read: allTypes) { (success, error) in
                if let error = error{
                    reject(error)
                    return
                }
                self.isAuthorizationRequested = true

                fulfill(success)
            }
       }
       return promise
    }
    
    var listeners:[([HeartRate])->Promise<Bool>] = []
    
    func data(endDate:Date ) -> Promise<[HeartRate]>{
        
        let promise = Promise<[HeartRate]>(on: .main) { fulfill, reject in
          // Called asynchronously on the dispatch queue specified.
            
            self.askPermission().then { success in
                let predicate = HKQuery.predicateForSamples(withStart: Date(timeIntervalSinceNow: -4*30*24*60*60), end: endDate, options: HKQueryOptions.strictEndDate)

                let q =  HKSampleQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: predicate, limit: 100000, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) in
                    if let error = error{
                        reject(error)
                        return
                    }
                    guard let samples = samples else{
                        reject(NSError())
                        return
                    }
                    self.isAuthorizationRequested = true
                    
                    
                    if samples.count > 0 && !self.isAuthorized{
                        DispatchQueue.main.async {
                            self.isAuthorized = true
                        }
                    }
                    
                    print("got them",samples.count)
                                        
                    
                    let heartrates = samples.map { sample in HeartRate.from_sample(sample)}

                    //DispatchQueue.main.asyncAfter(deadline: DispatchTime.now().advanced(by: .seconds(1))){
                        //for testing only
                        fulfill(heartrates)
                   // }
                    
                }
                self.healthStore.execute(q)
            
            }
        }
        return promise
    }
    
    var isAuthorizationRequested:Bool{
        set{
            if newValue != UserDefaults.standard.bool(forKey: "hk.isAuthorizationRequested"){
                UserDefaults.standard.set(newValue, forKey: "hk.isAuthorizationRequested")
                UserDefaults.standard.synchronize()
                
                self.registerUpdates()
            }
        }
        get{
            return UserDefaults.standard.bool(forKey: "hk.isAuthorizationRequested")
        }
    }
    
    var isAuthorized:Bool{
        set{
            if newValue != UserDefaults.standard.bool(forKey: "hkAuthorized"){
                UserDefaults.standard.set(newValue, forKey: "hkAuthorized")
                UserDefaults.standard.synchronize()
                
                self.registerUpdates()
            }
        }
        get{
            return UserDefaults.standard.bool(forKey: "hkAuthorized")
        }
    }
    
    var isFetching = false
    
    private var fulfillList:[(Bool)->Void] = []
    private var rejectList:[(Error)->Void] = []

    func fetchNewData()->Promise<Bool>{
        print("fetchNewData")
        if isFetching{
            return Promise<Bool>(on: .main) { fulfill, reject in
                self.fulfillList.append(fulfill)
                self.rejectList.append(reject)
            }
        }
        isFetching = true
        
        return self.data(endDate: Date(timeIntervalSinceNow: 0)).then{ heartrates in
            print("got new data")
            self.isFetching = false
            return Promises.all( self.listeners.map{ l in l(heartrates)} ).then{ success -> Bool  in
                print("all done");
                self.fulfillList.forEach{ fulfill in
                    fulfill(true)
                }
                self.fulfillList = []
                return true
            }
        }.catch{ error in
            self.isFetching = false
            self.rejectList.forEach{ reject in
                reject(error)
            }
            self.rejectList = []
            print("error \(error)")
        }
    }
    
    private var updatesRegistered = false
    func registerUpdates(){
        guard self.isAuthorizationRequested else{
            return
        }
        
        guard !self.updatesRegistered else{
            return
        }
        
        self.updatesRegistered = true
        
        let q = HKObserverQuery(sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!, predicate: nil) { (query, completionHandler, error) in
            
            self.fetchNewData().then{ success in
                completionHandler()
            }.catch{ error in
                print("error \(error)")
                completionHandler()
            }
            
        }
        self.healthStore.execute(q)
        self.healthStore.enableBackgroundDelivery(for: HKObjectType.quantityType(forIdentifier: .heartRate)!, frequency: HKUpdateFrequency.hourly) { (success, error) in
            print("delivery enabled \(success)")
        }
    }
}
