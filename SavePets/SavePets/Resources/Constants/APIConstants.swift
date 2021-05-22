//
//  APIConstants.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation

struct APIConstants {
    static let baseURL = "http://52.79.235.100:5000"
    
    static let enrollmentURL = APIConstants.baseURL + "/register"
    
    static let searchingURL = APIConstants.baseURL + "/lookup"
}
