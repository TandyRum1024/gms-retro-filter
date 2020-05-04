/*
    WARNING : UNOPTIMIZED PILE OF MISERABLE CODE AHEAD -- Prepare your brain
*/
// Update demoscene-ass looking scroller surface
var _t = current_time * 0.001;
surface_set_target(surfScroller);

// draw checkerboard BG
shader_set(shd_rainbow_whatever);
shader_set_uniform_f(shader_get_uniform(shd_rainbow_whatever, "uTime"), _t);
var _bgcol = make_color_hsv(_t * 255, 0, 255);
draw_primitive_begin_texture(pr_trianglestrip, sceneBGTex);
draw_vertex_texture(0, 0, 0, 0);
draw_vertex_texture(surfScrollerWid, 0, 1, 0);
draw_vertex_texture(0, surfScrollerHei, 0, 1);
draw_vertex_texture(surfScrollerWid, surfScrollerHei, 1, 1);
draw_primitive_end();
shader_reset();

// draw cube
d3d_start();
d3d_set_lighting(true);
d3d_set_hidden(false);
d3d_set_culling(true);
var _lighth = current_time * 0.001 * 360;
var _lightv = current_time * 0.001 * 360;
var _boxsz = 128;
d3d_light_define_ambient(c_gray);
d3d_light_enable(1, true);
d3d_light_define_direction(1, lengthdir_x(1, _lighth), lengthdir_y(1, _lighth), 1.0, make_color_hsv(255 * current_time * 0.001, 80, 255));
d3d_set_projection_ortho(0, 0, surfScrollerWid, surfScrollerHei, 0);
d3d_transform_set_rotation_x(current_time * 0.0002 * 360);
d3d_transform_add_rotation_y(current_time * 0.0002 * 360 + 180.0);
d3d_transform_add_rotation_z(current_time * 0.0004 * 360 + 42.0);
d3d_transform_add_translation(surfScrollerWid * 0.5, surfScrollerHei * 0.5, 0);
d3d_draw_block(-_boxsz, -_boxsz, -_boxsz, _boxsz, _boxsz, _boxsz, scenePlateTex, 1, 1);
d3d_transform_set_identity();
d3d_set_culling(false);
d3d_set_hidden(true);
d3d_set_lighting(false);
d3d_end();

// draw sinewave scroller
draw_set_halign(0); draw_set_valign(1);
var _strwid = string_width(scrollerStr) * scrollerStrScale;
var _tx = (surfScrollerWid - _strwid) * 0.5, _ty = surfScrollerHei * 0.5;
for (var i=1; i<=string_length(scrollerStr); i++)
{
    var _off = sin(_t * pi + i * 0.314) * 16;
    var _offr = cos(_t * pi + i * 0.314) * 8;
    var _col = make_color_hsv(_t * 255, 128, 255);
    var _c = string_char_at(scrollerStr, i);
    draw_text_transformed_color(_tx, _ty + _off + scrollerStrScale, _c, scrollerStrScale, scrollerStrScale, _offr, 0, 0, 0, 0, 1.0);
    draw_text_transformed_color(_tx, _ty + _off, _c, scrollerStrScale, scrollerStrScale, _offr, _col, _col, _col, _col, 1.0);
    _tx += string_width(_c) * scrollerStrScale;
}
surface_reset_target();
