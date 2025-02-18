import Vapor

protocol Response {
    var error: Bool { get }
}

struct Success: Content, Response {
    var error = false
}
