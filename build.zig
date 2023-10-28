const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-eth-secp256k1",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    exe.addIncludePath(.{ .path = "." });
    exe.addIncludePath(.{ .path = "libsecp256k1" });
    exe.addIncludePath(.{ .path = "libsecp256k1/src" });
    exe.defineCMacro("USE_FIELD_10X26", "1");
    exe.defineCMacro("USE_SCALAR_8X32", "1");
    exe.defineCMacro("USE_ENDOMORPHISM", "1");
    exe.defineCMacro("USE_NUM_NONE", "1");
    exe.defineCMacro("USE_FIELD_INV_BUILTIN", "1");
    exe.defineCMacro("USE_SCALAR_INV_BUILTIN", "1");
    exe.addCSourceFile(.{ .file = .{ .path = "ext.c" }, .flags = &[0][]const u8{} });
    exe.linkLibC();

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);

    const main_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);
}
