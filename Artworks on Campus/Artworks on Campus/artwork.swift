//
//  Artwork.swift
//  Artworks on Campus
//
//  Created by Christopher Wainwright on 10/12/2018.
//  Copyright © 2018 Christopher Wainwright. All rights reserved.
//

import Foundation

struct artwork: Decodable {
    let id: String
    let title: String
    let artist: String
    let yearOfWork: String?
    let Information: String
    let lat: String
    let long: String
    let location: String
    let locationNotes: String
    let fileName: String
    let lastModified: String
    let enabled: String
}
