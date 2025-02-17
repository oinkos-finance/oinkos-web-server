//
//  UserTokenDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/11/24.
//

import Vapor
import JWT

struct ResponseUserToken: Content, Response {
    var error: Bool = false
    var token: String
}
