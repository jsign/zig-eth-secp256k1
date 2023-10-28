const secp256k1lib = @cImport({
    @cInclude("ext.h");
});

pub const Secp256k1 = struct {
    pub fn init() Secp256k1 {
        _ = secp256k1lib.secp256k1_context_create_sign_verify();
        return .{};
    }
};
