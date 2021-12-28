const std = @import("std");
const testing = std.testing;
const assert = std.debug.assert;
const log = std.log.scoped(.day12);

pub fn run(allocator: std.mem.Allocator) anyerror!void {
    var input_str = @embedFile("../data/day12_input.txt");
    var graph = Graph.fromStrAlloc(allocator, input_str);
    defer graph.vertices.deinit();
    defer graph.edges.deinit();
    var num_paths1 = graph.findNumPaths(allocator, false);
    log.info("Part 1: num paths {d}", .{num_paths1});

    var num_paths2 = graph.findNumPaths(allocator, true);
    log.info("Part 2: num paths {d}", .{num_paths2});
}

const start_value: [2]u8 = .{ '>', '>' };
const end_value: [2]u8 = .{ '!', '!' };
const graph_max_size = 100;
const Graph = struct {
    vertices: std.ArrayList([2]u8),
    edges: std.ArrayList([2]usize), // vertex indicies

    pub fn lookupOrCreateVertex(self: *Graph, value: [2]u8) usize {
        for (self.vertices.items) |v, i| {
            if (std.mem.eql(u8, &v, &value)) return i;
        }

        self.vertices.append(value) catch unreachable;
        return self.vertices.items.len - 1;
    }

    pub fn fromStrAlloc(allocator: std.mem.Allocator, str: []const u8) Graph {
        var graph: Graph = .{
            .vertices = std.ArrayList([2]u8).init(allocator),
            .edges = std.ArrayList([2]usize).init(allocator),
        };

        var it = std.mem.tokenize(u8, str, "\n");
        while (it.next()) |line| {
            var split_pos = std.mem.indexOf(u8, line, "-").?;
            var from_str = line[0..split_pos];
            var to_str = line[split_pos + 1 ..];

            if (std.mem.eql(u8, from_str, "start")) from_str = &start_value;
            if (std.mem.eql(u8, to_str, "start")) to_str = &start_value;
            if (std.mem.eql(u8, from_str, "end")) from_str = &end_value;
            if (std.mem.eql(u8, to_str, "end")) to_str = &end_value;

            var from: [2]u8 = undefined;
            var to: [2]u8 = undefined;
            std.mem.copy(u8, &from, from_str);
            std.mem.copy(u8, &to, to_str);

            var i_vertex_from = graph.lookupOrCreateVertex(from);
            var i_vertex_to = graph.lookupOrCreateVertex(to);
            graph.edges.append(.{ i_vertex_from, i_vertex_to }) catch unreachable;
        }
        return graph;
    }

    pub fn isBigCave(value: [2]u8) bool {
        return value[0] >= 'A' and value[0] <= 'Z';
    }

    pub fn findNumPaths(self: *Graph, allocator: std.mem.Allocator, allow_single_small_cave_revisit: bool) usize {
        var num_paths_found: usize = 0;

        var i_start = self.lookupOrCreateVertex(start_value);
        var i_end = self.lookupOrCreateVertex(end_value);

        var search_stack = std.ArrayList(std.ArrayList(usize)).init(allocator);
        defer {
            for (search_stack.items) |item| item.deinit();
            search_stack.deinit();
        }
        {
            var list = std.ArrayList(usize).init(allocator);
            list.append(i_start) catch unreachable;
            search_stack.append(list) catch unreachable;
        }
        while (search_stack.items.len > 0) {
            // pop stack
            var current_path = search_stack.pop();
            defer current_path.deinit();
            var current_vertex = current_path.items[current_path.items.len - 1];

            if (current_vertex == i_end) {
                num_paths_found += 1;
                //std.debug.print("Found path ({d})\n", .{num_paths_found});
                //for (current_path.items) |p| std.debug.print("{s} -> ", .{self.vertices.items[p]});
                //std.debug.print("\n", .{});
            } else {

                // For part 2.
                var current_path_num_single_small_cave_revisits: usize = 0;
                if (allow_single_small_cave_revisit) {
                    // Count number of times the same small cave has been revisited
                    for (current_path.items) |p1, i| {
                        if (isBigCave(self.vertices.items[p1])) continue;
                        var num_revisits: usize = 0;
                        for (current_path.items) |p2, j| {
                            if (i == j or isBigCave(self.vertices.items[p2])) continue;
                            if (p1 == p2) num_revisits += 1;
                        }

                        current_path_num_single_small_cave_revisits =
                            std.math.max(current_path_num_single_small_cave_revisits, num_revisits);
                    }
                }

                for (self.edges.items) |e| {
                    var candidate_vertex: ?usize = null;
                    if (e[0] == current_vertex)
                        candidate_vertex = e[1];
                    if (e[1] == current_vertex)
                        candidate_vertex = e[0];

                    if (candidate_vertex == null) continue;

                    var candidate_has_already_been_visited: bool = false;
                    for (current_path.items) |p| {
                        if (p == candidate_vertex.?) {
                            candidate_has_already_been_visited = true;
                            break;
                        }
                    }
                    var allowed_to_visit: bool =
                        isBigCave(self.vertices.items[candidate_vertex.?]) or
                        !candidate_has_already_been_visited;

                    // Extra part 2 checks
                    if (allow_single_small_cave_revisit and !allowed_to_visit) {
                        allowed_to_visit =
                            !isBigCave(self.vertices.items[candidate_vertex.?]) and
                            candidate_vertex.? != i_start and
                            current_path_num_single_small_cave_revisits < 1;
                    }

                    if (allowed_to_visit) {
                        var list = std.ArrayList(usize).init(allocator);
                        // Copy the current path and add the new candidate vertex.
                        list.appendSlice(current_path.items) catch unreachable;
                        list.append(candidate_vertex.?) catch unreachable;
                        search_stack.append(list) catch unreachable;
                    }
                }
            }
        }

        return num_paths_found;
    }
};

const example0 =
    \\start-AA
    \\start-bb
    \\AA-cc
    \\AA-bb
    \\bb-dd
    \\AA-end
    \\bb-end
;

const example1 =
    \\dc-end
    \\HN-start
    \\start-kj
    \\dc-start
    \\dc-HN
    \\LN-dc
    \\HN-end
    \\kj-sa
    \\kj-HN
    \\kj-dc
;

const example2 =
    \\fs-end
    \\he-DX
    \\fs-he
    \\start-DX
    \\pj-DX
    \\end-zg
    \\zg-sl
    \\zg-pj
    \\pj-he
    \\RW-he
    \\fs-DX
    \\pj-RW
    \\zg-RW
    \\start-pj
    \\he-WI
    \\zg-he
    \\pj-fs
    \\start-RW
;

test "part 1 example 1" {
    var graph = Graph.fromStrAlloc(testing.allocator, example1);
    defer graph.vertices.deinit();
    defer graph.edges.deinit();
    var num_paths = graph.findNumPaths(testing.allocator, false);
    try testing.expectEqual(num_paths, 19);
}

test "part 1 example 2" {
    var graph = Graph.fromStrAlloc(testing.allocator, example2);
    defer graph.vertices.deinit();
    defer graph.edges.deinit();
    var num_paths = graph.findNumPaths(testing.allocator, false);
    try testing.expectEqual(num_paths, 226);
}

test "part 2 example 1" {
    var graph = Graph.fromStrAlloc(testing.allocator, example0);
    defer graph.vertices.deinit();
    defer graph.edges.deinit();
    var num_paths = graph.findNumPaths(testing.allocator, true);
    try testing.expectEqual(num_paths, 36);
}
