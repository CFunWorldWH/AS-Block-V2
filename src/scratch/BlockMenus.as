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


package scratch {
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.*;
	import blocks.*;
	import filters.*;
	import sound.*;
	import translation.Translator;
	import ui.ProcedureSpecEditor;
	import uiwidgets.*;
	import util.*;
	import flash.events.MouseEvent;

public class BlockMenus implements DragClient {

	private var app:Scratch;
	private var startX:Number;
	private var startY:Number;
	private var block:Block;
	private var blockArg:BlockArg; // null if menu is invoked on a block

	private static const basicMathOps:Array = ['+', '-', '*', '/'];
	private static const comparisonOps:Array = ['<', '=', '>'];

	private static const spriteAttributes:Array = ['x position', 'y position', 'direction', 'costume #', 'costume name', 'size', 'volume'];
	private static const stageAttributes:Array = ['backdrop #', 'backdrop name', 'volume'];

	public static function BlockMenuHandler(evt:MouseEvent, block:Block, blockArg:BlockArg = null, menuName:String = null):void {
		var menuHandler:BlockMenus = new BlockMenus(block, blockArg);
		var op:String = block.op;
		if (menuName == null) { // menu gesture on a block (vs. an arg)
			if (op == Specs.GET_LIST) menuName = 'list';
			if (op == Specs.GET_VAR) menuName = 'var';
			if ((op == Specs.PROCEDURE_DEF) || (op == Specs.CALL)) menuName = 'procMenu';
			if ((op == 'broadcast:') || (op == 'doBroadcastAndWait') || (op == 'whenIReceive')) menuName = 'broadcastInfoMenu';
			if ((basicMathOps.indexOf(op)) > -1) { menuHandler.changeOpMenu(evt, basicMathOps); return; }
			if ((comparisonOps.indexOf(op)) > -1) { menuHandler.changeOpMenu(evt, comparisonOps); return; }
			if (menuName == null) { menuHandler.genericBlockMenu(evt); return; }
		}
		if (op.indexOf('.') > -1 && menuHandler.extensionMenu(evt, menuName)) return;
		if (menuName == 'attribute') menuHandler.attributeMenu(evt);
		if (menuName == 'backdrop') menuHandler.backdropMenu(evt);
		if (menuName == 'booleanSensor') menuHandler.booleanSensorMenu(evt);
		if (menuName == 'broadcast') menuHandler.broadcastMenu(evt);
		if (menuName == 'broadcastInfoMenu') menuHandler.broadcastInfoMenu(evt);
		if (menuName == 'colorPicker') menuHandler.colorPicker(evt);
		if (menuName == 'costume') menuHandler.costumeMenu(evt);
		if (menuName == 'direction') menuHandler.dirMenu(evt);
		if (menuName == 'drum') menuHandler.drumMenu(evt);
		if (menuName == 'effect') menuHandler.effectMenu(evt);
		if (menuName == 'instrument') menuHandler.instrumentMenu(evt);
		if (menuName == 'key') menuHandler.keyMenu(evt);
		if (menuName == 'list') menuHandler.listMenu(evt);
		if (menuName == 'listDeleteItem') menuHandler.listItem(evt, true);
		if (menuName == 'listItem') menuHandler.listItem(evt, false);
		if (menuName == 'mathOp') menuHandler.mathOpMenu(evt);
		if (menuName == 'motorDirection') menuHandler.motorDirectionMenu(evt);
		if (menuName == 'note') menuHandler.notePicker(evt);
		if (menuName == 'procMenu') menuHandler.procMenu(evt);
		if (menuName == 'rotationStyle') menuHandler.rotationStyleMenu(evt);
		if (menuName == 'scrollAlign') menuHandler.scrollAlignMenu(evt);
		if (menuName == 'sensor') menuHandler.sensorMenu(evt);
		if (menuName == 'sound') menuHandler.soundMenu(evt);
		if (menuName == 'spriteOnly') menuHandler.spriteMenu(evt, false, false, false, true);
		if (menuName == 'spriteOrMouse') menuHandler.spriteMenu(evt, true, false, false, false);
		if (menuName == 'spriteOrStage') menuHandler.spriteMenu(evt, false, false, true, false);
		if (menuName == 'touching') menuHandler.spriteMenu(evt, true, true, false, false);
		if (menuName == 'stageOrThis') menuHandler.stageOrThisSpriteMenu(evt);
		if (menuName == 'stop') menuHandler.stopMenu(evt);
		if (menuName == 'timeAndDate') menuHandler.timeAndDateMenu(evt);
		if (menuName == 'triggerSensor') menuHandler.triggerSensorMenu(evt);
		if (menuName == 'var') menuHandler.varMenu(evt);
		if (menuName == 'videoMotionType') menuHandler.videoMotionTypeMenu(evt);
		if (menuName == 'videoState') menuHandler.videoStateMenu(evt);
		if (menuName == 'highlow') menuHandler.BitIOHL(evt);//增加IO输出高低电平选项菜单_wh_wh
		if (menuName == 'dsensor') menuHandler.BitSensor(evt);//增加读取数字传感器类别选项菜单_wh
		if (menuName == 'asensor') menuHandler.AnaSensor(evt);//增加读取模拟传感器类别选项菜单_wh
		if (menuName == 'xy') menuHandler.Joyxy(evt);//增加读取模拟传感器类别选项菜单_wh
		if (menuName == 'dcontrol') menuHandler.DControl(evt);//增加写数字模块类别选项菜单_wh
		if (menuName == 'onoff') menuHandler.OnOff(evt);//增加IO开关（高低）类别选项菜单_wh
		if (menuName == 'arm') menuHandler.Arm(evt);//增加机械臂类别选项菜单_wh
		if (menuName == 'tone') menuHandler.Tone(evt);//增加音乐音调类别选项菜单_wh
		if (menuName == 'meter') menuHandler.Meter(evt);//增加音乐节拍类别选项菜单_wh
		if (menuName == 'dpin') menuHandler.DPin(evt);//增加数字管脚_wh
		if (menuName == 'apin') menuHandler.APin(evt);//增加模拟管脚_wh
		if (menuName == 'pwmpin') menuHandler.PWMPin(evt);//增加PWM管脚_wh
		if (menuName == 'dppin') menuHandler.DPPin(evt);//增加方向电机管脚_wh
		//if (menuName == 'ulpin') menuHandler.UlPin(evt);//增加超声波管脚_wh
		if (menuName == 'numpin') menuHandler.NumPin(evt);//增加数码管管脚_wh
		if (menuName == 'dir') menuHandler.Dir(evt);//增加数码管管脚_wh

	}

	public static function strings():Array {
		// Exercises all the menus to cause their items to be recorded.
		// Return a list of additional strings (e.g. from the key menu).
		var events:Array = [new MouseEvent('dummy'), new MouseEvent('shift-dummy')];
		events[1].shiftKey = true;
		var handler:BlockMenus = new BlockMenus(new Block('dummy'), null);
		for each (var evt:MouseEvent in events) {
			handler.attributeMenu(evt);
			handler.backdropMenu(evt);
			handler.booleanSensorMenu(evt);
			handler.broadcastMenu(evt);
			handler.broadcastInfoMenu(evt);
			handler.costumeMenu(evt);
			handler.dirMenu(evt);
			handler.drumMenu(evt);
			handler.effectMenu(evt);
			handler.genericBlockMenu(evt);
			handler.instrumentMenu(evt);
			handler.listMenu(evt);
			handler.listItem(evt, true);
			handler.listItem(evt, false);
			handler.mathOpMenu(evt);
			handler.motorDirectionMenu(evt);
			handler.procMenu(evt);
			handler.rotationStyleMenu(evt);
			handler.scrollAlignMenu(evt);
			handler.sensorMenu(evt);
			handler.soundMenu(evt);
			handler.spriteMenu(evt, false, false, false, true);
			handler.spriteMenu(evt, true, false, false, false);
			handler.spriteMenu(evt, false, false, true, false);
			handler.spriteMenu(evt, true, true, false, false);
			handler.stageOrThisSpriteMenu(evt);
			handler.stopMenu(evt);
			handler.timeAndDateMenu(evt);
			handler.triggerSensorMenu(evt);
			handler.varMenu(evt);
			handler.videoMotionTypeMenu(evt);
			handler.videoStateMenu(evt);
		}
		return [
			'up arrow', 'down arrow', 'right arrow', 'left arrow', 'space',
			'other scripts in sprite', 'other scripts in stage',
			'backdrop #', 'backdrop name', 'volume', 'OK', 'Cancel',
			'Edit Block', 'Rename' , 'New name', 'Delete', 'Broadcast', 'New Message', 'Message Name',
			'delete variable', 'rename variable',
			'video motion', 'video direction',
			'Low C', 'Middle C', 'High C',
			//下拉菜单汉化字符串_wh
			'low','high','on','off',
			'key','ball','reed','holzor','flame','body','avoid obstacle',
			'potentiometer','light','heat','sound','waterlevel','X','Y',
			'LED','activebuzzer','relay','laser',
			'up','clamp',
			'half','quarter','eighth','whole','double','stop',
//			//固件下载提示汉化_wh
//			'waiting...','success!','failed!!!',
			
		];
	}

	public function BlockMenus(block:Block, blockArg:BlockArg) {
		app = Scratch.app;
		this.startX = app.mouseX;
		this.startY = app.mouseY;
		this.blockArg = blockArg;
		this.block = block;
	}

	public static function shouldTranslateItemForMenu(item:String, menuName:String):Boolean {
		// Return true if the given item from the given menu parameter slot should be
		// translated. This mechanism prevents translating proper names such as sprite,
		// costume, or variable names.
		function isGeneric(s:String):Boolean {
			return ['duplicate', 'delete', 'add comment'].indexOf(s) > -1;
		}
		switch (menuName) {
		case 'attribute':
			return spriteAttributes.indexOf(item) > -1 || stageAttributes.indexOf(item) > -1;
		case 'backdrop':
			return ['next backdrop', 'previous backdrop'].indexOf(item) > -1;
		case 'broadcast':
			return ['new message...'].indexOf(item) > -1;
		case 'costume':
			return false;
		case 'list':
			if (isGeneric(item)) return true;
			return ['delete list'].indexOf(item) > -1;
		case 'sound':
			return ['record...'].indexOf(item) > -1;
		case 'sprite':
		case 'spriteOnly':
		case 'spriteOrMouse':
		case 'spriteOrStage':
		case 'touching':
			return false; // handled directly by menu code
		case 'var':
			if (isGeneric(item)) return true;
			return ['delete variable', 'rename variable'].indexOf(item) > -1;
		}
		return true;
	}

	private function showMenu(m:Menu):void {
		m.color = block.base.color;
		m.itemHeight = 22;
		if (blockArg) {
			var p:Point = blockArg.localToGlobal(new Point(0, blockArg.height));
			m.showOnStage(app.stage, p.x - 9, p.y);
		} else {
			m.showOnStage(app.stage);
		}
	}

	private function setBlockArg(selection:*):void {
		if (blockArg != null) blockArg.setArgValue(selection);
		Scratch.app.setSaveNeeded();
		/*SCRATCH::allow3d_wh*/ { Scratch.app.runtime.checkForGraphicEffects(); }
	}

	private function attributeMenu(evt:MouseEvent):void {
		var obj:*;
		if (block && block.args[1]) {
			obj = app.stagePane.objNamed(block.args[1].argValue);
		}
		var attributes:Array = obj is ScratchStage ? stageAttributes : spriteAttributes;
		var m:Menu = new Menu(setBlockArg, 'attribute');
		for each (var s:String in attributes) m.addItem(s);
		if (obj is ScratchObj) {
			m.addLine();
			for each (s in obj.varNames().sort()) m.addItem(s);
		}
		showMenu(m);
	}

	private function backdropMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'backdrop');
		for each (var scene:ScratchCostume in app.stageObj().costumes) {
			m.addItem(scene.costumeName);
		}
		if (block && block.op.indexOf('startScene') > -1 || Menu.stringCollectionMode) {
			m.addLine();
			m.addItem('next backdrop');
			m.addItem('previous backdrop');
		}
		showMenu(m);
	}

	private function booleanSensorMenu(evt:MouseEvent):void {
		var sensorNames:Array = [
			'button pressed', 'A connected', 'B connected', 'C connected', 'D connected'];
		var m:Menu = new Menu(setBlockArg, 'booleanSensor');
		for each (var s:String in sensorNames) m.addItem(s);
		showMenu(m);
	}

	private function colorPicker(evt:MouseEvent):void {
		app.gh.setDragClient(this, evt);
	}

	private function costumeMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'costume');
		if (app.viewedObj() == null) return;
		for each (var c:ScratchCostume in app.viewedObj().costumes) {
			m.addItem(c.costumeName);
		}
		showMenu(m);
	}

	private function dirMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'direction');
		m.addItem('(90) ' + Translator.map('right'), 90);
		m.addItem('(-90) ' + Translator.map('left'), -90);
		m.addItem('(0) ' + Translator.map('up'), 0);
		m.addItem('(180) ' + Translator.map('down'), 180);
		showMenu(m);
	}

    //增加IO输出高低电平选项菜单_wh
	private function BitIOHL(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'highlow');
		m.addItem('low', 'low');
		m.addItem('high', 'high');
		showMenu(m);
	}
	
	//增加IO开关（高低）电平选项菜单_wh
	private function OnOff(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'onoff');
		m.addItem('on', 'on');
		m.addItem('off', 'off');
		showMenu(m);
	}
	
	//增加机械臂选项菜单_wh
	private function Arm(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'arm');
		m.addItem('updown', 'updown');
		m.addItem('clamp', 'clamp');
		showMenu(m);
	}
	
	//增加数字管脚选项菜单_wh
	private function DPin(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'dpin');
		m.addItem('2', 2);
		m.addItem('3', 3);
		m.addItem('4', 4);
		m.addItem('5', 5);
		m.addItem('6', 6);
		m.addItem('7', 7);
		m.addItem('8', 8);
		m.addItem('9', 9);
		m.addItem('10', 10);
		m.addItem('11', 11);
		m.addItem('12', 12);
		m.addItem('13', 13);
		showMenu(m);
	}
	
	//增加模拟读管脚选项菜单_wh
	private function APin(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'apin');
		m.addItem('0', 0);
		m.addItem('1', 1);
		m.addItem('2', 2);
		m.addItem('3', 3);
		m.addItem('4', 4);
		m.addItem('5', 5);
		showMenu(m);
	}
	
	//增加模拟写管脚选项菜单_wh
	private function PWMPin(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'pwmpin');
		m.addItem('3', 3);
		m.addItem('5', 5);
		m.addItem('6', 6);
		m.addItem('9', 9);
		m.addItem('10', 10);
		m.addItem('11', 11);
		showMenu(m);
	}
	
	//增加方向电机管脚选项菜单_wh
	private function DPPin(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'dppin');
		m.addItem('M1(5,7)', 'M1');
		m.addItem('M2(6,8)', 'M2');
		m.addItem('M3(9,11)', 'M3');
		m.addItem('M4(10,12)', 'M4');
		showMenu(m);
	}
	
	//增加超声波管脚选项菜单_wh
