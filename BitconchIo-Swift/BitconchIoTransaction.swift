//
//  BitconchIoTransaction.swift
//  EosioSwiftiOSExampleApp

//  Created by brave on 2019/10/17
//  Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//


import UIKit
import PromiseKit
import EosioSwift
import EosioSwiftAbieosSerializationProvider
import EosioSwiftSoftkeySignatureProvider

/// Action data structure for transaction.
struct TransferActionData: Codable {
    var from: EosioName
    var to: EosioName
    var quantity: String
    var memo: String = ""
}

public struct TransactionParameter {
    var endpoint: URL
    var code: String = ""
    var from: String = ""
    var to: String = ""
    var quantity: String = ""
    var memo: String = ""
    var privateKeys: [String] = [""]
    
    public init(endpoint: URL, code: String, from: String, to: String, quantity: String, memo: String,  privateKeys: [String]) {
        self.endpoint = endpoint
        self.code = code
        self.from = from
        self.to = to
        self.quantity = quantity
        self.memo = memo
        self.privateKeys = privateKeys
    }

}

public class BitconchIoTransaction {
    // Executed when the "Send Tokens" button is tapped.
    static public func executeTransferTransaction(parameter: TransactionParameter, completion: @escaping (EosioResult<Bool, EosioError>, String) -> Void
        ) {
        
        let rpcProvider: EosioRpcProvider = EosioRpcProvider(endpoint: parameter.endpoint)
        let serializationProvider = EosioAbieosSerializationProvider()
        let signatureProvider = try! BitconchIoSignatureProvider(privateKeys: parameter.privateKeys)
        
        let transactionFactory: EosioTransactionFactory = EosioTransactionFactory(
            rpcProvider: rpcProvider,
            signatureProvider: signatureProvider,
            serializationProvider: serializationProvider
        )
        
        // Get a new transaction from our transaction factory.
        let transaction = transactionFactory.newTransaction()
        
        // Set up our transfer action.
        let action = try! EosioTransaction.Action(
            account: EosioName(parameter.code),
            name: EosioName("transfer"),
            authorization: [EosioTransaction.Action.Authorization(
                actor: EosioName(parameter.from),
                permission: EosioName("active")
                )],
            data: TransferActionData(
                from: EosioName(parameter.from),
                to: EosioName(parameter.to),
                quantity: parameter.quantity,
                memo: parameter.memo
            )
        )
        
        // Add that action to the transaction.
        transaction.add(action: action)
        
        // Sign and return Body
        // Remember, you can also get promises back with: `transaction.signAndBroadcast(.promise)`.
        transaction.signOffLine { (result, body) in
            // Handle our result, success or failure, appropriately.
            switch result {
            case .failure (let error):
                print("ERROR SIGNING OR BROADCASTING TRANSACTION")
                print(error)
                print(error.reason)
            case .success:
                print(body)
            }
        }
    }
}
