//
//  CategoryDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 23/02/25.
//

import Vapor

struct ResponseCategory: Content, Response {
    var error = false
    
    var categories: [String]
}
