//
//  BitconchIoSignatureExtensions.swift
//  EosioSwiftiOSExampleApp

//  Created by brave on 2019/10/12
//  Copyright (c) 2017-2019 block.one and its contributors. All rights reserved.
//


import Foundation
import EosioSwift

public extension String {
    /// Returns a tuple breaking an EOSIO key formatted xxx_xx_xxxxxxx into components.
    func bitconchIoComponents() throws -> (prefix: String, version: String, body: String) {
        let components = self.components(separatedBy: "_")
        
        if components.count == 3 {
            return (prefix: components[0], version: components[1], body: components[2])
            
        } else if components.count == 1 {  // legacy format
            guard self.count > 3 else {
                throw EosioError(.signatureProviderError, reason: "\(self) is not a valid eosio key")
            }
            let eos = "BUS"
            let prefix = String(self.prefix(eos.count))
            let rest = String(self.suffix(self.count-eos.count))
            if prefix == eos {
                return (prefix: eos, version: "K1", body: rest)
            } else {
                return (prefix: "", version: "K1", body: self)
            }
            
        } else {
            throw EosioError(.signatureProviderError, reason: "\(self) is not a valid eosio key")
        }
    }
}

public extension Data {
    
    /// Returns a legacy EOSIO public key as a string formatted EOSxxxxxxxxxxxxxxxxxxx.
    var toBitconchIoLegacyPublicKey: String {
        let check = RIPEMD160.hash(message: self).prefix(4)
        return "BUS" + (self + check).base58EncodedString
    }
    
    /// Create a Data object in compressed ANSI X9.63 format from an EOSIO public key.
    init(bitconchPublicKey: String) throws {
        guard bitconchPublicKey.count > 0 else {
            throw EosioError(.signatureProviderError, reason: "Empty string is not a valid eosio key")
        }
        let components = try bitconchPublicKey.bitconchIoComponents()
        
        // decode the basse58 string into Data with the last 4 bytes being the checksum, throw error if not a valid b58 string
        guard let keyAndChecksum = Data.decode(base58: components.body) else {
            throw EosioError(.signatureProviderError, reason: "\(components.body) is not valid base 58")
        }
        
        // get the key, checksum and hash
        let key = keyAndChecksum.prefix(keyAndChecksum.count-4)
        let checksum = keyAndChecksum.suffix(4)
        var keyToHash = key
        if components.prefix == "PUB" || components.version == "R1" {
            keyToHash = key + components.version.data(using: .utf8)!
        }
        let hash = RIPEMD160.hash(message: keyToHash)
        
        // if the checksum and hash do not match, throw an error
        guard checksum == hash.prefix(4) else {
            throw EosioError(.signatureProviderError, reason: "Public key: \(key.hex) with checksum: \(checksum.hex) does not match \(hash.prefix(4).hex)")
        }
        // all done, set self to the key
        self = key
    }
    
}
