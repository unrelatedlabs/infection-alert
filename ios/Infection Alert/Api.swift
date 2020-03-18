//
//  Api.swift
//  Infection Alert
//
//  Created by Peter K on 3/13/20.
//  Copyright © 2020 Peter Kuhar. All rights reserved.
//

import UIKit

import Promises
import SwiftJWT
import CryptorECC


enum ApiError:Error{
    case notEncodable
    case serveError
    case invalidResponse
}

import CommonCrypto

extension String {
    func sha1() -> String {
        let data = Data(self.utf8)
        var digest = [UInt8](repeating: 0, count:Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        let hexBytes = digest.map { String(format: "%02hhx", $0) }
        return hexBytes.joined()
    }
}

class Authentication{
    
    func generateKey() -> String{

        let p256PrivateKey = try! ECPrivateKey.make(for: .prime256v1)
        let privateKeyPEM = p256PrivateKey.pemString
            
        return privateKeyPEM
    }
    
    func get_or_generate_keys()->String{
        if let key = UserDefaults.standard.string(forKey: "key"){
            return key
        }
        
        let key = generateKey()
        UserDefaults.standard.set(key, forKey: "key")
        return key
    }
    
    /*
      User id is a sha1 of the public key.
      public key is sent in the jwt token for verification
     */
    func new_jwt_token() -> String{
        let key = get_or_generate_keys()
        
        let jwtSigner = JWTSigner.es256(privateKey: key.data(using: .utf8)! )
        let myHeader = Header()

        struct MyClaims: Claims {
            let exp: Date
            let uid: String
            let pbk: String
        }
        
        let pubKey = try! ECPrivateKey.init(key: key).extractPublicKey()
        
        
        let myClaims = MyClaims( exp: Date(timeIntervalSinceNow: 3600), uid: pubKey.pemString.sha1() ,pbk: pubKey.pemString)

        //let myClaims = ClaimsStandardJWT(exp: Date(timeIntervalSinceNow: 60*10))
        
        var myJWT = JWT(header: myHeader, claims: myClaims)

        
        let signedJWT = try! myJWT.sign(using: jwtSigner)
        

        return signedJWT
        
    
    }
}

struct ApiResponse:Codable{
    var success:Bool
    var error:String?
}

class Api: NSObject {
 
    //let endpointPrefix =  "https://infection-alert.appspot.com"
    static let endpointPrefix =  "https://4d172dfe.ngrok.io"

    static func post<T>(_ path:String, data:T) -> Promise<ApiResponse> where T : Encodable{
        return Promise<ApiResponse>(on: .main) { fulfill, reject in
            let url = URL(string: path, relativeTo: URL(string: self.endpointPrefix))!.absoluteURL
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            guard let uploadData = try? encoder.encode(data) else {
                reject(ApiError.notEncodable)
                return
            }
            
            print("request size",uploadData.count)
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(Authentication().new_jwt_token())" , forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 30
            
            let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
                if let error = error {
                    print ("error: \(error)")
                    reject(error)
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    print ("server error")
                    reject(ApiError.serveError)
                    return
                }
                
                guard (200...299).contains(response.statusCode) else {
                    print ("server error", response.statusCode)
                    if let data = data, let dataString = String(data: data, encoding: .utf8){
                        print(dataString)
                    }
                    
                    reject(ApiError.serveError)
                    return
                }
                
                if let mimeType = response.mimeType,
                    mimeType == "application/json",
                    let data = data,
                    let dataString = String(data: data, encoding: .utf8) {
                    print ("got data: \(dataString)")
                    if let resp = try? JSONDecoder().decode(ApiResponse.self, from: data){
                        fulfill(resp)
                        return
                    }
                }
                reject(ApiError.invalidResponse)
                
                
            }
            task.resume()
        }
    }
}

extension Api{
    
}
