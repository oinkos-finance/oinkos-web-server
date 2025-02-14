//
//  UserTokenDTO.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/11/24.
//

import Vapor
import JWT

struct UserTokenResponseDTO: Content {
    var token: String
}
