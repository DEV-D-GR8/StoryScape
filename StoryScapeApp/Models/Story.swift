//
//  Story.swift
//  StoryScapeApp
//
//  Created by Dev Asheesh Chopra on 02/01/25.
//

import Foundation

struct Story: Codable, Identifiable {
    var id: String = UUID().uuidString
    let title: String
    let introduction: String
    let middle: String
    let conclusion: String
    let introImageURL: String?
    let middleImageURL: String?
    var timestamp: Date = Date()
    var userId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case introduction
        case middle
        case conclusion
        case introImageURL = "intro_image_url"
        case middleImageURL = "middle_image_url"
        case timestamp
        case userId
    }
    
    // Custom init to handle potentially missing fields.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.title = try container.decode(String.self, forKey: .title)
        self.introduction = try container.decode(String.self, forKey: .introduction)
        self.middle = try container.decode(String.self, forKey: .middle)
        self.conclusion = try container.decode(String.self, forKey: .conclusion)
        self.introImageURL = try container.decodeIfPresent(String.self, forKey: .introImageURL)
        self.middleImageURL = try container.decodeIfPresent(String.self, forKey: .middleImageURL)
        self.timestamp = try container.decodeIfPresent(Date.self, forKey: .timestamp) ?? Date()
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
    }
    
    // Fallback init (handy for testing and manual creation)
    init(
        id: String = UUID().uuidString,
        title: String,
        introduction: String,
        middle: String,
        conclusion: String,
        introImageURL: String? = nil,
        middleImageURL: String? = nil,
        timestamp: Date = Date(),
        userId: String? = nil
    ) {
        self.id = id
        self.title = title
        self.introduction = introduction
        self.middle = middle
        self.conclusion = conclusion
        self.introImageURL = introImageURL
        self.middleImageURL = middleImageURL
        self.timestamp = timestamp
        self.userId = userId
    }
}
