import Fluent
import Foundation

import struct Foundation.UUID

enum PaymentType: String, Codable {
    case creditCard, debitCard, cash, directTransfer
}

protocol Transaction: Model, Codable {
    var id: UUID? { get set }
    var user: User { get set }
    var title: String { get set }
    var value: Float { get set }
    var category: Category { get set }
    var paymentType: PaymentType { get set }
    var createdAt: Date? { get set }
    var updatedAt: Date? { get set }
}
