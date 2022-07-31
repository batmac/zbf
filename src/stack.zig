const std = @import("std");
const testing = std.testing;

// comptime stack implementation, no allocator.

pub fn Stack(comptime T: type, comptime capacity: usize) type {
    return struct {
        const Self = @This();
        sp: usize = 0,
        items: [capacity]T = std.mem.zeroes([capacity]T),

        pub inline fn init() Self {
            return Self{};
        }
        pub inline fn deinit(self: *Self) void {
            for (self.items[0..]) |_, i| {
                self.items[i] = 0;
            }
            self.sp = 0;
        }

        pub inline fn push(self: *Self, x: T) void {
            if (self.sp > capacity) {
                @panic("pushing in a full stack");
            }
            self.items[self.sp] = x;
            self.sp += 1;
        }

        pub inline fn pop(self: *Self) T {
            if (self.sp <= 0) {
                @panic("popping an empty stack");
            }
            self.sp -= 1;

            return self.items[self.sp];
        }

        pub inline fn len(self: *Self) usize {
            return self.sp;
        }

        pub inline fn dump(self: *Self) void {
            for (self.items[0..self.sp]) |v, i| {
                std.log.info("{d}: {d}", .{ i, v });
            }
        }
    };
}

test "expect this to succeed" {
    try std.testing.expect(true);
    std.testing.refAllDecls(@This());
}
test "init" {
    _ = Stack(u8, 10).init();
}
test "deinit" {
    var s = Stack(u8, 10).init();
    s.deinit();
}
test "1" {
    var s = Stack(u8, 10).init();
    s.push(1);
    s.push(2);
    std.debug.assert(s.pop() == 2);
    s.push(3);
    s.push(4);
    std.debug.assert(s.pop() == 4);
    std.debug.assert(s.pop() == 3);
    std.debug.assert(s.pop() == 1);
}
