//
//  BitconchIoTransactionExtensions.swift
//  EosioSwiftiOSExampleApp

//  Created by brave on 2019/10/16
//  Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//


import UIKit
import PromiseKit
import EosioSwift

class TransactionModel: Encodable {
    /// Array of signatures.
    var signatures: [String]?
    var compression: String = "none"
    var transaction: EosioTransaction?
}

extension EosioTransaction {
    /// Signs a transaction
    ///
    /// - Parameter completion: Called with an `EosioResult` consisting of a `Bool` for success and an optional `EosioError`.
    public func signOffLine(completion: @escaping (EosioResult<Bool, EosioError>, String) -> Void) {
        sign { (result) in
            switch result {
            case .failure(let error):
                completion(.failure(error), "")
            case .success(let success):
                completion(.success(success), self.getTransactionBody())
            }
        }
    }
    
    /// 返回交易体
    func getTransactionBody() -> String {
        let model: TransactionModel = TransactionModel()
        model.signatures = self.signatures
        model.transaction = self
        do {
            return try model.toJsonString(convertToSnakeCase: true, prettyPrinted: true)
        } catch {
            return ""
        }
    }

}
