
global.mouth_names = ["A", "B", "C", "D", "E", "F", "G", "H", "X"];

function fetch_image(sfile) {
	var _res = undefined;

	if(file_exists(sfile)) {
		try {
			_res = sprite_add(sfile, 1, false, false, 0, 0);
		} catch(_ignored) { 
			_res = undefined;
		} 
	}

	return _res;
}

function save_json(afile, data) {
	var _res = undefined;

	try {
		var _json = json_stringify(data);

		var _file = file_text_open_write(afile);
		try {
			file_text_write_string(_file, _json);
		} catch(_exception) { 
			show_debug_message("Save - Error : in " + afile + " save " + _exception.message);
			_res = undefined;
			game_end();
		} finally {
			file_text_close(_file);
		}
	} catch(_exception) { 
			show_debug_message("Save - Caught JSON Error : " + _exception.message);
	}
	
	return _res;
}

function string_from_file(filename) {
    var _remove_bom = ((argument_count > 1) && (argument[1] != undefined))? argument[1] : true;
    
    var _buffer = buffer_load(filename);
    
    if (_remove_bom && (buffer_get_size(_buffer) >= 4) && (buffer_peek(_buffer, 0, buffer_u32) & 0xFFFFFF == 0xBFBBEF)) {
        buffer_seek(_buffer, buffer_seek_start, 3);
    }
    
    var _string = buffer_read(_buffer, buffer_string);
    buffer_delete(_buffer);
    return _string;
}

function load_json(afile) {
	var _res = undefined;
	
	if(file_exists(afile)) {
		try {
			var _data = string_from_file(afile);
			_res = json_parse(_data);
		} catch(_exception) { 
			show_debug_message("Error : in " + afile + " load " + _exception.message);
			_res = undefined;
		}
	} else {
		show_debug_message("Can't find : " + afile);
	}
	
	return _res;
}


function sprite_from_imagelist(imagelist) {
	var _required_width = -1;
	var _required_height = -1;
	var _actual_width = -1;
	var _actual_height = -1;
	var _sprite = noone;
	var _surf = undefined;
	var _image = undefined;
	
	if(!is_undefined(imagelist)) {
	
		for(var _i = 0; _i < array_length(imagelist); _i++) {
			if(_i==0) { // First sprite frame
				_image = fetch_image(imagelist[_i]);
				if(is_undefined(_image)) {
					show_debug_message("Can't load " + imagelist[_i]);
					break;
				}
				_required_width = sprite_get_width(_image);
				_required_height = sprite_get_height(_image);

				show_debug_message("Image = " + string(_required_width) + " x " + string(_required_height));
				show_debug_message("Adding " + imagelist[_i]);
				_surf = surface_create(_required_width, _required_height);
				surface_set_target(_surf);
				draw_clear_alpha(c_black, 0);
				draw_sprite(_image, 0, 0, 0);
				surface_reset_target();
				sprite_delete(_image);
			
				_sprite = sprite_create_from_surface(_surf, 0, 0, _required_width, _required_height, false, false, 0, 0);

			} else {
				_image = fetch_image(imagelist[_i]);
				if(is_undefined(_image)) {
					sprite_delete(_sprite);
					_sprite = noone;
					show_debug_message("Can't load " + imagelist[_i]);
					break;
				}
				_actual_width = sprite_get_width(_image);
				_actual_height = sprite_get_height(_image);

				show_debug_message("Adding " + imagelist[_i]);

				if((_actual_width == _required_width) && (_actual_height == _required_height)) {

					surface_set_target(_surf);
					draw_clear_alpha(c_black, 0);
					draw_sprite(_image, 0, 0, 0);
					surface_reset_target();
					sprite_delete(_image);
			
					sprite_add_from_surface(_sprite, _surf, 0, 0, _required_width, _required_height, false, false);
				} else {
					sprite_delete(_sprite);
					sprite_delete(_image);
					_sprite = noone;
					show_debug_message("Sprite frame " + string(_i) + " has different size");
					break;				
				}
			}
		}
		if(sprite_exists(_sprite)) {	
			sprite_set_speed(_sprite, 0, spritespeed_framespersecond);	
		}
		surface_free(_surf);
	
		return _sprite;
	} else {
		return undefined;
	}
}

