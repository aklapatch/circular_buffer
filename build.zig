const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const lib = b.addStaticLibrary("circular_buffer", "src/main.zig");
    lib.setBuildMode(mode);
    lib.install();

    const exe = b.addExecutable("debugexec", "src/debug.zig");
    exe.setBuildMode(mode);
    exe.install();

    var main_tests = b.addTest("src/main.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}
