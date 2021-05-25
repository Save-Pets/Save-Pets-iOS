//
//  SearchingResult.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation

struct SearchingResult: Codable {
    let registrant: String?
    let phoneNum: String?
    let email: String?
    let dogRegistNum: String?
    let dogName: String?
    let dogBreed: String?
    let dogSex: String?
    let dogBirthYear: String?
    let dogProfile: String?
    let matchRate: String?
    let isSuccess: Bool
}
