//
//  UIImageView+Extension.swift
//  SavePets
//
//  Created by Haeseok Lee on 2021/05/25.
//

import UIKit

extension UIImageView {
    func imageDownload(url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200, let data = data, error == nil, let image = UIImage(data: data)
                else {
                    print("Download image fail : \(url)")
                    return
            }

            DispatchQueue.main.async() { [weak self] in
                print("Download image success \(url)")
                self?.contentMode = mode
                self?.image = image
            }
        }.resume()
    }
}
