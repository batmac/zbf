const builtin = @import("builtin");
const std = @import("std");
const fs = std.fs;
const os = std.os;
const mem = std.mem;
const stdin = std.io.getStdIn().reader();
const stdout = std.io.getStdOut().writer();
// const libc = @cImport(@cInclude("stdio.h"));
const stk = @import("verybasicstack.zig");

const OpFn = fn (u8) anyerror!void;

var jumpTable = [_]OpFn{opNoop} ** 256;
var ptr: u16 = 0;
var pc: usize = 0;
var ribbon = mem.zeroes([30000]u8);
var stack = stk.Stack.init();
var disabled = false;

fn initJumpTable() anyerror!void {
    comptime {
        jumpTable['<'] = opPtrMinus;
        jumpTable['>'] = opPtrPlus;
        jumpTable['['] = opPush;
        jumpTable[']'] = opPop;
        jumpTable['+'] = opPlus;
        jumpTable['-'] = opMinus;
        jumpTable[','] = opGetChar;
        jumpTable['.'] = opPutChar;
    }
}

pub fn main() anyerror!void {
    // try stdout.print("{s}\n", .{@typeName(@TypeOf(ribbon))});
    // const gpa = std.heap.c_allocator;
    var general_purpose_allocator = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!general_purpose_allocator.deinit());
    const gpa = general_purpose_allocator.allocator();
    const proc_args = try std.process.argsAlloc(gpa);
    defer gpa.free(proc_args);
    const args = proc_args[1..];

    if (args.len == 0) {
        // zig fmt: off
        std.debug.print("$0 <file.bf> -- ({s}-{s}-{s} [{s}])\n", .{ 
            @tagName(builtin.cpu.arch), 
            @tagName(builtin.os.tag), 
            @tagName(builtin.abi), 
            if (@hasDecl(builtin, "zig_backend")) @tagName(builtin.zig_backend) else "stage unknown"
        });
        // zig fmt: on
        os.exit(0);
    }

    const fname = args[0];
    var f = try fs.cwd().openFile(fname, fs.File.OpenFlags{ .mode = .read_only });
    defer f.close();

     try initJumpTable();

    const content = try f.readToEndAlloc(gpa, 1024 * 1024);
    defer gpa.free(content);

    while (true) {
        // try stdout.print("{d}\n", .{stack.items.len});
        // std.time.sleep(1000000000);
        var c = content[pc];
        log("pc={d} {c}\n", .{ pc, c });

        pc += 1;
        if (disabled) {
            if (c == ']') {
                disabled = false;
            }
            continue;
        }
        try jumpTable[c](c);
        if (pc >= content.len) {
            break;
        }
    }
    // try dumpRibbon();
}

fn dumpRibbon() anyerror!void {
    var count: usize = 0;
    for (ribbon) |v, i| {
        try stdout.print("{d}: {d} \n", .{ i, v });
        count += 1;
        if (count % 10 == 0) {
            try stdout.print("\n", .{});
        }
    }
    try stdout.print("\n", .{});
}

fn opNoop(_: u8) anyerror!void {
    // try stdout.print("\n noop {c}\n", .{c});
}

fn opNotImplemented(_: u8) anyerror!void {
    @panic("not implemented");
}

fn opPlus(_: u8) anyerror!void {
    log("opPlus ptr={d} value={d}\n", .{ ptr, ribbon[ptr] });
    ribbon[ptr] +%= 1;
}
fn opMinus(_: u8) anyerror!void {
    log("opMinus ptr={d} value={d}\n", .{ ptr, ribbon[ptr] });
    ribbon[ptr] -%= 1;
}
fn opPtrPlus(_: u8) anyerror!void {
    log("opPtrPlus ptr={d}\n", .{ptr});
    ptr +%= 1;
    ptr = ptr % 30000;
}
fn opPtrMinus(_: u8) anyerror!void {
    log("opPtrMinus ptr={d}\n", .{ptr});
    ptr -%= 1;
    ptr = ptr % 30000;
}
fn opPutChar(_: u8) anyerror!void {
    log("opPutChar {x}\n", .{ribbon[ptr]});

    try stdout.print("{c}", .{ribbon[ptr]});
}
fn opGetChar(_: u8) anyerror!void {
    try stdout.print("?", .{});
    var buf: [1024]u8 = undefined;

    if (try stdin.readUntilDelimiterOrEof(buf[0..], '\n')) |_| {
        ribbon[ptr] = buf[0];
    }
    // const cchar = libc.getchar();
    // ribbon[ptr] = @intCast(u8, cchar);
}

fn opPush(_: u8) anyerror!void {
    if (ribbon[ptr] == 0) {
        log("\n je disable\n", .{});
        disabled = true;
    } else {
        log("\n je stack {d}\n", .{pc - 1});
        stack.push(pc - 1);
    }
}

fn opPop(_: u8) anyerror!void {
    if (ribbon[ptr] != 0) {
        pc = stack.pop();
        log("\n j ai pop {d}\n", .{pc});
    }
}

fn log(comptime format: []const u8, args: anytype) void {
    // stdout.print(format, args) catch unreachable;
    _ = format;
    _ = args;
}

test "simple" {
    std.testing.refAllDecls(@This());
}
