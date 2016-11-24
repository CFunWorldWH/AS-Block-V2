/*
* AS-Block-v2.0 is Based on Scratch 2.0
* www.cfunworld.com
* QQ群:366029023
*/

/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// Specs.as
// John Maloney, April 2010
//
// This file defines the command blocks and categories.
// To add a new command:
//		a. add a specification for the new command to the commands array
//		b. add a primitive for the new command to the interpreter

package {
	import flash.display.Bitmap;
	import assets.Resources;

public class Specs {

	public static const GET_VAR:String = "readVariable";
	public static const SET_VAR:String = "setVar:to:";
	public static const CHANGE_VAR:String = "changeVar:by:";
	public static const GET_LIST:String = "contentsOfList:";
	public static const CALL:String = "call";
	public static const PROCEDURE_DEF:String = "procDef";
	public static const GET_PARAM:String = "getParam";

	public static const motionCategory:int = 1;
	public static const looksCategory:int = 2;
	public static const eventsCategory:int = 5;
	public static const controlCategory:int = 6;
	public static const operatorsCategory:int = 8;
	public static const dataCategory:int = 9;
	public static const myBlocksCategory:int = 10;
	public static const listCategory:int = 12;
	public static const extensionsCategory:int = 20;

	public static var variableColor:int = 0xEE7D16; // Scratch 1.4: 0xF3761D
	public static var listColor:int = 0xCC5B22; // Scratch 1.4: 0xD94D11
	public static var procedureColor:int = 0x632D99; // 0x531E99;
	public static var parameterColor:int = 0x5947B1;
	public static var extensionsColor:int = 0x4B4A60; // 0x72228C; // 0x672D79;
	public static var cfunblocksColor:int = 0x0e9f97;//CFunMore模块颜色_wh 0x20b2aa
	//public static var cfunblocksColor2:int = 0x008186;

	private static const undefinedColor:int = 0xD42828;

	public static const categories:Array = [
	 // id   category name	color
		[0,  "undefined",	0xD42828],
		[1,  "Motion",		0x4a6cd4],
		[2,  "Looks",		0x8a55d7],
		[3,  "Sound",		0xbb42c3],
		[4,  "Pen",			0x0e9a6c], // Scratch 1.4: 0x009870
		[5,  "Events",		0xc88330],
		[6,  "Control",		0xe1a91a],
		[7,  "Sensing",		0x2ca5e2],
		[8,  "Operators",	0x5cb712],
		[9,  "Data",		variableColor],
		[10, "More Blocks",	procedureColor],
		[11, "Parameter",	parameterColor],
		[12, "List",		listColor],
		[13, "Extension",	extensionsColor],
		[14, "Arduino Blocks",	cfunblocksColor],
		[15, "Arduino Robot",	cfunblocksColor]
		//新加模块ID号必须按顺序增加，原因推测和PaletteSelector.as下select函数的numChildren部分源码有关_wh
	];

	public static function blockColor(categoryID:int):int {
		if (categoryID > 100) categoryID -= 100;
		for each (var entry:Array in categories) {
			if (entry[0] == categoryID) return entry[2];
		}
		return undefinedColor;
	}

	public static function entryForCategory(categoryName:String):Array {
		for each (var entry:Array in categories) {
			if (entry[1] == categoryName) return entry;
		}
		return [1, categoryName, 0xFF0000]; // should not happen
	}

	public static function nameForCategory(categoryID:int):String {
		if (categoryID > 100) categoryID -= 100;
		for each (var entry:Array in categories) {
			if (entry[0] == categoryID) return entry[1];
		}
		return "Unknown";
	}

	public static function IconNamed(name:String):* {
		// Block icons are 2x resolution to look better when scaled.
		var icon:Bitmap;
		if (name == "greenFlag") icon = Resources.createBmp('flagIcon');
		if (name == "stop") icon = Resources.createBmp('stopIcon');
		if (name == "turnLeft") icon = Resources.createBmp('turnLeftIcon');
		if (name == "turnRight") icon = Resources.createBmp('turnRightIcon');
		if (icon != null) icon.scaleX = icon.scaleY = 0.5;
		return icon;
	}

	public static var commands:Array = [
		// block specification					type, cat, opcode			default args (optional)
		// motion
		["move %n steps",						" ", 1, "forward:",					10],
		["turn @turnRight %n degrees",			" ", 1, "turnRight:",				15],
		["turn @turnLeft %n degrees",			" ", 1, "turnLeft:",				15],
		["--"],
		["point in direction %d.direction",		" ", 1, "heading:",					90],
		["point towards %m.spriteOrMouse",		" ", 1, "pointTowards:",			""],
		["--"],
		["go to x:%n y:%n",						" ", 1, "gotoX:y:"],
		["go to %m.spriteOrMouse",				" ", 1, "gotoSpriteOrMouse:",		"mouse-pointer"],
		["glide %n secs to x:%n y:%n",			" ", 1, "glideSecs:toX:y:elapsed:from:"],
		["--"],
		["change x by %n",						" ", 1, "changeXposBy:",			10],
		["set x to %n",							" ", 1, "xpos:",					0],
		["change y by %n",						" ", 1, "changeYposBy:",			10],
		["set y to %n",							" ", 1, "ypos:",					0],
		["--"],
		["if on edge, bounce",					" ", 1, "bounceOffEdge"],
		["-"],
		["set rotation style %m.rotationStyle",	" ", 1, "setRotationStyle", 		"left-right"],
		["--"],
		["x position",							"r", 1, "xpos"],
		["y position",							"r", 1, "ypos"],
		["direction",							"r", 1, "heading"],

		// looks
		["say %s for %n secs",					" ", 2, "say:duration:elapsed:from:",	"Hello!", 2],
		["say %s",								" ", 2, "say:",							"Hello!"],
		["think %s for %n secs",				" ", 2, "think:duration:elapsed:from:", "Hmm...", 2],
		["think %s",							" ", 2, "think:",						"Hmm..."],
		["-"],
		["show",								" ", 2, "show"],
		["hide",								" ", 2, "hide"],
		["-"],
		["switch costume to %m.costume",		" ", 2, "lookLike:",				"costume1"],
		["next costume",						" ", 2, "nextCostume"],
		["switch backdrop to %m.backdrop",		" ", 2, "startScene", 				"backdrop1"],
		["-"],
		["change %m.effect effect by %n",		" ", 2, "changeGraphicEffect:by:",	"color", 25],
		["set %m.effect effect to %n",			" ", 2, "setGraphicEffect:to:",		"color", 0],
		["clear graphic effects",				" ", 2, "filterReset"],
		["-"],
		["change size by %n",					" ", 2, "changeSizeBy:",	 		10],
		["set size to %n%",						" ", 2, "setSizeTo:", 				100],
		["-"],
		["go to front",							" ", 2, "comeToFront"],
		["go back %n layers",					" ", 2, "goBackByLayers:", 			1],
		["-"],
		["costume #",							"r", 2, "costumeIndex"],
		["backdrop name",						"r", 2, "sceneName"],
		["size",								"r", 2, "scale"],

		// stage looks
		["switch backdrop to %m.backdrop",			" ", 102, "startScene", 			"backdrop1"],
		["switch backdrop to %m.backdrop and wait", " ", 102, "startSceneAndWait",		"backdrop1"],
		["next backdrop",							" ", 102, "nextScene"],
		["-"],
		["change %m.effect effect by %n",		" ", 102, "changeGraphicEffect:by:",	"color", 25],
		["set %m.effect effect to %n",			" ", 102, "setGraphicEffect:to:",		"color", 0],
		["clear graphic effects",				" ", 102, "filterReset"],
		["-"],
		["backdrop name",						"r", 102, "sceneName"],
		["backdrop #",							"r", 102, "backgroundIndex"],

		// sound
		["play sound %m.sound",					" ", 3, "playSound:",						"pop"],
		["play sound %m.sound until done",		" ", 3, "doPlaySoundAndWait",				"pop"],
		["stop all sounds",						" ", 3, "stopAllSounds"],
		["-"],
		["play drum %d.drum for %n beats",		" ", 3, "playDrum",							1, 0.25],
		["rest for %n beats",					" ", 3, "rest:elapsed:from:",				0.25],
		["-"],
		["play note %d.note for %n beats",		" ", 3, "noteOn:duration:elapsed:from:",	60, 0.5],
		["set instrument to %d.instrument",		" ", 3, "instrument:",						1],

		["-"],
		["change volume by %n",					" ", 3, "changeVolumeBy:",					-10],
		["set volume to %n%",					" ", 3, "setVolumeTo:", 					100],
		["volume",								"r", 3, "volume"],
		["-"],
		["change tempo by %n",					" ", 3, "changeTempoBy:",					20],
		["set tempo to %n bpm",					" ", 3, "setTempoTo:",						60],
		["tempo",								"r", 3,  "tempo"],

		// pen
		["clear",								" ", 4, "clearPenTrails"],
		["-"],
		["stamp",								" ", 4, "stampCostume"],
		["-"],
		["pen down",							" ", 4, "putPenDown"],
		["pen up",								" ", 4, "putPenUp"],
		["-"],
		["set pen color to %c",					" ", 4, "penColor:"],
		["change pen color by %n",				" ", 4, "changePenHueBy:"],
		["set pen color to %n",					" ", 4, "setPenHueTo:", 		0],
		["-"],
		["change pen shade by %n",				" ", 4, "changePenShadeBy:"],
		["set pen shade to %n",					" ", 4, "setPenShadeTo:",		50],
		["-"],
		["change pen size by %n",				" ", 4, "changePenSizeBy:",		1],
		["set pen size to %n",					" ", 4, "penSize:", 			1],
		["-"],

		// stage pen
		["clear",								" ", 104, "clearPenTrails"],

		// triggers
		["when @greenFlag clicked",				"h", 5, "whenGreenFlag"],
		["when %m.key key pressed",				"h", 5, "whenKeyPressed", 		"space"],
		["when this sprite clicked",			"h", 5, "whenClicked"],
		["when backdrop switches to %m.backdrop", "h", 5, "whenSceneStarts", 	"backdrop1"],
		["--"],
		["when %m.triggerSensor > %n",			"h", 5, "whenSensorGreaterThan", "loudness", 10],
		["--"],
		["when I receive %m.broadcast",			"h", 5, "whenIReceive",			""],
		["broadcast %m.broadcast",				" ", 5, "broadcast:",			""],
		["broadcast %m.broadcast and wait",		" ", 5, "doBroadcastAndWait",	""],

		// control - sprite
		["wait %n secs",						" ", 6, "wait:elapsed:from:",	1],
		["-"],
		["repeat %n",							"c", 6, "doRepeat", 10],
		["forever",								"cf",6, "doForever"],
		["-"],
		["if %b then",							"c", 6, "doIf"],
		["if %b then",							"e", 6, "doIfElse"],
		["wait until %b",						" ", 6, "doWaitUntil"],
		["repeat until %b",						"c", 6, "doUntil"],
		["-"],
		["stop %m.stop",						"f", 6, "stopScripts", "all"],
		["-"],
		["when I start as a clone",				"h", 6, "whenCloned"],
		["create clone of %m.spriteOnly",		" ", 6, "createCloneOf"],
		["delete this clone",					"f", 6, "deleteClone"],
		["-"],

		// control - stage
		["wait %n secs",						" ", 106, "wait:elapsed:from:",	1],
		["-"],
		["repeat %n",							"c", 106, "doRepeat", 10],
		["forever",								"cf",106, "doForever"],
		["-"],
		["if %b then",							"c", 106, "doIf"],
		["if %b then",							"e", 106, "doIfElse"],
		["wait until %b",						" ", 106, "doWaitUntil"],
		["repeat until %b",						"c", 106, "doUntil"],
		["-"],
		["stop %m.stop",						"f", 106, "stopScripts", "all"],
		["-"],
		["create clone of %m.spriteOnly",		" ", 106, "createCloneOf"],

		// sensing
		["touching %m.touching?",				"b", 7, "touching:",			""],
		["touching color %c?",					"b", 7, "touchingColor:"],
		["color %c is touching %c?",			"b", 7, "color:sees:"],
		["distance to %m.spriteOrMouse",		"r", 7, "distanceTo:",			""],
		["-"],
		["ask %s and wait",						" ", 7, "doAsk", 				"What's your name?"],
		["answer",								"r", 7, "answer"],
		["-"],
		["key %m.key pressed?",					"b", 7, "keyPressed:",			"space"],
		["mouse down?",							"b", 7, "mousePressed"],
		["mouse x",								"r", 7, "mouseX"],
		["mouse y",								"r", 7, "mouseY"],
		["-"],
		["loudness",							"r", 7, "soundLevel"],
		["-"],
		["video %m.videoMotionType on %m.stageOrThis", "r", 7, "senseVideoMotion", "motion"],
		["turn video %m.videoState",			" ", 7, "setVideoState",			"on"],
		["set video transparency to %n%",		" ", 7, "setVideoTransparency",		50],
		["-"],
		["timer",								"r", 7, "timer"],
		["reset timer",							" ", 7, "timerReset"],
		["-"],
		["%m.attribute of %m.spriteOrStage",	"r", 7, "getAttribute:of:"],
		["-"],
		["current %m.timeAndDate", 				"r", 7, "timeAndDate",			"minute"],
		["days since 2000", 					"r", 7, "timestamp"],
		["username",							"r", 7, "getUserName"],

		// stage sensing
		["ask %s and wait",						" ", 107, "doAsk", 				"What's your name?"],
		["answer",								"r", 107, "answer"],
		["-"],
		["key %m.key pressed?",					"b", 107, "keyPressed:",		"space"],
		["mouse down?",							"b", 107, "mousePressed"],
		["mouse x",								"r", 107, "mouseX"],
		["mouse y",								"r", 107, "mouseY"],
		["-"],
		["loudness",							"r", 107, "soundLevel"],
		["-"],
		["video %m.videoMotionType on %m.stageOrThis", "r", 107, "senseVideoMotion", "motion", "Stage"],
		["turn video %m.videoState",			" ", 107, "setVideoState",			"on"],
		["set video transparency to %n%",		" ", 107, "setVideoTransparency",	50],
		["-"],
		["timer",								"r", 107, "timer"],
		["reset timer",							" ", 107, "timerReset"],
		["-"],
		["%m.attribute of %m.spriteOrStage",	"r", 107, "getAttribute:of:"],
		["-"],
		["current %m.timeAndDate", 				"r", 107, "timeAndDate",		"minute"],
		["days since 2000", 					"r", 107, "timestamp"],
		["username",							"r", 107, "getUserName"],

		// operators
		["%n + %n",								"r", 8, "+",					"", ""],
		["%n - %n",								"r", 8, "-",					"", ""],
		["%n * %n",								"r", 8, "*",					"", ""],
		["%n / %n",								"r", 8, "/",					"", ""],
		["-"],
		["pick random %n to %n",		"r", 8, "randomFrom:to:",		1, 10],
		["-"],
		["%s < %s",								"b", 8, "<",					"", ""],
		["%s = %s",								"b", 8, "=",					"", ""],
		["%s > %s",								"b", 8, ">",					"", ""],
		["-"],
		["%b and %b",							"b", 8, "&"],
		["%b or %b",							"b", 8, "|"],
		["not %b",								"b", 8, "not"],
		["-"],
		["join %s %s",							"r", 8, "concatenate:with:",	"hello ", "world"],
		["letter %n of %s",						"r", 8, "letter:of:",			1, "world"],
		["length of %s",						"r", 8, "stringLength:",		"world"],
		["-"],
		["%n mod %n",							"r", 8, "%",					"", ""],
		["round %n",							"r", 8, "rounded", 				""],
		["-"],
		["%m.mathOp of %n",						"r", 8, "computeFunction:of:",	"sqrt", 9],

		// variables
		["set %m.var to %s",								" ", 9, SET_VAR],
		["change %m.var by %n",								" ", 9, CHANGE_VAR],
		["show variable %m.var",							" ", 9, "showVariable:"],
		["hide variable %m.var",							" ", 9, "hideVariable:"],

		// lists
		["add %s to %m.list",								" ", 12, "append:toList:"],
		["-"],
		["delete %d.listDeleteItem of %m.list",				" ", 12, "deleteLine:ofList:"],
		["insert %s at %d.listItem of %m.list",				" ", 12, "insert:at:ofList:"],
		["replace item %d.listItem of %m.list with %s",		" ", 12, "setLine:ofList:to:"],
		["-"],
		["item %d.listItem of %m.list",						"r", 12, "getLine:ofList:"],
		["length of %m.list",								"r", 12, "lineCountOfList:"],
		["%m.list contains %s",								"b", 12, "list:contains:"],
		["-"],
		["show list %m.list",								" ", 12, "showList:"],
		["hide list %m.list",								" ", 12, "hideList:"],

		// obsolete blocks from Scratch 1.4 that may be used in older projects
		["play drum %n for %n beats",			" ", 98, "drum:duration:elapsed:from:", 1, 0.25], // Scratch 1.4 MIDI drum
		["set instrument to %n",				" ", 98, "midiInstrument:", 1],
		["loud?",								"b", 98, "isLoud"],

		// obsolete blocks from Scratch 1.4 that are converted to new forms (so should never appear):
		["abs %n",								"r", 98, "abs"],
		["sqrt %n",								"r", 98, "sqrt"],
		["stop script",							"f", 98, "doReturn"],
		["stop all",							"f", 98, "stopAll"],
		["switch to background %m.costume",		" ", 98, "showBackground:", "backdrop1"],
		["next background",						" ", 98, "nextBackground"],
		["forever if %b",						"cf",98, "doForeverIf"],

		// testing and experimental control prims
		["noop",								"r", 99, "COUNT"],
		["counter",								"r", 99, "COUNT"],
		["clear counter",						" ", 99, "CLR_COUNT"],
		["incr counter",						" ", 99, "INCR_COUNT"],
		["for each %m.varName in %s",			"c", 99, "doForLoop", "v", 10],
		["while %b",							"c", 99, "doWhile"],
		["all at once",							"c", 99, "warpSpeed"],

		// stage motion (scrolling)
		["scroll right %n",						" ", 99, "scrollRight",		10],
		["scroll up %n",						" ", 99, "scrollUp",		10],
		["align scene %m.scrollAlign",			" ", 99, "scrollAlign",		'bottom-left'],
		["x scroll",							"r", 99, "xScroll"],
		["y scroll",							"r", 99, "yScroll"],

		// other obsolete blocks from alpha/beta
		["hide all sprites",					" ", 99, "hideAll"],
		["user id",								"r", 99, "getUserId"],
		
		
		//二级积木模块添加：模块_wh
		//["test %s",							" ", 13, "test:",				"?"],//测试_wh
		
		["Arduino Program",	"h", 14, "whenArduino"],//Arduino程序生成_wh
		
		["————basic IO————",	"+",	14],//细分类别说明_wh
		//基本IO操作模块_wh
		["read Dx pin %m.dpin",					"b", 14, "readdigital:",		4],//数字口输入_wh
		["read Ax pin A%m.apin",					"r", 14, "readanalog:",		0],//模拟口输入_wh
		["set Dx pin %m.dpin as %m.highlow",		" ", 14, "setdigital:",		2,	'high'],//数字口输出_wh
		["set pwm pin %m.pwmpin as %n",				" ", 14, "setpwm:",			3,	120],//pwm口输出_wh
		["-"],
		
		["————read sensor————",	"+",	14],//细分类别说明_wh
		//读数字传感器模块_wh
		["read %m.dsensor sensor %m.dpin",		"b", 14, "readdigitals:",		'key',	4],//按键传感器_wh
//		["read ball sensor %n",				"b", 13, "readdigital:",		4],//滚珠传感器_wh
//		["read reed sensor %n",				"b", 13, "readdigital:",		4],//干簧管传感器_wh
//		["read holzor sensor %n",			"b", 13, "readdigital:",		4],//霍尔传感器_wh
//		["read flame sensor %n",				"b", 13, "readdigital:",		4],//火焰传感器_wh
//		["read body sensor %n",				"b", 13, "readdigital:",		4],//人体红外传感器_wh
		
		//读模拟传感器模块_wh
		["read %m.asensor sensor A%m.apin",	"r", 14, "readanalogs:",		'slider',	0],//旋转电位器_wh
//		["read slid potentiometer A%n",		"r", 13, "readanalog:",		0],//滑动电位器_wh
//		["read light sensor A%n",			"r", 13, "readanalog:",		0],//光敏传感器_wh
//		["read heat sensor A%n",				"r", 13, "readanalog:",		0],//热敏传感器_wh
//		["read sound sensor A%n",			"r", 13, "readanalog:",		0],//声音传感器_wh
//		["read water level sensor A%n",		"r", 13, "readanalog:",		0],//水位传感器_wh
		
		//读取其他模块_wh
		["read joystick %m.xy axis A%m.apin",			"r", 14, "readanalogsj:",		'X',	0],//摇杆X轴_wh
//		["read joystick Y axis A%n",			"r", 13, "readanalog:",		1],//摇杆Y轴_wh
		//["read joystick key %m.dpin",				"b", 13, "readdigitalj:",		4],//摇杆按键_wh
		["read capacitance %m.dpin",				"r", 14, "readcap:",		4],//读取电容值_wh
		["read frared receiver %m.dpin",			"r", 14,	"readfraredR:",	11],//红外遥控接收_wh
		["read LM35 temperature sensor A%m.apin",	"r", 14, "readAfloat:",		0],//LM35温度值_wh
		["read ultrasonic sensor P2,3",			"r", 14, "readPfloat:"],//超声波传感器_wh
		
		["-"],//间隔_wh
		["————set module————",	"+",	14],//细分类别说明_wh
		//写数字模块_wh
		["set %m.dcontrol %m.dpin as %m.onoff",		" ", 14, "setdigitals:",	'LED',	2,	'on'],//LED_wh
//		["set active buzzer %n as %m.highlow",	" ", 13, "setdigital:",	2,	1],//有缘蜂鸣器_wh
//		["set relay %n as %m.highlow",			" ", 13, "setdigital:",	2,	1],//继电器_wh
//		["set laser head %n as %m.highlow",		" ", 13, "setdigital:",	2,	1],//激光头_wh
		
		//写PWM模块_wh
		["set DC motor %m.pwmpin speed as %n",			" ", 14, "setMpwm:",		3,	120],//直流电机转速_wh
		
		//其他写模块_wh
		["set servo %m.dpin angle as %n",	" ", 14, "setsg:",		3,	90],//舵机角度_wh
		["set motor %m.dppin direct %m.dir speed as %n",	" ", 14, "setdm:",		"M1",	"forward",	120],//方向电机角度_wh
		["set digital tube P%m.numpin num as %n",		" ", 14, "setnum:",	9,	123.4],//数码管_wh
		["set pin %m.dpin tone: %m.tone meter: %m.meter",	" ", 14, "setmusic:",	3,	'C2',	'1/2'],//无源蜂鸣器_wh
		["set colors LED as R %n G %n B %n",	" ", 14, "setrgb:",	60,60,60],//三色LED_wh
		
		//二级积木模块添加：机器人_wh
		["————CK Board————",	"+",	15],//细分类别说明_wh
		["sound",	"r", 15, "readcksound"],//测控板模拟量_wh
		["slide",	"r", 15, "readckslide"],//测控板模拟量_wh
		["light",	"r", 15, "readcklight"],//测控板模拟量_wh
		["red key",	"b", 15, "readckkey1"],//测控板数字量_wh
		["green key",	"b", 15, "readckkey2"],//测控板数字量_wh
		["joystick X",	"r", 15, "readckjoyx"],//测控板模拟量_wh
		["joystick Y",	"r", 15, "readckjoyy"],//测控板模拟量_wh
		["set LED as %m.onoff",			" ", 15, "setckled:",	'on'],//led灯_wh
		
		["-"],//间隔_wh
		["————Robot Car————",	"+",	15],//细分类别说明_wh
		["read track sensor",				"r", 	15, "readtrack:"],//循迹传感器_wh
		["read avoid obstacle sensor",	"r", 	15, "readavoid:"],//避障传感器_wh
		//["read ultrasonic sensor",		"r", 	14, "readultrs:"],//超声波传感器_wh
		["read power sensor",				"r", 	15, "readpower:"],//电量传感器_wh
		["-"],//间隔_wh
		["set gray threshold as %n",		" ", 15, "setgray:",	600],//灰度阀值_wh
		["set forward speed as %n",		" ", 15, "setforward:",	120],//向前_wh
		["set back speed as %n",			" ", 15, "setback:",		120],//后退_wh
		["set left speed as %n",			" ", 15, "setleft:",		120],//左转_wh
		["set right speed as %n",		" ", 15, "setright:",		120],//右转_wh
		//["set buzzer(LED) as %m.onoff",		" ", 14, "setbuzzer:",	'on'],//蜂鸣器_wh
		["set arm %m.arm angle as %n",	" ", 15, "setarm:",	'updown',	20],//舵机角度_wh
	];

	public static var extensionSpecs:Array = ["when %m.booleanSensor", "when %m.sensor %m.lessMore %n", "sensor %m.booleanSensor?", "%m.sensor sensor value", "turn %m.motor on for %n secs", "turn %m.motor on", "turn %m.motor off", "set %m.motor power to %n", "set %m.motor2 direction to %m.motorDirection", "when distance %m.lessMore %n", "when tilt %m.eNe %n", "distance", "tilt"];

}}
