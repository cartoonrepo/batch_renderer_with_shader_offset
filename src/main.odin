package main

import     "core:fmt"
import     "core:time"
import     "core:math/rand"
import sdl "vendor:sdl3"
import glm "core:math/linalg/glsl"

import en  "engine"

TITLE :: "Batch Renderer with shader offset(no instancing)"

SCREEN_WIDTH  :: 1280
SCREEN_HEIGHT :: 720

BUNNY_TEST :: false
MAX_QUAD   :: 50_000

Bunny :: struct {
    pos, speed: glm.vec2,
    color: en.Color,
}

main :: proc() {
    en.set_window_flags({.RESIZABLE, .MAXIMIZED})
    en.init_window(TITLE, SCREEN_WIDTH, SCREEN_HEIGHT); defer en.close_window()
    en.vsync(1)

    en.init_renderer(); defer en.cleanup()

    w, h := en.get_window_size_f32()
    pos: glm.vec2 = {w* 0.5, h * 0.5}

    bunnies := make([]Bunny, MAX_QUAD); defer delete(bunnies)
    b_count: int

    for &b in bunnies {
        b.pos   = pos
        b.speed = {rand.float32_range(-200, 200), rand.float32_range(-200, 200)}
        b.color = {u8(rand.float32_range(0, 255)), u8(rand.float32_range(0, 255)), u8(rand.float32_range(0, 255)), 255}
    }

    last_time: f32
    start_tick := time.tick_now()
    main_loop: for {
        current_time := f32(time.duration_seconds(time.tick_since(start_tick)))
        frame_time   := current_time - last_time
        last_time     = current_time

        en.process_event()
        if en.window_should_close() { break main_loop }
        en.clear_background({0, 25, 38, 255})

        w, h = en.get_window_size_f32()

        if BUNNY_TEST {
            bunny_test(bunnies, w, h)
        } else {
            s := abs(glm.cos(current_time) / 2)

            en.draw_quad({s * w,       h * 0.5}, {50, 50}, {200, 0, 0, 255})
            en.draw_quad({w - (s * w), h * 0.5}, {50, 50}, {200, 0, 0, 255})

            en.draw_quad({w * 0.5, s * h},     {50, 50}, {0, 200, 0, 255})
            en.draw_quad({w * 0.5, h - s * h}, {50, 50}, {0, 200, 0, 255})

            key_state := sdl.GetKeyboardState(nil)
            if key_state[i32(sdl.Scancode.W)] || key_state[i32(sdl.Scancode.UP)] {
                pos.y += 200 * frame_time
            }
            if key_state[i32(sdl.Scancode.S)] || key_state[i32(sdl.Scancode.DOWN)] {
                pos.y -= 200 * frame_time
            }
            if key_state[i32(sdl.Scancode.A)] || key_state[i32(sdl.Scancode.LEFT)] {
                pos.x -= 200 * frame_time
            }
            if key_state[i32(sdl.Scancode.D)] || key_state[i32(sdl.Scancode.RIGHT)] {
                pos.x += 200 * frame_time
            }

            en.draw_quad(pos, {50, 50}, {0, 0, 200, 255})
        }

        en.flush_renderer()
        en.swap_window()
    }
}

bunny_test :: proc(bunnies: []Bunny, w, h: f32) {
    for &b in bunnies {
        b.pos += b.speed

        if b.pos.y > h || b.pos.y < 0 {
            b.speed.y *= -1
        }

        if b.pos.x > w || b.pos.x < 0 {
            b.speed.x *= -1
        }

        en.draw_quad(b.pos, {50, 50}, b.color)
    }
}
