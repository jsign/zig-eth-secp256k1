// Copyright 2015 Jeffrey Wilcke, Felix Lange, Gustav Simonsson. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be found in
// the LICENSE file.

// This file is a port of go-ethereum/crypto/secp256k1/secp256k1.go with some slight modifications.

const std = @import("std");
const secp256k1lib = @cImport({
    @cInclude("ext.h");
});

pub const PubKey = [65]u8;
pub const Signature = [65]u8;
pub const Message = [32]u8;

pub const Secp256k1 = struct {
    context: *secp256k1lib.secp256k1_context,

    pub fn init() !Secp256k1 {
        var context = secp256k1lib.secp256k1_context_create_sign_verify() orelse return error.FailedInitialize;
        return Secp256k1{
            .context = context,
        };
    }

    pub fn RecoverPubkey(self: Secp256k1, msg: Message, sig: Signature) !PubKey {
        try checkSignature(sig);

        var pubkey: PubKey = undefined;
        if (secp256k1lib.secp256k1_ext_ecdsa_recover(self.context, &pubkey, &sig, &msg) == 0) {
            return error.RecoverFailed;
        }

        return pubkey;
    }

    fn checkSignature(sig: [65]u8) !void {
        if (sig[64] >= 4) {
            return error.InvalidRecoveryID;
        }
    }
};

test "recover sanity" {
    // Useful when the underlying libsecp256k1 API changes to quickly
    // check only recover function without use of signature function
    var msg: Message = undefined;
    _ = try std.fmt.hexToBytes(&msg, "ce0677bb30baa8cf067c88db9811f4333d131bf8bcf12fe7065d211dce971008");
    var sig: Signature = undefined;
    _ = try std.fmt.hexToBytes(&sig, "90f27b8b488db00b00606796d2987f6a5f59ae62ea05effe84fef5b8b0e549984a691139ad57a3f0b906637673aa2f63d1f55cb1a69199d4009eea23ceaddc9301");
    var pubkey1: PubKey = undefined;
    _ = try std.fmt.hexToBytes(&pubkey1, "04e32df42865e97135acfb65f3bae71bdc86f4d49150ad6a440b6f15878109880a0a2b2667f7e725ceea70c673093bf67663e0312623c8e091b13cf2c0f11ef652");

    var s = try Secp256k1.init();
    const pubkey2 = try s.RecoverPubkey(msg, sig);
    try std.testing.expectEqualSlices(u8, &pubkey1, &pubkey2);
}