//	private function UlPin(evt:MouseEvent):void {
//		var m:Menu = new Menu(setBlockArg, 'ulpin');
//		m.addItem('2,3', 2);
//		m.addItem('3,4', 3);
//		m.addItem('4,5', 4);
//		m.addItem('5,6', 5);
//		m.addItem('6,7', 6);
//		m.addItem('7,8', 7);
//		m.addItem('8,9', 8);
//		m.addItem('9,10', 9);
//		m.addItem('10,11', 10);
//		m.addItem('11,12', 11);
//		m.addItem('12,13', 12);
//		showMenu(m);
//	}
	
	//增加数码管管脚选项菜单_wh
	private function NumPin(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'numpin');
		m.addItem('2,3,4', 2);
		m.addItem('3,4,5', 3);
		m.addItem('4,5,6', 4);
		m.addItem('5,6,7', 5);
		m.addItem('6,7,8', 6);
		m.addItem('7,8,9', 7);
		m.addItem('8,9,10', 8);
		m.addItem('9,10,11', 9);
		m.addItem('10,11,12', 10);
		m.addItem('11,12,13', 11);
		showMenu(m);
	}
	
	//增加方向选项菜单_wh
	private function Dir(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'dir');
		m.addItem('forward', 'forward');
		m.addItem('back', 'back');
		showMenu(m);
	}
	
	//增加音乐节拍选项菜单_wh
	private function Tone(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'tone');
		m.addItem('C2', 'C2');
		m.addItem('D2', 'D2');
		m.addItem('E2', 'E2');
		m.addItem('F2', 'F2');
		m.addItem('G2', 'G2');
		m.addItem('A2', 'A2');
		m.addItem('B2', 'B2');
		m.addItem('C3', 'C3');
		m.addItem('D3', 'D3');
		m.addItem('E3', 'E3');
		m.addItem('F3', 'F3');
		m.addItem('G3', 'G3');
		m.addItem('A3', 'A3');
		m.addItem('B3', 'B3');
		m.addItem('C4', 'C4');
		m.addItem('D4', 'D4');
		m.addItem('E4', 'E4');
		m.addItem('F4', 'F4');
		m.addItem('G4', 'G4');
		m.addItem('A4', 'A4');
		m.addItem('B4', 'B4');
		m.addItem('C5', 'C5');
		m.addItem('D5', 'D5');
		m.addItem('E5', 'E5');
		m.addItem('F5', 'F5');
		m.addItem('G5', 'G5');
		m.addItem('A5', 'A5');
		m.addItem('B5', 'B5');
		m.addItem('C6', 'C6');
		m.addItem('D6', 'D6');
		m.addItem('E6', 'E6');
		m.addItem('F6', 'F6');
		m.addItem('G6', 'G6');
		m.addItem('A6', 'A6');
		m.addItem('B6', 'B6');
		m.addItem('C7', 'C7');
		m.addItem('E7', 'D7');
		m.addItem('F7', 'F7');
		m.addItem('G7', 'G7');
		m.addItem('A7', 'A7');
		showMenu(m);
	}
	
	//增加音乐节拍选项菜单_wh
	private function Meter(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'meter');
		m.addItem('1/2', '1/2');
		m.addItem('1/4', '1/4');
		m.addItem('1/8', '1/8');
		m.addItem('whole', 'whole');
		m.addItem('double', 'double');
		m.addItem('stop', 'stop');
		showMenu(m);
	}
	
	//增加读数字传感器选项菜单_wh
	private function BitSensor(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'dsensor');
		m.addItem('key', 'key');
		m.addItem('raindrop', 'raindrop');
		m.addItem('reed', 'reed');
		m.addItem('holzor', 'holzor');
		m.addItem('body', 'body');
		m.addItem('avoid obstacle', 'avoid obstacle');
		m.addItem('tilt switch', 'tilt switch');
		showMenu(m);
	}
	
	//增加读模拟传感器选项菜单_wh
	private function AnaSensor(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'asensor');
		m.addItem('slider', 'slider');
		m.addItem('rotation', 'rotation');
		m.addItem('light', 'light');
		m.addItem('heat', 'heat');
		m.addItem('sound', 'sound');
		m.addItem('waterlevel', 'waterlevel');
		m.addItem('soil moisture', 'soil moisture');
		m.addItem('gray', 'gray');
		m.addItem('flame', 'flame');
		showMenu(m);
	}
	
	//增加读摇杆xy轴选项菜单_wh
	private function Joyxy(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'xy');
		m.addItem('X', 'X');
		m.addItem('Y', 'Y');
		showMenu(m);
	}
	
	//增加写数字模块选项菜单_wh
	private function DControl(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'dcontrol');
		m.addItem('LED', 'LED');
		m.addItem('activebuzzer', 'activebuzzer');
		m.addItem('relay', 'relay');
		m.addItem('laser', 'laser');
		m.addItem('fan', 'fan');
		m.addItem('light belt', 'light belt');
		showMenu(m);
	}
	
