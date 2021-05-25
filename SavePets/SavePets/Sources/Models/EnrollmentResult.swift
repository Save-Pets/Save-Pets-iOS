//
//  EnrollmentResult.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation

struct EnrollmentResult: Codable {
    let dogRegistNum: String?
    let dogName: String?
    let dogBreed: String?
    let dogSex: String?
    let dogBirthYear: String?
    let dogProfile: String?
    let isSuccess: Bool
}
