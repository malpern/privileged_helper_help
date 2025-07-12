//
//  HelperProtocol.swift
//  helperpoc
//
//  Created by Micah Alpern on 7/11/25.
//

import Foundation

@objc protocol HelperProtocol {
    func createTestFile(reply: @escaping (Bool, String?) -> Void)
    func getHelperInfo(reply: @escaping (Bool, String?) -> Void)
}