//	//增加读取数字传感器类别选项菜单_wh
//	private function BitSersor(evt:MouseEvent):void {
//		var m:Menu = new Menu(setBlockArg, 'bitsersor');
//		m.addItem('key ', 'key ');
//		m.addItem('vibrate ', 'vibrate ');
//		showMenu(m);
//	}

	private function drumMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'drum');
		for (var i:int = 1; i <= SoundBank.drumNames.length; i++) {
			m.addItem('(' + i + ') ' + Translator.map(SoundBank.drumNames[i - 1]), i);
		}
		showMenu(m);
	}

	private function effectMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'effect');
		if (app.viewedObj() == null) return;
		for each (var s:String in FilterPack.filterNames) m.addItem(s);
		showMenu(m);
	}

	private function extensionMenu(evt:MouseEvent, menuName:String):Boolean {
		var items:Array = app.extensionManager.menuItemsFor(block.op, menuName);
		if (!items) return false;
		var m:Menu = new Menu(setBlockArg);
		for each (var s:String in items) m.addItem(s);
		showMenu(m);
		return true;
	}

	private function instrumentMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'instrument');
		for (var i:int = 1; i <= SoundBank.instrumentNames.length; i++) {
			m.addItem('(' + i + ') ' + Translator.map(SoundBank.instrumentNames[i - 1]), i);
		}
		showMenu(m);
	}

	private function keyMenu(evt:MouseEvent):void {
		var ch:int;
		var namedKeys:Array = ['up arrow', 'down arrow', 'right arrow', 'left arrow', 'space'];
		var m:Menu = new Menu(setBlockArg, 'key');
		for each (var s:String in namedKeys) m.addItem(s);
		for (ch = 97; ch < 123; ch++) m.addItem(String.fromCharCode(ch)); // a-z
		for (ch = 48; ch < 58; ch++) m.addItem(String.fromCharCode(ch)); // 0-9
		showMenu(m);
	}

	private function listItem(evt:MouseEvent, forDelete:Boolean):void {
		var m:Menu = new Menu(setBlockArg, 'listItem');
		m.addItem('1');
		m.addItem('last');
		if (forDelete) {
			m.addLine();
			m.addItem('all');
		} else {
			m.addItem('random');
		}
		showMenu(m);
	}

	private function mathOpMenu(evt:MouseEvent):void {
		var ops:Array = ['abs', 'floor', 'ceiling', 'sqrt', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'ln', 'log', 'e ^', '10 ^'];
		var m:Menu = new Menu(setBlockArg, 'mathOp');
		for each (var op:String in ops) m.addItem(op);
		showMenu(m);
	}

	private function motorDirectionMenu(evt:MouseEvent):void {
		var ops:Array = ['this way', 'that way', 'reverse'];
		var m:Menu = new Menu(setBlockArg, 'motorDirection');
		for each (var s:String in ops) m.addItem(s);
		showMenu(m);
	}

	private function notePicker(evt:MouseEvent):void {
		var piano:Piano = new Piano(block.base.color, app.viewedObj().instrument, setBlockArg);
		if (!isNaN(blockArg.argValue)) {
			piano.selectNote(int(blockArg.argValue));
		}
		var p:Point = blockArg.localToGlobal(new Point(blockArg.width, blockArg.height));
		piano.showOnStage(app.stage, int(p.x - piano.width / 2), p.y);
	}

	private function rotationStyleMenu(evt:MouseEvent):void {
		const rotationStyles:Array = ['left-right', "don't rotate", 'all around'];
		var m:Menu = new Menu(setBlockArg, 'rotationStyle');
		for each (var s:String in rotationStyles) m.addItem(s);
		showMenu(m);
	}

	private function scrollAlignMenu(evt:MouseEvent):void {
		const options:Array = [
			'bottom-left', 'bottom-right', 'middle', 'top-left', 'top-right'];
		var m:Menu = new Menu(setBlockArg, 'scrollAlign');
		for each (var s:String in options) m.addItem(s);
		showMenu(m);
	}

	private function sensorMenu(evt:MouseEvent):void {
		var sensorNames:Array = [
			'slider', 'light', 'sound',
			'resistance-A', 'resistance-B', 'resistance-B', 'resistance-C', 'resistance-D'];
		var m:Menu = new Menu(setBlockArg, 'sensor');
		for each (var s:String in sensorNames) m.addItem(s);
		showMenu(m);
	}

	private function soundMenu(evt:MouseEvent):void {
		function setSoundArg(s:*):void {
			if (s is Function) s()
			else setBlockArg(s);
		}
		var m:Menu = new Menu(setSoundArg, 'sound');
		if (app.viewedObj() == null) return;
		for (var i:int = 0; i < app.viewedObj().sounds.length; i++) {
			m.addItem(app.viewedObj().sounds[i].soundName);
		}
		m.addLine();
		m.addItem('record...', recordSound);
		showMenu(m);
	}

	private function recordSound():void {
		app.setTab('sounds');
		app.soundsPart.recordSound();
	}

	private function spriteMenu(evt:MouseEvent, includeMouse:Boolean, includeEdge:Boolean, includeStage:Boolean, includeSelf:Boolean):void {
		function setSpriteArg(s:*):void {
			if (blockArg == null) return;
			if (s == 'edge') blockArg.setArgValue('_edge_', Translator.map('edge'));
			else if (s == 'mouse-pointer') blockArg.setArgValue('_mouse_', Translator.map('mouse-pointer'));
			else if (s == 'myself') blockArg.setArgValue('_myself_', Translator.map('myself'));
			else if (s == 'Stage') blockArg.setArgValue('_stage_', Translator.map('Stage'));
			else blockArg.setArgValue(s);
			if (block.op == 'getAttribute:of:') {
				var obj:ScratchObj = app.stagePane.objNamed(s);
				var attr:String = block.args[0].argValue;
				var validAttrs:Array = obj && obj.isStage ? stageAttributes : spriteAttributes;
				if (validAttrs.indexOf(attr) == -1 && !obj.ownsVar(attr)) {
					block.args[0].setArgValue(validAttrs[0]);
				}
			}
			Scratch.app.setSaveNeeded();
		}
		var spriteNames:Array = [];
		var m:Menu = new Menu(setSpriteArg, 'sprite');
		if (includeMouse) m.addItem(Translator.map('mouse-pointer'), 'mouse-pointer');
		if (includeEdge) m.addItem(Translator.map('edge'), 'edge');
		m.addLine();
		if (includeStage) {
			m.addItem(app.stagePane.objName, 'Stage');
			m.addLine();
		}
		if (includeSelf && !app.viewedObj().isStage) {
			m.addItem(Translator.map('myself'), 'myself');
			m.addLine();
			spriteNames.push(app.viewedObj().objName);
		}
		for each (var sprite:ScratchSprite in app.stagePane.sprites()) {
			if (sprite != app.viewedObj()) spriteNames.push(sprite.objName);
		}
		spriteNames.sort(Array.CASEINSENSITIVE);
		for each (var spriteName:String in spriteNames) {
			m.addItem(spriteName);
		}
		showMenu(m);
	}

	private function stopMenu(evt:MouseEvent):void {
		function setStopType(selection:*):void {
			blockArg.setArgValue(selection);
			block.setTerminal((selection == 'all') || (selection == 'this script'));
			block.type = block.isTerminal ? 'f' : ' ';
			Scratch.app.setSaveNeeded();
		}
		var m:Menu = new Menu(setStopType, 'stop');
		if (!block.nextBlock) {
			m.addItem('all');
			m.addItem('this script');
		}
		m.addItem(app.viewedObj().isStage ? 'other scripts in stage' : 'other scripts in sprite');
		showMenu(m);
	}

	private function stageOrThisSpriteMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'stageOrThis');
		m.addItem(app.stagePane.objName);
		if (!app.viewedObj().isStage) m.addItem('this sprite');
		showMenu(m);
	}

	private function timeAndDateMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'timeAndDate');
		m.addItem('year');
		m.addItem('month');
		m.addItem('date');
		m.addItem('day of week');
		m.addItem('hour');
		m.addItem('minute');
		m.addItem('second');
		showMenu(m);
	}

	private function triggerSensorMenu(evt:MouseEvent):void {
		function setTriggerType(s:String):void {
			if ('video motion' == s) app.libraryPart.showVideoButton();
			setBlockArg(s);
		}
		var m:Menu = new Menu(setTriggerType, 'triggerSensor');
		m.addItem('loudness');
		m.addItem('timer');
		m.addItem('video motion');
		showMenu(m);
	}

	private function videoMotionTypeMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'videoMotion');
		m.addItem('motion');
		m.addItem('direction');
		showMenu(m);
	}

	private function videoStateMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(setBlockArg, 'videoState');
		m.addItem('off');
		m.addItem('on');
		m.addItem('on-flipped');
		showMenu(m);
	}

	// ***** Generic block menu *****

	private function genericBlockMenu(evt:MouseEvent):void {
		if (!block || block.isEmbeddedParameter()) return;
		var m:Menu = new Menu(null, 'genericBlock');
		addGenericBlockItems(m);
		showMenu(m);
	}

	private function addGenericBlockItems(m:Menu):void {
		if (!block) return;
		m.addLine();
		if (!isInPalette(block)) {
			if(block.op == "whenArduino")//增加Arduino生成与上传选项_wh
			{
				m.addItem('upload to arduino', upload2A);
				m.addItem('arduino source', ASource);
			}
			if (!block.isProcDef()) {
				m.addItem('duplicate', duplicateStack);
			}
			m.addItem('delete', block.deleteStack);
			m.addLine();
			m.addItem('add comment', block.addComment);//添加注释_wh
		}
		m.addItem('help', block.showHelp);
		m.addLine();
	}

	//生成arduino代码_wh
	private function ASource():void {
		app.ArduinoRPFlag = true;
		app.ArduinoRPNum = 2;
		app.interp.toggleThread(block, app.viewedObj());
	}
	
	//上传到arduino板_wh
	private function upload2A():void {
		app.ArduinoRPFlag = true;
		app.ArduinoRPNum = 1;
		app.interp.toggleThread(block, app.viewedObj());
	}
	
	private function duplicateStack():void {
		block.duplicateStack(app.mouseX - startX, app.mouseY - startY);
	}

	private function changeOpMenu(evt:MouseEvent, opList:Array):void {
		function opMenu(selection:*):void {
			if (selection is Function) { selection(); return; }
			block.changeOperator(selection);
		}
		if (!block) return;
		var m:Menu = new Menu(opMenu, 'changeOp');
		addGenericBlockItems(m);
		if (!isInPalette(block)) for each (var op:String in opList) m.addItem(op);
		showMenu(m);
	}

	// ***** Procedure menu (for procedure definition hats and call blocks) *****

	private function procMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(null, 'proc');
		addGenericBlockItems(m);
		m.addItem('edit', editProcSpec);
		showMenu(m);
	}

	private function editProcSpec():void {
		if (block.op == Specs.CALL) {
			var def:Block = app.viewedObj().lookupProcedure(block.spec);
			if (!def) return;
			block = def;
		}
		var d:DialogBox = new DialogBox(editSpec2);
		d.addTitle('Edit Block');
		d.addWidget(new ProcedureSpecEditor(block.spec, block.parameterNames, block.warpProcFlag));
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage, true);
		ProcedureSpecEditor(d.widget).setInitialFocus();
	}

	private function editSpec2(dialog:DialogBox):void {
		var newSpec:String = ProcedureSpecEditor(dialog.widget).spec();
		if (newSpec.length == 0) return;
		if (block != null) {
			var oldSpec:String = block.spec;
			block.parameterNames = ProcedureSpecEditor(dialog.widget).inputNames();
			block.defaultArgValues = ProcedureSpecEditor(dialog.widget).defaultArgValues();
			block.warpProcFlag = ProcedureSpecEditor(dialog.widget).warpFlag();
			block.setSpec(newSpec);
			if (block.nextBlock) block.nextBlock.allBlocksDo(function(b:Block):void {
				if (b.op == Specs.GET_PARAM) b.parameterIndex = -1; // parameters may have changed; clear cached indices
			});
			for each (var caller:Block in app.runtime.allCallsOf(oldSpec, app.viewedObj())) {
				var oldArgs:Array = caller.args;
				caller.setSpec(newSpec, block.defaultArgValues);
				for (var i:int = 0; i < oldArgs.length; i++) {
					var arg:* = oldArgs[i];
					if (arg is BlockArg) arg = arg.argValue;
					caller.setArg(i, arg);
				}
				caller.fixArgLayout();
			}
		}
		app.runtime.updateCalls();
		app.updatePalette();
	}

	// ***** Variable and List menus *****

	private function listMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(varOrListSelection, 'list');
		var isGetter:Boolean = block.op == Specs.GET_LIST;
		if (isGetter) {
			if (isInPalette(block)) m.addItem('delete list', deleteVarOrList); // list reporter in palette
			addGenericBlockItems(m);
			m.addLine()
		}
		var myName:String = isGetter ? blockVarOrListName() : null;
		var listName:String;
		for each (listName in app.stageObj().listNames()) {
			if (listName != myName) m.addItem(listName);
		}
		if (!app.viewedObj().isStage) {
			m.addLine();
			for each (listName in app.viewedObj().listNames()) {
				if (listName != myName) m.addItem(listName);
			}
		}
		showMenu(m);
	}

	private function varMenu(evt:MouseEvent):void {
		var m:Menu = new Menu(varOrListSelection, 'var');
		var isGetter:Boolean = (block.op == Specs.GET_VAR);
		if (isGetter && isInPalette(block)) { // var reporter in palette
			m.addItem('rename variable', renameVar);
			m.addItem('delete variable', deleteVarOrList);
			addGenericBlockItems(m);
		} else {
			if (isGetter) addGenericBlockItems(m);
			var myName:String = blockVarOrListName();
			var vName:String;
			for each (vName in app.stageObj().varNames()) {
				if (!isGetter || (vName != myName)) m.addItem(vName);
			}
			if (!app.viewedObj().isStage) {
				m.addLine();
				for each (vName in app.viewedObj().varNames()) {
					if (!isGetter || (vName != myName)) m.addItem(vName);
				}
			}
		}
		showMenu(m);
	}

	private function isInPalette(b:Block):Boolean {
		var o:DisplayObject = b;
		while (o != null) {
			if (o == app.palette) return true;
			o = o.parent;
		}
		return false;
	}

	private function varOrListSelection(selection:*):void {
		if (selection is Function) { selection(); return; }
		setBlockVarOrListName(selection);
	}

	private function renameVar():void {
		function doVarRename(dialog:DialogBox):void {
			var newName:String = dialog.getField('New name').replace(/^\s+|\s+$/g, '');
			if (newName.length == 0 || block.op != Specs.GET_VAR) return;
			var oldName:String = blockVarOrListName();

			if (oldName.charAt(0) == '\u2601') { // Retain the cloud symbol
				newName = '\u2601 ' + newName;
			}

			app.runtime.renameVariable(oldName, newName);
		}
		var d:DialogBox = new DialogBox(doVarRename);
		d.addTitle(Translator.map('Rename') + ' ' + blockVarOrListName());
		d.addField('New name', 120);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function deleteVarOrList():void {
		function doDelete(selection:*):void {
			if (block.op == Specs.GET_VAR) {
				app.runtime.deleteVariable(blockVarOrListName());
			} else {
				app.runtime.deleteList(blockVarOrListName());
			}
			app.updatePalette();
			app.setSaveNeeded();
		}
		DialogBox.confirm(Translator.map('Delete') + ' ' + blockVarOrListName() + '?', app.stage, doDelete);
	}

	private function blockVarOrListName():String {
		return (blockArg != null) ? blockArg.argValue : block.spec;
	}

	private function setBlockVarOrListName(newName:String):void {
		if (newName.length == 0) return;
		if ((block.op == Specs.GET_VAR) || (block.op == Specs.SET_VAR) || (block.op == Specs.CHANGE_VAR)) {
			app.runtime.createVariable(newName);
		}
		if (blockArg != null) blockArg.setArgValue(newName);
		if (block != null && (block.op == Specs.GET_VAR || block.op == Specs.GET_LIST)) {
			block.setSpec(newName);
			block.fixExpressionLayout();
		}
		Scratch.app.setSaveNeeded();
	}

	// ***** Color picker support *****

	public function dragBegin(evt:MouseEvent):void { }

	public function dragEnd(evt:MouseEvent):void {
		if (pickingColor) {
			pickingColor = false;
			Mouse.cursor = MouseCursor.AUTO;
			app.stage.removeChild(colorPickerSprite);
			app.stage.removeEventListener(Event.RESIZE, fixColorPickerLayout);
		} else {
			pickingColor = true;
			app.gh.setDragClient(this, evt);
			Mouse.cursor = MouseCursor.BUTTON;
			app.stage.addEventListener(Event.RESIZE, fixColorPickerLayout);
			app.stage.addChild(colorPickerSprite = new Sprite);
			fixColorPickerLayout();
		}
	}

	public function dragMove(evt:MouseEvent):void {
		if (pickingColor) {
			blockArg.setArgValue(pixelColorAt(evt.stageX, evt.stageY));
			Scratch.app.setSaveNeeded();
		}
	}

	private function fixColorPickerLayout(event:Event = null):void {
		var g:Graphics = colorPickerSprite.graphics;
		g.clear();
		g.beginFill(0, 0);
		g.drawRect(0, 0, app.stage.stageWidth, app.stage.stageHeight);
	}

	private var pickingColor:Boolean = false;
	private var colorPickerSprite:Sprite;
	private var onePixel:BitmapData = new BitmapData(1, 1);

	private function pixelColorAt(x:int, y:int):int {
		var m:Matrix = new Matrix();
		m.translate(-x, -y);
		onePixel.fillRect(onePixel.rect, 0);
		if (app.isIn3D) app.stagePane.visible = true;
		onePixel.draw(app, m);
		if (app.isIn3D) app.stagePane.visible = false;
		x = onePixel.getPixel32(0, 0);
		return x ? x | 0xFF000000 : 0xFFFFFFFF; // alpha is always 0xFF
	}

	// ***** Broadcast menu *****

	private function broadcastMenu(evt:MouseEvent):void {
		function broadcastMenuSelection(selection:*):void {
			if (selection is Function) selection();
			else setBlockArg(selection);
		}
		var msgNames:Array = app.runtime.collectBroadcasts();
		if (msgNames.indexOf('message1') <= -1) msgNames.push('message1');
		msgNames.sort();

		var m:Menu = new Menu(broadcastMenuSelection, 'broadcast');
		for each (var msg:String in msgNames) m.addItem(msg);
		m.addLine();
		m.addItem('new message...', newBroadcast);
		showMenu(m);
	}

	private function newBroadcast():void {
		function changeBroadcast(dialog:DialogBox):void {
			var newName:String = dialog.getField('Message Name');
			if (newName.length == 0) return;
			setBlockArg(newName);
		}
		var d:DialogBox = new DialogBox(changeBroadcast);
		d.addTitle('New Message');
		d.addField('Message Name', 120);
		d.addAcceptCancelButtons('OK');
		d.showOnStage(app.stage);
	}

	private function broadcastInfoMenu(evt:MouseEvent):void {
		function showBroadcasts(selection:*):void {
			if (selection is Function) { selection(); return; }
			var msg:String = block.args[0].argValue;
			var sprites:Array = [];
			if (selection == 'show senders') sprites = app.runtime.allSendersOfBroadcast(msg);
			if (selection == 'show receivers') sprites = app.runtime.allReceiversOfBroadcast(msg);
			if (selection == 'clear senders/receivers') sprites = [];
			app.highlightSprites(sprites);
		}
		var m:Menu = new Menu(showBroadcasts, 'broadcastInfo');
		addGenericBlockItems(m);
		if (!isInPalette(block)) {
			m.addItem('show senders');
			m.addItem('show receivers');
			m.addItem('clear senders/receivers');
		}
		showMenu(m);
	}

}}
