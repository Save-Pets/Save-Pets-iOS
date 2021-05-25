//
//  APIConstants.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation

struct APIConstants {
    static let baseURL = "http://ec2-13-125-252-86.ap-northeast-2.compute.amazonaws.com:5000"
    
    static let enrollmentURL = APIConstants.baseURL + "/register"
    
    static let searchingURL = APIConstants.baseURL + "/lookup"
}
