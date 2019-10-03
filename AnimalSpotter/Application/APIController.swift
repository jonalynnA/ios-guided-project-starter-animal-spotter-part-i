//
//  APIController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

enum NetworkingError: Error {
    case noData
    case noBearer
    case serverError(Error) // use (Error) here so you get the actual server error
    case unexpectedStatusCode
    case badDecode
}


class APIController {
    
    private let baseUrl = URL(string: "https://lambdaanimalspotter.vapor.cloud/api")!
    
    var bearer: Bearer?
    
    // Create function for fetching all animal names
   
    func fetchAllAnimalNames(completion: @escaping (Result<[String], NetworkingError>) -> Void) { // The Result enum is going to have an [String] for success, and NetworkingError for its failure
        
        guard let bearer = bearer else { // check for bearer first, no bearer = no log in
            completion(.failure(.noBearer))
            return
        }
        
        let requestURL = baseUrl.appendingPathComponent("animals").appendingPathComponent("all")
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.get.rawValue
        
        // "Bearer "6TpUjfcRQiEtxjma1Fy3vEpBqNLf5MMwu0bi6iJoD5E="
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            
            if let error = error {
                NSLog("Error fetching animal names: \(error)")
                completion(.failure(.serverError(error)))
                return
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(.failure(.unexpectedStatusCode))
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let animalNames = try JSONDecoder().decode([String].self, from: data)
                
                completion(.success(animalNames))
            } catch {
                NSLog("Error decoding animal names: \(error)")
                completion(.failure(.badDecode))
            }
            
        }.resume()
        
    }
    
    // Create function to fetch specific animal
    
    func fetchDetails(for animalName: String, completion: @escaping (Result<Animal, NetworkingError>) -> Void) {
        
        guard let bearer = bearer else {
            completion(.failure(.noBearer))
            return
        }
        
        let requestURL = baseUrl.appendingPathComponent("animals").appendingPathComponent(animalName)
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.get.rawValue
        request.setValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
           
            if let error = error {
                NSLog("Error fetching animal details: \(error)")
                completion(.failure(.serverError(error)))
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(.failure(.unexpectedStatusCode))
                return
            }
      
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                
                let animal = try decoder.decode(Animal.self, from: data)
                
                completion(.success(animal))
            } catch {
                NSLog("Error decoding Animal: \(error)")
                completion(.failure(.badDecode))
            }
           
           
        }.resume()
        }
    
      // create function to fetch image
    func fetchImage(at urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching image: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from image fetch data task")
                completion(nil)
                return
            }
            
            let image = UIImage(data: data)
            
            completion(image)
            
        }.resume()
        }
    
    // create function for sign up
    
    func signUp(with user: User, completion: @escaping (Error?) -> Void) {
        
        // Build the URL
        
//        let requestURL = baseUrl.appendingPathComponent("users/signup")
         let requestURL = baseUrl
        .appendingPathComponent("users")
        .appendingPathComponent("signup")
        
        // Build the request
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = HTTPMethod.post.rawValue
        
        // Tell the API that the body is in JSON format
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        
        do {
            let userJSON = try encoder.encode(user)
            request.httpBody = userJSON
        } catch {
            NSLog("Error encoding user object: \(error)")
        }
        
        // Perform the request (data task)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
        // Handle errors
            if let error = error {
                NSLog("Error signing up user: \(error)")
                completion(error)
            }
            // getting a response back from the data task
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                
                let statusCodeError = NSError(domain: "com.JonalynnMasters.animalspotter", code: response.statusCode, userInfo: nil)
                completion(statusCodeError)
            }
            
            // nil means there was no error, everything succeeded.
            completion(nil)
       
        } .resume()
    }
    
    // create function for sign in
    
    func signIn(with user: User, completion: @escaping (Error?) -> Void) {
        
        let requestURL = baseUrl
        .appendingPathComponent("users")
        .appendingPathComponent("login")
        
        var request = URLRequest(url: requestURL)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = HTTPMethod.post.rawValue
        do {
            request.httpBody = try JSONEncoder().encode(user)
        } catch {
            NSLog("Error encoding user for sign in: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                NSLog("Error signing in user: \(error)")
                completion(error)
                return
            }
            
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                let statusCodeError = NSError(domain: "com.JonalynnMasters.animalspotter", code: response.statusCode, userInfo: nil)
                completion(statusCodeError)
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                let noDataError = NSError(domain: "com.JonalynnMasters.animalspotter", code: -1, userInfo: nil)
                completion(noDataError)
                return
            }
            
            do {
                let bearer = try JSONDecoder().decode(Bearer.self, from: data)
                self.bearer = bearer
            } catch {
                NSLog("Error decoding Bearer Token: \(error)")
                completion(error)
            }
            
            completion(nil)
        }.resume()
        
    }
    
  
    
    
}

