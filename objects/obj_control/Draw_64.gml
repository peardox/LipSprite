/// @description Insert description here+
// You can write your code in this editor

function lipcode_to_index(code) {
	var _rval = 8;
	switch(code) {
		case "A":
			_rval = 0;
			break;
		case "B":
			_rval = 1;
			break;
		case "C":
			_rval = 2;
			break;
		case "D":
			_rval = 3;
			break;
		case "E":
			_rval = 4;
			break;
		case "F":
			_rval = 5;
			break;
		case "G":
			_rval = 6;
			break;
		case "H":
			_rval = 7;
			break;
	}
	
	return _rval;
}

var _frame_index = 8;
var _frame_time = 8;
var _lips = undefined;
var _apos = 0;
var _story = "";

draw_set_font(global.fonts);

if(keyboard_check_pressed(vk_escape)) {
	show_debug_message("global.reclines : " + string(array_length(global.reclines)) + " : " + json_stringify(global.reclines));
	save_json("lines.json", global.reclines);
	game_end();
}


if(keyboard_check_pressed(vk_numpad0)) {
	var _ln = array_length(global.reclines);
	global.reclines[_ln] = (current_time - stim) / 1000;
}

if(keyboard_check_pressed(vk_space)) {
	speaking = !speaking;
	if(speaking) {
		speak();
		dtim = current_time;
		stim = current_time;
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
				show_debug_message(string(_apos) + " - " + string(_lips.s) + " - " + string(_lips.v));
			}
		} else {
			// Dunno what's needed here
			// We're at the end, should be about to stop
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
	var _ypos = room_height - 22; // - _txt_h;

	draw_text(_xpos, _ypos, _txt);
	_story = global.lipstory.lines;
} else {
	_story = global.blurb;
}

if(!variable_global_exists("one_off")) {
	global.one_off = true;
} else {
	global.one_off = false;
}

function draw_centered_text(xpos, ypos, txt, justify) {
	draw_text(floor(xpos + (justify / 2)), ypos, txt);
}

function draw_justified_text(xpos, ypos, txt, justify) {
	var _c = "";
	var _len = string_length(txt);
	var _spaces = string_count(" ", txt);
	
	if(_len < 2) {
		draw_text(xpos, ypos, txt);
	} else {
		for(var _i = 1; _i <= _len; _i++) {
			_c = string_char_at(txt, _i);
			draw_text(floor(xpos), ypos, _c);
			if(_c == " ") {
				xpos += string_width(_c) + (justify / _spaces);
			} else {
				xpos += string_width(_c);
			}
		}
	}
}

if(array_length(_story) > 0) {
	var _border = 16;
	var _txt_h = 0;
	var _txt_w = 0;

	var _xpos = room_height + _border;
	var _ypos = 16;
	var _line = 0;
	var _justify = 0;
	var _look_ahead_empty = false;
	
	draw_set_font(global.fontl);
	
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
		
		if(global.one_off) {
			show_debug_message("Room : " + string(room_width) + " x " + string(room_height) + 
				" Line : " + string(_line) + 
				" Width : " + string(_txt_w) + 
				" LookAhead : " + string(_look_ahead_empty) + 
				" Justify : " + string(_justify));
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