function sprite_from_path(path, ext = "png") {
	var _idx = 0;
	var _list = [];
	
	for(var _i = 0; _i<array_length(global.mouth_names); _i++) {
		if(file_exists(path + "lips." + global.mouth_names[_i] + "." + ext)) {
			_list[_idx] = path + "lips." + global.mouth_names[_i] + "." + ext;
			_idx++;
		}
	}
	
	if(_idx == array_length(global.mouth_names)) {
		return sprite_from_imagelist(_list);
	} else {
		return noone;
	}
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

function speak() {
	obj_control.time_index = 0;
	global.snd = audio_create_stream(global.lipaudio);
	obj_control.snd = audio_play_sound(global.snd, 100, false);
	obj_control.lip_frames = array_length(global.liptimes.mouthCues);
	obj_control.audio_length = audio_sound_length(global.snd);
}

game_set_speed(30, gamespeed_fps);
global.is_desktop = false;

global.liptimes = load_json("story/an_01_03.min.json");
global.lipstory = load_json("story/an_01_03.txt.json");
global.liplines = load_json("story/an_01_03.lines.json");
global.lipaudio = "story/an_01_03.ogg";

// Uncomment one of the next three lines to change the look of the sprite
// global.lipsprite = sprite_from_path("sq1024/gothic/", "png");
// global.lipsprite = sprite_from_path("sq1024/explosion/", "png");
global.lipsprite = sprite_from_path("sq1024/sketch/", "jpg");

global.frame = sprite_add("frame-1024.png", 1, false, false, 0, 0);
var _frame_sprite = sprite_nineslice_create();
_frame_sprite.enabled = true;
_frame_sprite.left = 28;
_frame_sprite.right = 28;
_frame_sprite.top = 28;
_frame_sprite.bottom = 28;

sprite_set_nineslice(global.frame, _frame_sprite);

global.fonts = font_add("SourceCodePro-Regular.ttf", 12, true, true, 32, 255);
global.fontl = font_add("Montserrat-Medium.ttf", 18, true, true, 32, 255);
global.reclines = [0];

global.blurb = ["LipSprite",
				"",
				"This is an experimental Lip Synch test using Rhubarb Lip Sync",
                "to produce the animation, FFMpeg to convert video to images,",
                "Deep Art Effects to stylize the images from the video and",
                "GameMaker Studio 2 to play an audio track while animating the",
                "image frames in time with the recording.",
                "",
                "While this technique is far from perfect in this example it",
                "does illustrate the basis of providing a method to animate",
                "character portraits in GameMaker Studio 2 using only nine images.",
                "",
                "Using smaller, better, source images than those presented here",
                "should create a more convincing effect. It would also help if I",
                "had put my glasses on straight :)",
                "",
                "The audio used in this example is 'The Merchant And The Genie', one",
                "of the stories from 'The Arabian Nights Entertainments' obtained",
                "from LibriVox (so the voice you hear isn't me).",
                "",
                "The process of creating the images and synching them to the sound",
                "is relatively easy but time-consuming so if I can get better results",
                "I'll write a little GUI utility to automate the boring work for you.",
                "",
                "If anyone is crazy enough to find this intersting the source for",
                "the app that produced this video is on GitHub (link below)"
               ];

switch (os_type) {
	case os_operagx:
	case os_windows: 
	case os_uwp:
	case os_linux:
	case os_macosx:
		global.is_desktop = true;
		break;
	case os_tvos: 
	case os_ios: 
	case os_android: 
		global.is_desktop = false; // OK, this is redundant but I'm writing it anyway
		break;
}
