//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Rambo on 2021/4/2.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?
    
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage:uiImage!)
            }
        }
    }
}

