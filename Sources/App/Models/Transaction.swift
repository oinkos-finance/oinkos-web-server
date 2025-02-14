//
//  Transaction.swift
//  OinkosWebServer
//
//  Created by Sam Nascimento on 13/02/25.
//

import Fluent

import struct Foundation.UUID

enum PaymentType: String, Codable {
    case creditCard, debitCard, cash, directTransfer
}

protocol Transaction: Model {
    var id: UUID? { get set }
    var title: String { get set }
    var value: Float { get set }
    var category: PaymentType { get set }
}
