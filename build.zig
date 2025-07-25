pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{ .preferred_optimize_mode = .ReleaseSafe });
    const install_options = std.Build.Step.InstallArtifact.Options{ .dest_dir = .{ .override = .prefix } };

    const common = std.Build.Module.Import{
        .name = "common",
        .module = b.createModule(.{ .root_source_file = b.path("src/common.zig") }),
    };

    const game = b.addExecutable(.{
        .name = "diab2gcu_prototype",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/game/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{ common, .{
                .name = "sam701/zig-toml",
                .module = b.lazyDependency("toml", .{}).?.module("toml"),
            } },
        }),
    });
    if (target.query.isNativeOs() and target.result.os.tag != .windows) {
        game.linkSystemLibrary("ncursesw");
        game.linkLibC();
    } else game.linkLibrary(b.lazyDependency("pdcurses", .{
        .optimize = .ReleaseFast,
        .target = target,
    }).?.artifact("zig-pdcurses"));
    b.getInstallStep().dependOn(&b.addInstallArtifact(game, install_options).step);

    const ds1_to_toml = b.addExecutable(.{
        .name = "ds1-to-toml",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/ds1-to-toml/main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .imports = &.{common},
        }),
    });
    const ds1_to_toml_install = b.addInstallArtifact(ds1_to_toml, install_options);
    b.step("ds1-to-toml", "Build the converter utility").dependOn(&ds1_to_toml_install.step);

    blk: {
        var run: *std.Build.Step.Run = undefined;
        defer b.step("run", "-- [|ds1-to-toml] [args...]").dependOn(&run.step);
        if (b.args) |args|
            if (mem.eql(u8, args[0], ds1_to_toml.name)) {
                run = b.addRunArtifact(ds1_to_toml);
                run.step.dependOn(&ds1_to_toml_install.step);
                run.addArgs(args[1..]);
                break :blk;
            };
        run = b.addRunArtifact(game);
        run.step.dependOn(b.getInstallStep());
        if (b.args) |args| run.addArgs(args);
    }
}

const mem = std.mem;
const std = @import("std");
