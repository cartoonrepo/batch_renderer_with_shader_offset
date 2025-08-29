package engine

import     "core:fmt"
import glm "core:math/linalg/glsl"
import gl  "vendor:OpenGL"

MAX_ELEMENTS :: 8192

VERTEX_SOURCE   :: "assets/shaders/default.vert"
FRAGMENT_SOURCE :: "assets/shaders/default.frag"

Color :: struct {
    r, g, b, a: u8,
}

Vertex :: struct {
    position  : glm.vec2,
    color     : glm.vec4,
    offset    : glm.vec2,
}

Renderer :: struct {
    vao, vbo, ebo : u32,
    shader        : u32,

    vertices : []Vertex,
    indices  : []u32,

    max_quads  : u32,
    quad_count : u32,
}

// /utils
normalize_color :: proc(color: Color) -> [4]f32 {
    return {
        f32(color.r) / 255,
        f32(color.g) / 255,
        f32(color.b) / 255,
        f32(color.a) / 255,
    }
}

clear_background :: proc(color: Color) {
    c := normalize_color(color)

    gl.ClearColor(c.x, c.y, c.z, c.w)
    gl.Clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT)
}

// /render
renderer: Renderer

setup_renderer :: proc(r: ^Renderer) {
    r.max_quads = MAX_ELEMENTS
    r.vertices  = make([]Vertex, r.max_quads * 4)
    r.indices   = make([]u32,    r.max_quads * 6)

    for offset, i: u32; i < r.max_quads * 6 ; i += 6 {
        r.indices[i + 0] = offset + 0
        r.indices[i + 1] = offset + 1
        r.indices[i + 2] = offset + 2
        r.indices[i + 3] = offset + 2
        r.indices[i + 4] = offset + 3
        r.indices[i + 5] = offset + 0
        offset += 4
    }
}

cleanup :: proc() {
    r := &renderer
    gl.DeleteVertexArrays(1, &r.vao)
    gl.DeleteBuffers(1, &r.vbo)
    gl.DeleteBuffers(1, &r.ebo)

    delete(r.vertices)
    delete(r.indices)
}

init_renderer :: proc() {
    r := &renderer
    setup_renderer(r)

    gl.GenVertexArrays(1, &r.vao)
    gl.GenBuffers(1, &r.vbo)
    gl.GenBuffers(1, &r.ebo)

    gl.BindVertexArray(r.vao)

    gl.BindBuffer(gl.ARRAY_BUFFER, r.vbo)
    gl.BindBuffer(gl.ELEMENT_ARRAY_BUFFER, r.ebo)

    v := r.vertices[0]
    i := r.indices[0]

    gl.BufferData(gl.ARRAY_BUFFER,         len(r.vertices) * size_of(v), nil,                    gl.DYNAMIC_DRAW)
    gl.BufferData(gl.ELEMENT_ARRAY_BUFFER, len(r.indices)  * size_of(i), raw_data(r.indices[:]), gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0) // position
    gl.EnableVertexAttribArray(1) // color
    gl.EnableVertexAttribArray(2) // offset

    gl.VertexAttribPointer(0, i32(len(v.position)), gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, position))
    gl.VertexAttribPointer(1, i32(len(v.color)),    gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, color))
    gl.VertexAttribPointer(2, i32(len(v.offset)),   gl.FLOAT, false, size_of(Vertex), offset_of(Vertex, offset))

    ok: bool
    r.shader, ok = gl.load_shaders_file(VERTEX_SOURCE, FRAGMENT_SOURCE)
    if !ok {
        fmt.println("failed to load shaders")
        when gl.GL_DEBUG {
            fmt.println(gl.get_last_error_message())
        }
    }
}

flush_renderer :: proc() {
    r := &renderer

    gl.UseProgram(r.shader)

    w, h := get_window_size_f32()
    projection := glm.mat4Ortho3d(0, w, 0, h, -2, 2)
    gl.UniformMatrix4fv(gl.GetUniformLocation(r.shader, "projection"), 1, false, &projection[0, 0])

    gl.BindVertexArray(r.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, r.vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, len(r.vertices) * size_of(r.vertices[0]), raw_data(r.vertices))

    gl.DrawElements(gl.TRIANGLES, i32(r.quad_count * 6), gl.UNSIGNED_INT, nil)
    gl.BindVertexArray(0)

    r.quad_count  = 0
}

draw_quad :: proc(pos, size: glm.vec2, color: Color) {
    r := &renderer

    if r.quad_count >= r.max_quads {
        flush_renderer()
    }

    offset := r.quad_count * 4

    c := normalize_color(color)
    // simple solution for batch rendering without instacing.
    r.vertices[offset + 0] = Vertex{{0 * size.x, 1 * size.y}, c, pos} // TOP    LEFT
    r.vertices[offset + 1] = Vertex{{1 * size.x, 1 * size.y}, c, pos} // TOP    RIGHT
    r.vertices[offset + 2] = Vertex{{1 * size.x, 0 * size.y}, c, pos} // BOTTOM LEFT
    r.vertices[offset + 3] = Vertex{{0 * size.x, 0 * size.y}, c, pos} // BOTTOM RIGHT

    r.quad_count += 1
}
