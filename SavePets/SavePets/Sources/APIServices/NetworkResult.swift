//
//  NetworkResult.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation

enum NetworkResult<T> {
    case success(T)
    case requestErr(T)
    case pathErr
    case serverErr
    case networkFail
}
