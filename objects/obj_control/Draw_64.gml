/// @description Insert description here+
// You can write your code in this editor

var _frame_index = 8;
var _frame_time = 8;
var _lips = undefined;
var _apos = 0;
var _story = "";
var _dostory = false;

draw_set_font(global.fonts);

if(keyboard_check_pressed(vk_escape)) {
/* Only for building
	save_json("lines.json", global.liplines);
*/
	game_end();
}

/* Only for building
if(keyboard_check_pressed(vk_numpad0)) {
	var _ln = array_length(global.liplines);
	global.liplines[_ln] = floor(current_time - stim) / 1000;
}
*/

if(keyboard_check_pressed(vk_space)) {
	speaking = !speaking;
	if(speaking) {
		speak();
		dtim = current_time;
		stim = current_time;
		lipline = 0;

	}
}

if(speaking) {
	_apos = audio_sound_get_track_position(snd);
	if(_apos >= audio_length) {
		speaking = false;
		audio_stop_sound(snd);
	} else {
		if(time_index < (lip_frames - 1)) {
			_lips = global.liptimes.mouthCues[time_index];
			_frame_time = _lips.s;
			_frame_index = lipcode_to_index(_lips.v);
			_lips = global.liptimes.mouthCues[time_index + 1];
			if(_lips.s < _apos) {
				time_index++;
				_frame_index = lipcode_to_index(_lips.v);
			}
		} else {
			// Dunno what's needed here
			// We're at the end, should be about to stop
			speaking = false;
			audio_stop_sound(snd);
		}
	}
} else {
	_lips = global.liptimes.mouthCues[0];
	_frame_time = _lips.s;
	_frame_index = lipcode_to_index(_lips.v);
}

var _frame_scale = room_height / sprite_get_height(global.frame);

draw_sprite_ext(global.frame, 0, 0, 0, _frame_scale, _frame_scale, 0, c_white, 1);
draw_sprite(global.lipsprite, _frame_index, 28, 28);
// draw_set_colour(c_black);
draw_set_colour(c_white);

if(speaking) {
	rfps += fps_real;
	rcnt++;
	
	if(current_time > (dtim + 1000)) {
		dtim = current_time;
		dfps = rfps / rcnt;
	}
	var _txt = 
		"FPS = " + string(fps) +
		" : Time = " + string_format((current_time - stim) / 1000, 4, 3) +  " / " + string_format(_apos, 4, 2) +  
		" : Mouth = " + _lips.v + 
		" : Length = " + string_format(audio_length, 4, 2) + 
		" : RealFPS = " + string_format(dfps, 5, 2);
	var _txt_h = string_height(_txt);
	var _txt_w = string_width(_txt);

	var _xpos =  (room_height / 2) - (_txt_w / 2);
	var _ypos = room_height - 22;

	draw_text(_xpos, _ypos, _txt);
	_story = global.lipstory.lines;
	_dostory = true;
} else {
	_story = global.blurb;
}

if(array_length(_story) > 0) {
	var _border = 16;
	var _txt_h = 0;
	var _txt_w = 0;
	var _cline = 0;
	var _xpos = room_height + _border;
	var _ypos = 16;
	var _line = 0;
	var _justify = 0;
	var _look_ahead_empty = false;
	
	if(_dostory) {
		for(var _i = lipline; _i < array_length(global.liplines); _i++) {
			if(global.liplines[_i] < _apos) {
				_cline = _i;
			}
		}
	}
	
	_line = _cline - 10;
	if(_line < 0) {
		_line = 0;
	}
	
	draw_set_font(global.fontl);

//	draw_text(0, 0, "LipLine : " + string(lipline) +  " Line : " + string(_line) + " Cline : " + string(_cline));

	while((_ypos < room_height) && (_line < array_length(_story)) ) {
		_txt = _story[_line];
		_look_ahead_empty = false;
		if(_line < array_length(_story) - 1) {
			if(string_length(_story[_line + 1]) == 0) {
				_look_ahead_empty = true;
			}
		} else {
			_look_ahead_empty = true;
		}
		if(string_length(_txt) == 0) {
			_txt = " ";
		}
		_txt_h = string_height(_txt);
		_txt_w = string_width(_txt);
		_justify = room_width - _xpos - _txt_w;

		if(_dostory && (_cline == _line)) {
			draw_set_colour(c_yellow);
		} else {
			draw_set_colour(c_white);
		}
		
		if(_line == 0) {
			draw_centered_text(_xpos, _ypos, _txt, room_width - _xpos - _txt_w);
		}
		else if(_look_ahead_empty) {
			draw_text(_xpos, _ypos, _txt);
		} else {
			draw_justified_text(_xpos, _ypos, _txt, _justify);
		}
		_line++;
		_ypos += _txt_h;
	}
}
