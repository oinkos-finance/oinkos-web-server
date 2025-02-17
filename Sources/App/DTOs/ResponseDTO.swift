//
//  ResponseDTOProtocol.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 17/02/25.
//

import Vapor

protocol Response {
    var error: Bool { get }
}
