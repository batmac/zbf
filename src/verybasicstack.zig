const std = @import("std");

const SIZE = 1024;

pub const Stack = struct {
    size: usize = SIZE,
    sp: usize = 0,
    mem: [SIZE]usize = std.mem.zeroes([SIZE]usize),

    pub inline fn init() Stack {
        return Stack{};
    }

    pub inline fn push(self: *Stack, x: usize) void {
        if (self.sp > self.size) {
            @panic("pushing in a stack which is full");
        }
        self.mem[self.sp] = x;
        self.sp += 1;
    }
    pub inline fn pop(self: *Stack) usize {
        if (self.sp <= 0) {
            @panic("popping an empty stack");
        }
        self.sp -= 1;
        const x = self.mem[self.sp];
        return x;
    }

    pub inline fn len(self: *Stack) usize {
        return self.sp;
    }

    pub inline fn dump(self: *Stack) void {
        const mem = self.mem[0..self.sp];
        for (mem) |v, i| {
            std.log.info("{d}:{x}", .{ i, v });
        }
    }
};

test "expect this to succeed" {
    try std.testing.expect(true);
}

test "simple" {
    std.testing.refAllDecls(@This());
}

test "dump" {
    var s = Stack.init();
    s.push(1);
    s.dump();
}

// pub fn main() anyerror!void {
//     var s = Stack.init();
//     while (true) {
//     _=s.pop();
//     }
//     s.dump();
//}
