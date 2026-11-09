const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // libsecp256k1 static C library.
    const upstream = b.dependency("libsecp256k1", .{});
    const libsecp256k1 = b.addLibrary(.{
        .name = "secp256k1",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
        }),
    });
    libsecp256k1.root_module.addIncludePath(upstream.path(""));
    libsecp256k1.root_module.addIncludePath(upstream.path("src"));
    const common_flags = [_][]const u8{
        "-DENABLE_MODULE_RECOVERY=1",
        "-DECMULT_WINDOW_SIZE=15",
        "-DCOMB_BLOCKS=43",
        "-DCOMB_TEETH=6",
    };
    const asm_flags = [_][]const u8{"-DUSE_ASM_X86_64=1"};
    const cflags: []const []const u8 = if (target.result.cpu.arch == .x86_64) &(common_flags ++ asm_flags) else &common_flags;
    libsecp256k1.root_module.addCSourceFile(.{ .file = b.path("ext.c"), .flags = cflags });
    libsecp256k1.root_module.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{ "precomputed_ecmult.c", "precomputed_ecmult_gen.c" },
        .flags = cflags,
    });
    libsecp256k1.root_module.link_libc = true;
    b.installArtifact(libsecp256k1);

    // Run command.
    const exe = b.addExecutable(.{
        .name = "zig-eth-secp256k1",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.linkLibrary(libsecp256k1);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    b.installArtifact(exe);

    // Tests.
    const main_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    main_tests.root_module.linkLibrary(libsecp256k1);

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&run_main_tests.step);

    // Exported modules.
    _ = b.addModule("zig-eth-secp256k1", .{
        .root_source_file = b.path("src/secp256k1.zig"),
        .target = target,
        .optimize = optimize,
    });
}
