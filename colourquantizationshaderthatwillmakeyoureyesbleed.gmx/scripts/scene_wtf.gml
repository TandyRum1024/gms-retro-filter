draw_clear(c_black);

// surface_set_target(oKORN.surfSource);
// Begin 3D drawing
d3d_start();
d3d_set_culling(false);
d3d_set_hidden(true);
draw_set_alpha_test(true);
draw_set_alpha_test_ref_value(0.5);

// 1] Set up the camera
d3d_set_projection_ext(cameraX, cameraY, cameraZ, cameraXto, cameraYto, cameraZto, 0, -1, 0, cameraFov, oKORN.winWid / oKORN.winHei, 0.1, 2048);

// Draw background
draw_set_color_write_enable(1, 1, 1, 0);
draw_set_alpha_test(false);
d3d_set_hidden(false);
draw_set_blend_mode(bm_add);

var _bgguysize = 256;
var _bgrot = current_time * 0.00025 * 360.0;
d3d_transform_set_rotation_x(90);
d3d_transform_add_rotation_y(_bgrot);
draw_set_alpha(1/32);
for (var i=0; i<32; i++)
{
    d3d_transform_add_rotation_y(0.1);
    d3d_draw_cylinder(-sceneBGSize, -sceneBGSize, -2048, sceneBGSize, sceneBGSize, 2048, sceneBGTex, 10, 10, false, 16);
}
// draw_set_alpha(1.0);
d3d_transform_add_rotation_y(_bgrot);
d3d_transform_add_rotation_z(sin(current_time * 0.01 + cos(current_time * 0.125)) * 15);

draw_set_alpha(1/8);
for (var i=0; i<32; i++)
{
    draw_set_color(make_color_hsv(random_range(0, 255), 128, 255));
    d3d_transform_add_rotation_z(sin(current_time * 0.001 + i + cos(current_time * 0.00125 + i)));
    d3d_transform_add_rotation_y(1);
    d3d_draw_wall(-_bgguysize, sceneBGSize * 0.5, -_bgguysize, _bgguysize, sceneBGSize * 0.5, _bgguysize, sceneGuyTex, 1, 1);
}
draw_set_alpha(1.0);
draw_set_alpha_test(true);
d3d_set_hidden(true);
draw_set_blend_mode(bm_normal);

// 2] Draw rotating plate
draw_set_color(make_color_hsv(current_time * 0.0005 * 255, 40, 255));
var _platerot = current_time * 0.0005 * 360.0;
d3d_transform_set_rotation_x(90);
d3d_transform_add_rotation_y(_platerot);
d3d_transform_add_translation(scenePlateX, scenePlateY, scenePlateZ);
d3d_draw_floor(-scenePlateSize, -scenePlateSize, 0, scenePlateSize, scenePlateSize, 0, scenePlateTex, 4, 4);

// 3] Cat
var _guyz = -scenePlateHeight + sceneGuyBaseZ;
var _guyrot = _platerot * 2.0;

// (shadow)
d3d_transform_set_rotation_y(_guyrot);
// draw_set_blend_mode_ext(bm_dest_color, bm_zero);
draw_set_color(c_dkgray);
draw_set_alpha(0.5);
d3d_draw_wall(-sceneGuyWidth, -1, -sceneGuyHeight, sceneGuyWidth, -1, 0, sceneGuyTexShadow, 1, 1);
draw_set_alpha(1.0);
draw_set_color(c_white);
// draw_set_blend_mode(bm_normal);

// (cat)
var _iter = 16;
var _inviter = 1 / 16 * 180;
draw_set_alpha_test(false);
d3d_set_hidden(false);
draw_set_alpha(0.5);
for (var i=0; i<_iter; i++)
{
    d3d_transform_set_rotation_x(90);
    d3d_transform_add_rotation_y(_guyrot + i * _inviter);
    d3d_transform_add_translation(scenePlateX + sceneGuyBaseX, scenePlateY + sceneGuyBaseY, scenePlateZ + _guyz);
    d3d_draw_wall(-sceneGuyWidth, 0, -sceneGuyHeight, sceneGuyWidth, 0, 0, sceneGuyTex, 1, 1);
}
draw_set_alpha(1.0);
draw_set_alpha_test(true);
d3d_set_hidden(true);
draw_set_color_write_enable(1, 1, 1, 1);

// 4] Text
var _textstr = "didhd wjsms rhdiddlrk dkslqslek#tkffuwntpdy dmdkdkdkr;"; //"꺄아앍 고양이다#괴ㅏ아아아앍;";
var _textcolour = make_color_hsv(current_time * 0.01 * 255, 150, 255);
// Stop depth testing
d3d_set_hidden(false);

d3d_transform_set_rotation_y(180 + _guyrot * 0.1 + random_range(-10, 10));
d3d_transform_add_rotation_z(random_range(-10, 10));
d3d_transform_add_scaling(0.5, 0.5, 0.5);
d3d_transform_add_translation(scenePlateX + sceneGuyBaseX + random_range(-32, 32), scenePlateY + sceneGuyBaseY - sceneGuyHeight + random_range(-32, 32), scenePlateZ + _guyz + random_range(-32, 32));
draw_set_halign(1); draw_set_valign(1);
draw_text_color(0, 1, _textstr, 0, 0, 0, 0, 1.0);

d3d_transform_add_translation(0, 0, -1);
draw_text_color(0, 0, _textstr, _textcolour, _textcolour, _textcolour, _textcolour, 1.0);

// re-enable depth testing & other things
d3d_set_hidden(true);
d3d_transform_set_identity();
draw_set_alpha_test(false);
d3d_end();
// surface_reset_target();
