const secp256k1lib = @cImport({
    @cInclude("ext.h");
});

pub const Secp256k1 = struct {
    context: *secp256k1lib.secp256k1_context,

    pub fn init() !Secp256k1 {
        var context = secp256k1lib.secp256k1_context_create_sign_verify() orelse return error.FailedInitialize;
        return Secp256k1{
            .context = context,
        };
    }
};
