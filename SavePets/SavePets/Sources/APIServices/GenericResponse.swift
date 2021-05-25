//
//  GenericResponse.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/19.
//

import Foundation

struct GenericResponse<T: Codable>: Decodable {
    var data: T?
    var message: String?
    
    enum CodingKeys: String, CodingKey {
        case message, data
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try? values.decode(T.self, forKey: .data)
        self.message = try? values.decode(String.self, forKey: .message)
    }
}
