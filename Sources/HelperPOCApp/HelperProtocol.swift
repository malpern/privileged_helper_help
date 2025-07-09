import Foundation

@objc protocol HelperProtocol {
    func createTestFile(reply: @escaping (Bool, String?) -> Void)
    func getHelperInfo(reply: @escaping (Bool, String?) -> Void)
}