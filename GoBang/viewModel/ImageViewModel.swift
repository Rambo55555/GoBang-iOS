//
//  ImageViewModel.swift
//  GoBang
//
//  Created by Rambo on 2021/5/6.
//

import SwiftUI
import Combine

class ImageViewModel: ObservableObject {
    @Published var steadyStateZoomScale: CGFloat = 1.0
    @Published var steadyStatePanOffset: CGSize = .zero
    @Published private(set) var backgroundImage: UIImage?
    var backgroundURL: URL? = URL(string: "http://qs5xv187z.hn-bkt.clouddn.com/2021_2_1439.jpg")
//    var backgroundURL: URL? {
//        get {
//            self.backgroundURL
//        }
//        set {
//            emojiArt.backgroundURL = newValue?.imageURL
//            fetchBackgroundImageData()
//        }
//    }
    init() {
        
    }
    private var fetchImageCancellable: AnyCancellable?
    func fetchBackgroundImageData(onResponse: @escaping () -> ())  {
        backgroundImage = nil
        if let url = backgroundURL {
            fetchImageCancellable?.cancel() // cancel the previous one
            // assign only works if you have Never as your error
            fetchImageCancellable = URLSession.shared.dataTaskPublisher(for: url)
                .map { data, uRLResponse in UIImage(data: data)}
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: {_ in onResponse() }, receiveValue: {data in self.backgroundImage = data})
//                .replaceError(with: nil)
//                .assign(to: \.backgroundImage, on: self)
            
        }
    }
    func getImageUrl(type: String, onResponse: @escaping () -> ()) {
        // Prepare URL
        let url = URL(string: "http://localhost:8080/image/getRandomOne?type=" + type)
        guard let requestUrl = url else { fatalError() }
        print("fetch background image......\(url)")
        // Prepare URL Request Object
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"

        // Perform HTTP Request
        let task = URLSession.shared.dataTask(with: requestUrl) { (data, response, error) in
            DispatchQueue.main.async { [self] in
                // Check for Error
                if let error = error {
                    print("Error took place \(error)")
                    return
                }
         
                // Convert HTTP Response Data to a String
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response data string:\n \(dataString)")
                    
                    do {
                        // make sure this JSON is in the format we expect
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            if let statusCode = json["statusCode"] as? Int{
                                if statusCode == 200 {
                                    let jsonData: NSDictionary = json["data"] as! NSDictionary
                                    self.backgroundURL = URL(string: jsonData["url"] as! String)
                                    onResponse()
                                    print("login success")
                                }
                            }
                        }
                    } catch let error as NSError {
                        print("Failed to load: \(error.localizedDescription)")
                    }
                    
                }
            }
        }
        task.resume()
    }
}
