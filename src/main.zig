const builtin = @import("builtin");
const std = @import("std");
const fs = std.fs;
const os = std.os;
const mem = std.mem;
const stdout = std.io.getStdOut().writer();
const libc = @cImport(@cInclude("stdio.h"));
const stk = @import("stack.zig");

const OpFn = fn (u8) anyerror!void;

const jumpTable = init: {
    var initial_value = [_]OpFn{opNoop} ** 256;
    initial_value['<'] = opPtrMinus;
    initial_value['>'] = opPtrPlus;
    initial_value['['] = opPush;
    initial_value[']'] = opPop;
    initial_value['+'] = opPlus;
    initial_value['-'] = opMinus;
    initial_value[','] = opGetChar;
    initial_value['.'] = opPutChar;
    break :init initial_value;
};
var ptr: u16 = 0;
var pc: usize = 0;
var ribbon = mem.zeroes([30000]u8);
var stack = stk.Stack(usize, 1024).init();
var disabled = false;
var depth: usize = 0;

pub fn main() anyerror!void {
    // try stdout.print("{s}\n", .{@typeName(@TypeOf(ribbon))});
    // const gpa = std.heap.c_allocator;
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!general_purpose_allocator.deinit());
    const gpa = general_purpose_allocator.allocator();
    const args = try std.process.argsAlloc(gpa);
    defer gpa.free(args);

    if (args.len < 2) {
        // zig fmt: off
        std.debug.print("$0 <file.bf> -- ({s}-{s}-{s} [{s}])\n", .{ 
            @tagName(builtin.cpu.arch),
            @tagName(builtin.os.tag),
            @tagName(builtin.abi),
            if (@hasDecl(builtin, "zig_backend")) @tagName(builtin.zig_backend) else "stageUnknown",
        });
        // zig fmt: on
        os.exit(0);
    }

    const fname = args[1];
    var f = try fs.cwd().openFile(fname, fs.File.OpenFlags{ .mode = .read_only });
    const content = try f.readToEndAlloc(gpa, 1024 * 1024);
    f.close();
    defer gpa.free(content);

    while (true) {
        var c = content[pc];
        log("pc={d} {c}\n", .{ pc, c });
        pc += 1;
        if (disabled) {
            if (c == '[') {
                depth += 1;
            } else if (c == ']') {
                if (depth == 0) {
                    log("  enabling\n", .{});
                    disabled = false;
                } else {
                    depth -= 1;
                }
            }
            continue;
        }
        try jumpTable[c](c);
        if (pc >= content.len) {
            break;
        }
    }
}

fn opNoop(c: u8) !void {
    log("opNoop {c}\n", .{c});
}
fn opNotImplemented(_: u8) !void {
    @panic("not implemented");
}
fn opPlus(_: u8) !void {
    log("opPlus ptr={d} value={d}\n", .{ ptr, ribbon[ptr] });
    ribbon[ptr] +%= 1;
}
fn opMinus(_: u8) !void {
    log("opMinus ptr={d} value={d}\n", .{ ptr, ribbon[ptr] });
    ribbon[ptr] -%= 1;
}
fn opPtrPlus(_: u8) !void {
    log("opPtrPlus ptr={d}\n", .{ptr});
    ptr +%= 1;
    ptr = ptr % 30000;
}
fn opPtrMinus(_: u8) !void {
    log("opPtrMinus ptr={d}\n", .{ptr});
    ptr -%= 1;
    ptr = ptr % 30000;
}
fn opPutChar(_: u8) !void {
    log("opPutChar ptr={d} value={d}\n", .{ ptr, ribbon[ptr] });
    try stdout.print("{c}", .{ribbon[ptr]});
}
fn opGetChar(_: u8) !void {
    log("opGetChar {d}\n", .{ptr});
    const cchar = libc.getchar();
    ribbon[ptr] = @intCast(u8, cchar);
}
fn opPush(_: u8) !void {
    log("opPush ptr={d} value={d}\n", .{ ptr, ribbon[ptr] });
    if (ribbon[ptr] == 0) {
        log("  disabling\n", .{});
        disabled = true;
    } else {
        log("  pushing\n", .{pc - 1});
        stack.push(pc - 1);
    }
}
fn opPop(_: u8) !void {
    log("opPop\n", .{});
    pc = stack.pop();
}

inline fn log(comptime format: []const u8, args: anytype) void {
    // stdout.print(format, args) catch unreachable;
    _ = format;
    _ = args;
}

test "recurse" {
    std.testing.refAllDecls(@This());
}
