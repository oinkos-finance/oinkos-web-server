import Vapor
import JWT

struct ResponseUserToken: Content, Response {
    var error: Bool = false
    var token: String
}
