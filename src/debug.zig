const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const heap = std.heap;
const warn = std.debug.warn;
const CircularBuffer = @import("./main.zig").CircularBuffer;

pub fn main() !void {

 var buffer =  CircularBuffer(i32).init(heap.direct_allocator);
    defer buffer.deinit();
    _ = try buffer.setMaxSize(4);

    for ([_]i32 { 1, 3, 4, 5, 6}) |value, j| {
        try buffer.push(value);
        std.debug.warn("j = {}\n", j);
        var tmp = buffer.at(j);
        warn("val = {}\n",buffer.at(j) );
    }
      
    var val = buffer.popStart();
    if (val) |value| {
        testing.expect(value == 1);
    }
    else
        unreachable;
}