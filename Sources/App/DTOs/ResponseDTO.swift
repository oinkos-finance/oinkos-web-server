import Vapor

protocol Response {
    var error: Bool { get }
}
