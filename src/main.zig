const std = @import("std");
const testing = std.testing;
const ArrayList = std.ArrayList;
const heap = std.heap;
const warn = std.debug.warn;

pub fn CircularBuffer(comptime T: type) type {
    return struct {
        const Self = @This();
        // I can use the .len variable to be the writing pointer
        // of the buffer, and use another var to point to the read point
        list: ArrayList(T),
        start_idx: usize,

        pub fn init(allocator: *std.mem.Allocator) Self {
            return Self {
                .list = ArrayList(T).init(allocator),
                .start_idx = 0,
            };

        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }

        pub fn start(self: Self) usize {
            return self.start_idx;
        }

        pub fn end(self: Self) usize {
            return self.list.count();
        }

        pub fn count(self: Self) usize {
            return self.list.count() - self.start();
        }

        pub fn capacity(self: Self) usize {
            return self.list.capacity();
        }

        pub fn setMaxSize(self: *Self, new_size: usize) !void {
            try self.list.ensureCapacity(new_size);

            // the array list will not shrink if the list.len is not bigger than the
            // desired capacity
            if (self.list.capacity() > new_size){
                var old_len = self.list.len;

                self.list.len = self.list.capacity();
                self.list.shrink(new_size);
                self.list.len = old_len;

            }
        }

        // append until you reach capacity, and then going over the end
        pub fn push(self: *Self, item: T) !void {
            // insert at the beginning if you have reached the end
            var old_len = self.list.len; 

            try self.list.append(item);
            self.list.len = (old_len + 1) % self.capacity();            
        }

        // I need to account for the wrap around effect of the buffer
        pub fn at(self: Self, idx: usize) T {

            var new_idx = (self.start_idx + idx) % self.capacity();
           
            return self.list.items[new_idx];
        }

        pub fn popEnd(self: *Self) ?T {
            var retval = self.list.pop();            
            self.list.len = (self.list.len + self.capacity() -1) % self.capacity();
            return retval;
        }

        pub fn popStart(self: *Self) ?T {
            
            if (self.count() == 0 ) return null;
            var old_start = self.start_idx;
            self.start_idx += 1;
            return self.list.items[old_start];
        }

        pub const Iterator = struct {
            buffer: *const Self,

            count: usize,

            pub fn next(it: *Iterator) ?T {
                if (it.count >= it.buffer.count()) return null;
                const val = it.buffer.at(it.count);
                it.count += 1;
                return val;
            } 

            pub fn reset(it: *Iterator) void {
                it.count = 0;
            }

        };

        pub fn iterator(self: *const Self) Iterator {
            return Iterator{
                .buffer = self,
                .count = 0,
            };
        }
    };
}

test ".init()" {
    var buffer =  CircularBuffer(i32).init(heap.direct_allocator);
    defer buffer.deinit();
    _ = try buffer.setMaxSize(4);
    testing.expect(buffer.start() == 0);
    testing.expect(buffer.end() == 0);
    testing.expect(buffer.capacity() == 4);
    testing.expect(buffer.count() == 0);
}

test "push and pop and Iterator" {
    var buffer =  CircularBuffer(i32).init(heap.direct_allocator);
    defer buffer.deinit();
    _ = try buffer.setMaxSize(4);

    for ([_]i32 { 1, 3, 4, 5, 6}) |value, j| {
        try buffer.push(value);
        testing.expect(buffer.at(j) == value);
    }

    var tmp  = buffer.popEnd();
    if (tmp) |value| {
        testing.expect(value == 6);
    }
    else
        unreachable;

    // this value was overwritten by the value pus earlier
    tmp = buffer.popStart();
    if (tmp)|value| {
        testing.expect(value == 6);
    }
    else
        unreachable;

    var it = buffer.iterator();

    tmp = it.next();
    if (tmp) |val| 
        testing.expect(val == 3);

    tmp = it.next();
    if (tmp) |val|
        testing.expect(val == 4);

    it.reset();

    tmp = it.next();
    if (tmp) |val|
        testing.expect(val == 3);
}
