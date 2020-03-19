//
//  LocationProvider.swift
//  Infection Alert
//
//  Created by Peter K on 3/13/20.
//  Copyright © 2020 Peter Kuhar. All rights reserved.
//

import UIKit
import CoreLocation
import Promises

enum LocationError:Error{
    case notAuthorized
    case denied
    case timeout
}

class LocationProvider:NSObject,CLLocationManagerDelegate {
    init(_ fullfill:@escaping (_ location:CLLocationCoordinate2D)->Void,_ reject:@escaping (_ error:Error)->Void) {
        self.fullfill = fullfill
        self.reject = reject
        
    
        
    }
    
    var timeout:TimeInterval = 5
    
    static func randomLocationOffset() -> CLLocationCoordinate2D{
        if let offset = UserDefaults.standard.array(forKey: "location_offset") as? [Double]{
            return CLLocationCoordinate2D(latitude: offset[0], longitude: offset[1])
        }
        let d = 0.0015 //about two blocks in nothern california
        let rand_d_lon = Double.random(in: -d ..< d)
        let rand_d_lat = Double.random(in: -d ..< d)
        
        UserDefaults.standard.set([rand_d_lat,rand_d_lon], forKey: "location_offset")
        UserDefaults.standard.synchronize()

        return CLLocationCoordinate2D(latitude: rand_d_lat, longitude: rand_d_lon)
    }
    
    func startTimer(){
        Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { (timer) in
            print("Timer fired")
            if let location = self.manager.location{
                self.fullfill(self.anonymizeLocation(location.coordinate))
                self.lastLocation = location.coordinate
            }else if let location = self.lastLocation{
                self.fullfill(self.anonymizeLocation(location))
            }else{
                self.reject(LocationError.timeout)
            }
        }
    }
    
    static func get() -> Promise<CLLocationCoordinate2D>{
        
        return Promise<CLLocationCoordinate2D>(on:.main){ fullfill, reject in
            let provider = LocationProvider(fullfill,reject)
            self.retained.append(provider)
            
            provider.manager.desiredAccuracy = 500//m
            provider.manager.delegate = provider
            switch(CLLocationManager.authorizationStatus()){
            case CLAuthorizationStatus.restricted, CLAuthorizationStatus.denied:
                print("denied")
                reject(LocationError.denied)
                break
            case CLAuthorizationStatus.notDetermined:
                provider.manager.requestAlwaysAuthorization()
                break
            case CLAuthorizationStatus.authorizedAlways,CLAuthorizationStatus.authorizedWhenInUse:
                provider.manager.requestLocation()
                break
            default:
                provider.manager.requestAlwaysAuthorization()
                break
            }
        }
    }
    static var retained:[LocationProvider] = [] //FIXME: hack, not sure why is disaperas otehrwise
    
    var manager:CLLocationManager = CLLocationManager()
    var fullfill:(_ location:CLLocationCoordinate2D)->Void
    var reject:(_ error:Error)->Void

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let last = locations.last else{
            if let last = self.lastLocation{
                self.fullfill(anonymizeLocation(last))
            }else{
                self.reject(LocationError.notAuthorized)
            }
            manager.stopUpdatingLocation()
            return
        }
        self.fullfill( anonymizeLocation(last.coordinate) )
        self.lastLocation = last.coordinate
        manager.stopUpdatingLocation()
    }
    
    func anonymizeLocation(_ loc:CLLocationCoordinate2D) -> CLLocationCoordinate2D{
        let r = LocationProvider.randomLocationOffset()
        let l = loc
        let aproxLoc = CLLocationCoordinate2D(latitude: max(-90,min(90,r.latitude + l.latitude)), longitude:max(-180,min(180, r.longitude + l.longitude)))
        return aproxLoc
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let last = self.lastLocation{
            self.fullfill(anonymizeLocation(last))
        }else{
            self.reject(error)
        }
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print(status)
        if status == .authorizedAlways || status == .authorizedWhenInUse{
            manager.requestLocation()
        }else{
            reject(LocationError.denied)
        }
    }
    
    var lastLocation:CLLocationCoordinate2D?{
        set{
            if let coord = newValue{
                UserDefaults.standard.set([coord.latitude,coord.longitude], forKey: "lastLocation")
            }
        }
        get{
            if let coord = UserDefaults.standard.array(forKey:"lastLocation") as? [Double]{
                return CLLocationCoordinate2D(latitude: coord[0], longitude: coord[1])
            }
            return nil
        }
    }
    
}
