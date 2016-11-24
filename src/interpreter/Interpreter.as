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

// Interpreter.as
// John Maloney, August 2009
// Revised, March 2010
//
// A simple yet efficient interpreter for blocks.
//
// Interpreters may seem mysterious, but this one is quite straightforward. Since every
// block knows which block (if any) follows it in a sequence of blocks, the interpreter
// simply executes the current block, then asks that block for the next block. The heart
// of the interpreter is the evalCmd() function, which looks up the opcode string in a
// dictionary (initialized by initPrims()) then calls the primitive function for that opcode.
// Control structures are handled by pushing the current state onto the active thread's
// execution stack and continuing with the first block of the substack. When the end of a
// substack is reached, the previous execution state is popped. If the substack was a loop
// body, control yields to the next thread. Otherwise, execution continues with the next
// block. If there is no next block, and no state to pop, the thread terminates.
//
// The interpreter does as much as it can within workTime milliseconds, then returns
// control. It returns control earlier if either (a) there are are no more threads to run
// or (b) some thread does a command that has a visible effect (e.g. "move 10 steps").
//
// To add a command to the interpreter, just add a new case to initPrims(). Command blocks
// usually perform some operation and return null, while reporters must return a value.
// Control structures are a little tricky; look at some of the existing control structure
// commands to get a sense of what to do.
//
// Clocks and time:
//
// The millisecond clock starts at zero when Flash is started and, since the clock is
// a 32-bit integer, it wraps after 24.86 days. Since it seems unlikely that one Scratch
// session would run that long, this code doesn't deal with clock wrapping.
// Since Scratch only runs at discrete intervals, timed commands may be resumed a few
// milliseconds late. These small errors accumulate, causing threads to slip out of
// synchronization with each other, a problem especially noticeable in music projects.
// This problem is addressed by recording the amount of time slippage and shortening
// subsequent timed commands slightly to "catch up".
// Delay times are rounded to milliseconds, and the minimum delay is a millisecond.

package interpreter {
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.DisplayObject;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import blocks.Block;
	import blocks.BlockArg;
	
	import primitives.Primitives;
	
	import scratch.ScratchObj;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;
	
	import sound.ScratchSoundPlayer;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;

public class Interpreter {

	public var activeThread:Thread;				// current thread
	public var currentMSecs:int = getTimer();	// millisecond clock for the current step
	public var turboMode:Boolean = false;

	private var app:Scratch;
	private var primTable:Dictionary;		// maps opcodes to functions
	private var threads:Array = [];			// all threads
	private var yield:Boolean;				// set true to indicate that active thread should yield control
	private var startTime:int;				// start time for stepThreads()
	private var doRedraw:Boolean;
	private var isWaiting:Boolean;

	private const warpMSecs:int = 500;		// max time to run during warp
	private var warpThread:Thread;			// thread that is in warp mode
	private var warpBlock:Block;			// proc call block that entered warp mode

	private var bubbleThread:Thread;			// thread for reporter bubble
	public var askThread:Thread;				// thread that opened the ask prompt
	
	public var ArduinoValDefStr:Array = new Array;
	public var ArduinoValDefFlag:Array = new Array;
	public var ArduinoValDefi:Number = 0;
	public var ArduinoIfElseB:Array = new Array;

	protected var debugFunc:Function;

	public function Interpreter(app:Scratch) {
		this.app = app;
		initPrims();
//		checkPrims();
	}

	public function targetObj():ScratchObj { return ScratchObj(activeThread.target) }
	public function targetSprite():ScratchSprite { return activeThread.target as ScratchSprite }

	/* Threads */

	public function doYield():void { isWaiting = true; yield = true }
	public function redraw():void { if (!turboMode) doRedraw = true }

	public function yieldOneCycle():void {
		// Yield control but proceed to the next block. Do nothing in warp mode.
		// Used to ensure proper ordering of HTTP extension commands.
		if (activeThread == warpThread) return;
		if (activeThread.firstTime) {
			redraw();
			yield = true;
			activeThread.firstTime = false;
		}
	}

	public function threadCount():int { return threads.length }

	public function toggleThread(b:Block, targetObj:*, startupDelay:int = 0):void {
		var i:int, newThreads:Array = [], wasRunning:Boolean = false;
		for (i = 0; i < threads.length; i++) {
			if ((threads[i].topBlock == b) && (threads[i].target == targetObj)) {
				wasRunning = true;
			} else {
				newThreads.push(threads[i]);
			}
		}
		threads = newThreads;
		if (wasRunning) {
			if (app.editMode) b.hideRunFeedback();
			clearWarpBlock();
		} else {
			var topBlock:Block = b;
			if (b.isReporter) {
				if((b.op == "readpower:")||(b.op == "readavoid:")||(b.op == "readtrack:")||(b.op == "readdigitals:")||(b.op == "readanalogs:")||(b.op == "readcap:")||(b.op == "readanalogsj:")||(b.op == "readdigital:")||(b.op == "readanalog:")||(b.op == "readckkey1")||(b.op == "readckkey2")||(b.op == "readcksound")||(b.op == "readckslide")||(b.op == "readcklight")||(b.op == "readckjoyx")||(b.op == "readckjoyy")||(b.op == "readAfloat:")||(b.op == "readPfloat:"))//||(b.op == "readdigitalj:")||(b.op == "readultrs:")
					;
				else
				{
					// click on reporter shows value in bubble
					if (bubbleThread) {
						toggleThread(bubbleThread.topBlock, bubbleThread.target);
					}
					var reporter:Block = b;
					var interp:Interpreter = this;
					b = new Block("%s", "", -1);
					b.opFunction = function(b:Block):void {
						var p:Point = reporter.localToGlobal(new Point(0, 0));
						app.showBubble(String(interp.arg(b, 0)), p.x, p.y, reporter.getRect(app.stage).width);
					};
					b.args[0] = reporter;
				}
			}
			if (app.editMode) topBlock.showRunFeedback();
			var t:Thread = new Thread(b, targetObj, startupDelay);
			if (topBlock.isReporter) bubbleThread = t;
			t.topBlock = topBlock;
			threads.push(t);
			app.threadStarted();
		}
	}

	public function showAllRunFeedback():void {
		for each (var t:Thread in threads) {
			t.topBlock.showRunFeedback();
		}
	}

	public function isRunning(b:Block, targetObj:ScratchObj):Boolean {
		for each (var t:Thread in threads) {
			if ((t.topBlock == b) && (t.target == targetObj)) return true;
		}
		return false;
	}

	public function startThreadForClone(b:Block, clone:*):void {
		threads.push(new Thread(b, clone));
	}

	public function stopThreadsFor(target:*, skipActiveThread:Boolean = false):void {
		for (var i:int = 0; i < threads.length; i++) {
			var t:Thread = threads[i];
			if (skipActiveThread && (t == activeThread)) continue;
			if (t.target == target) {
				if (t.tmpObj is ScratchSoundPlayer) {
					(t.tmpObj as ScratchSoundPlayer).stopPlaying();
				}
				t.stop();
			}
		}
		if ((activeThread.target == target) && !skipActiveThread) yield = true;
	}

	public function restartThread(b:Block, targetObj:*):Thread {
		// used by broadcast, click hats, and when key pressed hats
		// stop any thread running on b, then start a new thread on b
		var newThread:Thread = new Thread(b, targetObj);
		var wasRunning:Boolean = false;
		for (var i:int = 0; i < threads.length; i++) {
			if ((threads[i].topBlock == b) && (threads[i].target == targetObj)) {
				if (askThread == threads[i]) app.runtime.clearAskPrompts();
				threads[i] = newThread;
				wasRunning = true;
			}
		}
		if (!wasRunning) {
			threads.push(newThread);
			if (app.editMode) b.showRunFeedback();
			app.threadStarted();
		}
		return newThread;
	}

	public function stopAllThreads():void {
		threads = [];
		if (activeThread != null) 
		{
			activeThread.stop();
		}
		clearWarpBlock();
		app.runtime.clearRunFeedback();
		doRedraw = true;
		app.comCOMing = 0;//_wh
	}

	public function stepThreads():void {
		startTime = getTimer();
		var workTime:int = (0.75 * 1000) / app.stage.frameRate; // work for up to 75% of one frame time
		doRedraw = false;
		currentMSecs = getTimer();
		app.openNum = true;
		
		if (threads.length == 0)
		{
			if(app.ArduinoFlag == true)
			{
				if(app.ArduinoRPFlag == true)
				{
					app.ArduinoFs.writeUTFBytes('/* 创趣天地-CFunWorld */' + '\n' + '/* www.cfunworld.com */' + '\n');
					app.ArduinoFs.writeUTFBytes(
												  '#include <Wire.h>' + '\n'
												+ '#include "CFunPort.h"' + '\n'
												);
					if(app.ArduinoUs)
						app.ArduinoFs.writeUTFBytes('#include "CFunUltrasonic.h" ' + '\n');
					if(app.ArduinoSeg)
						app.ArduinoFs.writeUTFBytes('#include "CFun7SegmentDisplay.h" ' + '\n');
					if(app.ArduinoRGB)
						app.ArduinoFs.writeUTFBytes('#include "CFunRGBLed.h" ' + '\n');
					if(app.ArduinoBuz)
						app.ArduinoFs.writeUTFBytes('#include "CFunBuzzer.h" ' + '\n');
					if(app.ArduinoCap)
						app.ArduinoFs.writeUTFBytes('#include "CFunreadCapacitive.h" ' + '\n');
					if(app.ArduinoDCM)
						app.ArduinoFs.writeUTFBytes('#include "CFunDCMotor.h" ' + '\n');
					if(app.ArduinoSer)
						app.ArduinoFs.writeUTFBytes('#include "Servo.h" ' + '\n');
					if(app.ArduinoIR)
						app.ArduinoFs.writeUTFBytes('#include "CFunIR.h" ' + '\n');
					if(app.ArduinoTem)
						app.ArduinoFs.writeUTFBytes('#include "CFunTemperature.h" ' + '\n');
					if(app.ArduinoAvo)
						app.ArduinoFs.writeUTFBytes('#include "CFunAvoid.h" ' + '\n');
					if(app.ArduinoTra)
						app.ArduinoFs.writeUTFBytes('#include "CFunTrack.h" ' + '\n');
					
					app.ArduinoHeadFs.open(app.ArduinoHeadFile,FileMode.READ);
					app.ArduinoHeadFs.position = 0;
					app.ArduinoFs.writeUTFBytes(app.ArduinoHeadFs.readMultiByte(app.ArduinoHeadFs.bytesAvailable,'utf-8'));//head_wh
					
					app.ArduinoFs.writeUTFBytes('\n' + "void setup(){" + '\n' + "delay(20);" + '\n');
					
					//app.ArduinoPinFs.close();
					app.ArduinoPinFs.open(app.ArduinoPinFile,FileMode.READ);
					app.ArduinoPinFs.position = 0;
					app.ArduinoFs.writeUTFBytes(app.ArduinoPinFs.readMultiByte(app.ArduinoPinFs.bytesAvailable,'utf-8'));//pinmode_wh
					
					//app.ArduinoDoFs.close();
					app.ArduinoDoFs.open(app.ArduinoDoFile,FileMode.READ);
					app.ArduinoDoFs.position = 0;
					app.ArduinoFs.writeUTFBytes(app.ArduinoDoFs.readMultiByte(app.ArduinoDoFs.bytesAvailable,'utf-8'));//do_wh
					
					app.ArduinoFs.writeUTFBytes("}"+'\n');
					
					app.ArduinoFs.writeUTFBytes('\n'+"void loop(){"+'\n');
				
					app.ArduinoLoopFs.open(app.ArduinoLoopFile,FileMode.READ);
					app.ArduinoLoopFs.position = 0;
					app.ArduinoFs.writeUTFBytes(app.ArduinoLoopFs.readMultiByte(app.ArduinoLoopFs.bytesAvailable,'utf-8'));//loop_wh
					
					app.ArduinoFs.writeUTFBytes("}"+'\n');
					
					if(app.ArduinoUs)
						app.ArduinoFs.writeUTFBytes('\n' + 'void ius(){' +'\n'
													+ '_iustime = micros()-_itime;' +'\n'
													+ 'noInterrupts();' +'\n'
													+ '}'
													+'\n');
				}
				
				app.ArduinoHeadFs.close();
				app.ArduinoPinFs.close();
				app.ArduinoDoFs.close();
				app.ArduinoFs.close();
				app.ArduinoFlag = false;
				
				for (var i:int = 0; i < ArduinoValDefi; i++)
				{
					ArduinoValDefFlag[i] = 0;
				}
				
				if(app.ArduinoRPFlag == true)
				{
					if(app.ArduinoWarnFlag == false)
					{
						if(app.ArduinoRPNum == 2)
						{
							app.ArduinoRPNum = 0;
							app.ArduinoFile.openWithDefaultApplication();
						}
						
						if(app.ArduinoRPNum == 1)
						{
							app.ArduinoRPNum = 0;
							app.ArduinoFile.copyTo(app.ArduinoFileB,true);
							
							if(app.comTrue)
								app.arduino.close();
							else
							{
								app.ArduinoRPFlag = false;
								DialogBox.warnconfirm(Translator.map("error about uploading to arduino"),Translator.map("please open the COM"), null, app.stage);//软件界面中部显示提示框_wh
								return;
							}
							var file:File = new File();
//							var process:NativeProcess = new NativeProcess();
//							var nativePSInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
							file = file.resolvePath(File.userDirectory.resolvePath("AS-Block/ArduinoBuilder/cmd.exe").nativePath);//调用cmd.exe_wh
							app.nativePSInfo.executable = file;
							app.process.start(app.nativePSInfo);
							var str:String = File.userDirectory.resolvePath("AS-Block/ArduinoBuilder").nativePath;
							app.process.standardInput.writeUTFBytes("cd /d "+ File.userDirectory.resolvePath("AS-Block/ArduinoBuilder").nativePath +"\r\n");
							app.process.standardInput.writeUTFBytes("ArduinoUploader arduinos.ino 1 " + app.comIDTrue + " 16MHZ" + "\r\n");

							app.UpDialog.setText(Translator.map("compiliation") + " ... ");
							app.UpDialog.showOnStage(app.stage);

							app.delay1sTimer.start();
							app.cmdBackNum = 1;
							app.process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, app.cmdDataHandler);
						}
					}
				}
			}
			return;
		}
		while ((currentMSecs - startTime) < workTime) {
			if (warpThread && (warpThread.block == null)) clearWarpBlock();
			var threadStopped:Boolean = false;
			var runnableCount:int = 0;
			for each (activeThread in threads) {
				isWaiting = false;
				stepActiveThread();
				if (activeThread.block == null) threadStopped = true;
				if (!isWaiting) runnableCount++;
			}
			if (threadStopped) {
				var newThreads:Array = [];
				for each (var t:Thread in threads) {
					if (t.block != null) newThreads.push(t);
					else if (app.editMode) {
						if (t == bubbleThread) bubbleThread = null;
						t.topBlock.hideRunFeedback();
					}
				}
				threads = newThreads;
				if (threads.length == 0) return;
			}
			currentMSecs = getTimer();
			if (doRedraw || (runnableCount == 0)) return;
		}
	}

	private function stepActiveThread():void {
		var xi:Number = 0;
		var pop:Boolean = true;
		if (activeThread.block == null) return;
		if (activeThread.startDelayCount > 0) { activeThread.startDelayCount--; doRedraw = true; return; }
		if (!(activeThread.target.isStage || (activeThread.target.parent is ScratchStage))) {
			// sprite is being dragged
			if (app.editMode) {
				// don't run scripts of a sprite that is being dragged in edit mode, but do update the screen
				doRedraw = true;
				return;
			}
		}
		yield = false;
		while (true) {
			if (activeThread == warpThread) currentMSecs = getTimer();
			evalCmd(activeThread.block);
			
			if (yield) {
				if (activeThread == warpThread) {
					if ((currentMSecs - startTime) > warpMSecs) return;
					yield = false;
					continue;
				} else return;
			}

			if (activeThread.block != null)
				activeThread.block = activeThread.block.nextBlock;

			while (activeThread.block == null) { // end of block sequence
				
				if(app.ArduinoFlag == true)
				{
					for(xi = app.ArduinoBracketN-1; xi >= 0; xi--)
					{
						if(app.ArduinoBracketXF[xi])
						{
							if(app.ArduinoBracketXF[xi] == 1)
							{
								if(app.ArduinoLoopFlag == true)
									app.ArduinoLoopFs.writeUTFBytes("}" + '\n');
								else
									app.ArduinoDoFs.writeUTFBytes("}" + '\n');
							}
							else
							{
								if(app.ArduinoLoopFlag == true)
									app.ArduinoLoopFs.writeUTFBytes("}" + '\n' + "else" + " {" + '\n');
								else
									app.ArduinoDoFs.writeUTFBytes("}" + '\n' + "else" + " {" + '\n');
								app.ArduinoBracketXF[app.ArduinoBracketN ++] = 1;
								
								activeThread.popState();
								startCmdList(ArduinoIfElseB[xi]);
								pop = false;
								
							}
							app.ArduinoBracketXF[xi] = 0;	
							break;
						}
					}
				}

				if(pop)
				{
					if (!activeThread.popState()) return; // end of script
				}
				else
					pop = true;
				
				if ((activeThread.block == warpBlock) && activeThread.firstTime) { // end of outer warp block
					clearWarpBlock();
					activeThread.block = activeThread.block.nextBlock;
					continue;
				}
				if (activeThread.isLoop) {
					if (activeThread == warpThread) {
						if ((currentMSecs - startTime) > warpMSecs) return;
					} else return;
				} else {
					if (activeThread.block.op == Specs.CALL) activeThread.firstTime = true; // in case set false by call
					activeThread.block = activeThread.block.nextBlock;
				}
			}
		}
	}

	private function clearWarpBlock():void {
		if(activeThread != null)
		{
			if(activeThread.comATCOMing)
				app.comCOMing = 0;
			activeThread.comWaitNum = 0;//_wh
			activeThread.comATCOMing = 0;//_wh
		}
		warpThread = null;
		warpBlock = null;
		app.readCDFlag = false;
	}

	/* Evaluation */
	public function evalCmd(b:Block):* {
		if (!b) return 0; // arg() and friends can pass null if arg index is out of range
		var op:String = b.op;
		if (b.opFunction == null) {
			if (op.indexOf('.') > -1) b.opFunction = app.extensionManager.primExtensionOp;
			else b.opFunction = (primTable[op] == undefined) ? primNoop : primTable[op];
		}

		// TODO: Optimize this into a cached check if the args *could* block at all
		if(b.args.length && checkBlockingArgs(b)) {
			doYield();
			return null;
		}
		
		
		// Debug code
		if(debugFunc != null)
			debugFunc(b);

		var lostTime:Number = 100;
		if(app.ArduinoFlag == false)
		{
			if(app.blueFlag)
			{
				lostTime = 250;
				if(app.tFlag)
				{
					var timeDelay:Number = getTimer() - app.timeStart;
					if(timeDelay < app.timeDelayAll)
					{
						doYield();
						//app.test ++;
						return null;
					}
				}
				app.tFlag = false;
			}
			else
				lostTime = 100;
			switch(op)
			{
				case "readdigital:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readdigitalSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readdigitals:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readdigitalsSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readckkey1":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readckkey1Send"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKkey1 = b.opFunction(b);
								return (Boolean)(app.CKkey1);
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readckkey2":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readckkey2Send"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKkey2 = b.opFunction(b);
								return (Boolean)(app.CKkey2);
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readanalog:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readanalogSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readanalogs:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readanalogsSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readcksound":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readcksoundSend"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKsound = (int)(b.opFunction(b)/5);
								if(app.CKsound > 100)
									app.CKsound = 100;
								return app.CKsound;
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readcklight":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readcklightSend"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKlight = (int)(b.opFunction(b)*100/1023);
								return app.CKlight;
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readckslide":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readckslideSend"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKslide = (int)(b.opFunction(b)*100/1023);
								return app.CKslide;
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readckjoyx":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readckjoyxSend"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKjoyx = (int)(b.opFunction(b)*200/1023-100);
								return app.CKjoyx;
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
						//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
						//						app.comCOMing = 1;
						//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readckjoyy":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readckjoyySend"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
								app.CKjoyy = (int)(b.opFunction(b)*200/1023-100);
								return app.CKjoyy;
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
						//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
						//						app.comCOMing = 1;
						//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readanalogsj:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readanalogsjSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readAfloat:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readAfloatSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readPfloat:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readPfloatSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readcap:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readcapSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readtrack:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readtrackSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readavoid:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readavoidSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;

				case "readpower:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readpowerSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				case "readfraredR:":
					if(app.comCOMing == 0)
					{
						app.comCOMing = 1;
						//if(activeThread.comWaitNum == 0)
						{
							activeThread.comATCOMing = 1;
							activeThread.ArduinoNA = false;
							b.opFunction = primTable["readfraredRSend:"];app.comRevFlag = false;b.opFunction(b);
							activeThread.startT = getTimer();
						}
					}
					if(activeThread.comATCOMing == 1)
					{
						activeThread.comWaitNum++;
						
						if((getTimer() - activeThread.startT) >= lostTime)
						{
							activeThread.comWaitNum = 0;
							app.comRevFlag = false;
							app.comCOMing = 0;
							activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
							if(app.readCDFlag == false)
							{
								app.CFunConCir(2);//DialogBox.warnconfirm(Translator.map("communication problem"),Translator.map("please check communication"), null, app.stage);
								app.readCDFlag = true;
							}
							return 0;
						}
						
						if(app.comRevFlag == false)
						{
							doYield();
						}
						
						if(activeThread.comWaitNum)
						{
							if(app.comRevFlag)
							{
								activeThread.comWaitNum = 0;
								app.comRevFlag = false;
								app.comCOMing = 0;
								activeThread.comATCOMing = 0;activeThread.ArduinoNA = false;
								b.opFunction = primTable[op];
							}
							else
							{
								activeThread.ArduinoNA = true;
								return;
							}
						}
					}
					else
					{
//						activeThread.comWaitNum = 1;
						doYield();
						activeThread.ArduinoNA = true;
//						app.comCOMing = 1;
//						activeThread.comATCOMing = 1;
						return;
					}
					break;
				//case "0":break;
				default:break;
			}
		}
		//Arduino程序生成流程_wh
		else
		{
			switch(op)
			{
				case "readdigital:":b.opFunction = primTable["readdigitalSend:"];break;
				case "readanalog:":b.opFunction = primTable["readanalogSend:"];break;
				
				case "readckkey1":b.opFunction = primTable["readckkey1Send"];break;
				case "readckkey2":b.opFunction = primTable["readckkey2Send"];break;
				case "readcksound":b.opFunction = primTable["readcksoundSend"];break;
				case "readckslide":b.opFunction = primTable["readckslideSend"];break;
				case "readcklight":b.opFunction = primTable["readcklightSend"];break;
				case "readckjoyx":b.opFunction = primTable["readckjoyxSend"];break;
				case "readckjoyy":b.opFunction = primTable["readckjoyySend"];break;
				
				case "readavoid:":b.opFunction = primTable["readavoidSend:"];break;
				//case "readultrs:":b.opFunction = primTable["readultrsSend:"];break;
				case "readtrack:":b.opFunction = primTable["readtrackSend:"];break;
				case "readpower:":b.opFunction = primTable["readpowerSend:"];break;
				case "readfraredR:":b.opFunction = primTable["readfraredRSend:"];break;
				
				case "readdigitals:":	b.opFunction = primTable["readdigitalsSend:"];break;
				case "readanalogs:":	b.opFunction = primTable["readanalogsSend:"];break;
				case "readanalogsj:":	b.opFunction = primTable["readanalogsjSend:"];break;
				//case "readdigitalj:":	b.opFunction = primTable["readdigitaljSend:"];break;
				case "readcap:":		b.opFunction = primTable["readcapSend:"];break;
				case "readAfloat:":	b.opFunction = primTable["readAfloatSend:"];break;
				case "readPfloat:":	b.opFunction = primTable["readPfloatSend:"];break;
				
				default:break;
			}
		}
		return b.opFunction(b);
	}

	// Returns true if the thread needs to yield while data is requested
	public function checkBlockingArgs(b:Block):Boolean {
		// Do any of the arguments request data?  If so, start any requests and yield.
		var shouldYield:Boolean = false;
		var args:Array = b.args;
		for(var i:uint=0; i<args.length; ++i) {
			var barg:Block = args[i] as Block;
			if(barg) {
				if(checkBlockingArgs(barg))
					shouldYield = true;

				// Don't start a request if the arguments for it are blocking
				else if(barg.isRequester && barg.requestState < 2) {
					if(barg.requestState == 0) evalCmd(barg);
					shouldYield = true;
				}
			}
		}

		return shouldYield;
	}

	public function arg(b:Block, i:int):* {
		var args:Array = b.args;
		if (b.rightToLeft) { i = args.length - i - 1; }
		return (b.args[i] is BlockArg) ?
			BlockArg(args[i]).argValue : evalCmd(Block(args[i]));
	}

	public function numarg(b:Block, i:int):Number {
		var args:Array = b.args;
		if (b.rightToLeft) { i = args.length - i - 1; }
		var n:Number = (args[i] is BlockArg) ?
			Number(BlockArg(args[i]).argValue) : Number(evalCmd(Block(args[i])));

//		if (n != n) // return 0 if NaN (uses fast, inline test for NaN)//无效数据判断标志_wh
//		{
//			app.ArduinoNAN = true;
//			return 0;
//		}
		return n;
	}

	public function boolarg(b:Block, i:int):Boolean {
		if (b.rightToLeft) { i = b.args.length - i - 1; }
		var o:* = (b.args[i] is BlockArg) ? BlockArg(b.args[i]).argValue : evalCmd(Block(b.args[i]));
		if (o is Boolean) return o;
		if (o is String) {
			var s:String = o;
			if ((s == '') || (s == '0') || (s.toLowerCase() == 'false')) return false
			return true; // treat all other strings as true
		}
		return Boolean(o); // coerce Number and anything else
	}

	public static function asNumber(n:*):Number {
		// Convert n to a number if possible. If n is a string, it must contain
		// at least one digit to be treated as a number (otherwise a string
		// containing only whitespace would be consider equal to zero.)
		if (typeof(n) == 'string') {
			var s:String = n as String;
			var len:uint = s.length;
			for (var i:int = 0; i < len; i++) {
				var code:uint = s.charCodeAt(i);
				if (code >= 48 && code <= 57) return Number(s);
			}
			return NaN; // no digits found; string is not a number
		}
		return Number(n);
	}

	private function startCmdList(b:Block, isLoop:Boolean = false, argList:Array = null):void {
		if(activeThread.comWaitNum == 0)
		{
			if (b == null) {
				if (isLoop) yield = true;
				return;
			}
			
			activeThread.isLoop = isLoop;
			activeThread.pushStateForBlock(b);
			if (argList) activeThread.args = argList;
		
		evalCmd(activeThread.block);
		}
	}

	/* Timer */

	public function startTimer(secs:Number):void {
		var waitMSecs:int = 1000 * secs;
		if (waitMSecs < 0) waitMSecs = 0;
		activeThread.tmp = currentMSecs + waitMSecs; // end time in milliseconds
		activeThread.firstTime = false;
		doYield();
	}

	public function checkTimer():Boolean {
		// check for timer expiration and clean up if expired. return true when expired
		if (currentMSecs >= activeThread.tmp) {
			// time expired
			activeThread.tmp = 0;
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
			return true;
		} else {
			// time not yet expired
			doYield();
			return false;
		}
	}

	/* Primitives */

	public function isImplemented(op:String):Boolean {
		return primTable[op] != undefined;
	}

	public function getPrim(op:String):Function { return primTable[op] }
    
	private function initPrims():void {
		var xj:Array = new Array;
		primTable = new Dictionary();
		// control
		primTable["whenGreenFlag"]		= primNoop;
		primTable["whenKeyPressed"]		= primNoop;
		primTable["whenClicked"]		= primNoop;
		primTable["whenSceneStarts"]	= primNoop;
		primTable["whenpicbp"]		= primNoop;
		primTable["whenpicac"]		= primNoop;
		primTable["wait:elapsed:from:"]	= primWait;
		primTable["doForever"]			= function(b:*):* 
										{
											if(app.ArduinoFlag == true)
											{
												app.ArduinoLoopFlag = true;
												startCmdList(b.subStack1); 
											}
											else
												startCmdList(b.subStack1, true); 
										}
		primTable["doRepeat"]			= function(b:*):* 
										{
											if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
											{
												app.ArduinoMathNum = 0;
												var num:Number = numarg(b, 0);
												if(app.ArduinoValueFlag == true)
												{
													if(app.ArduinoLoopFlag == true)
														app.ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + app.ArduinoValueStr + ";i++)" + "{" + '\n');
													else
														app.ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + app.ArduinoValueStr + ";i++)" + "{" + '\n');
													app.ArduinoValueFlag = false;
												}
												else
												{
													if(app.ArduinoReadFlag == true)
													{
														if(app.ArduinoLoopFlag == true)
															app.ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + app.ArduinoReadStr[0] + ";i++)" + "{" + '\n');
														else
															app.ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + app.ArduinoReadStr[0] + ";i++)" + "{" + '\n');
														app.ArduinoReadFlag = false;
													}
													else
													{
														if(app.ArduinoMathFlag == true)
														{
															if(app.ArduinoLoopFlag == true)
																app.ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + app.ArduinoMathStr[0] + ";i++)" + "{" + '\n');
															else
																app.ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + app.ArduinoMathStr[0] + ";i++)" + "{" + '\n');
															app.ArduinoMathFlag = false;
														}
														else
														{
															if(app.ArduinoLoopFlag == true)
																app.ArduinoLoopFs.writeUTFBytes("for(int i=0;i<" + num + ";i++)" + "{" + '\n');
															else
																app.ArduinoDoFs.writeUTFBytes("for(int i=0;i<" + num + ";i++)" + "{" + '\n');
													}
													}
												}
												app.ArduinoBracketXF[app.ArduinoBracketN ++] = 1;
												startCmdList(b.subStack1);//代码块_wh
											}
											else
												primRepeat(b);
										}
		primTable["broadcast:"]			= function(b:*):* { broadcast(arg(b, 0), false); }
		primTable["doBroadcastAndWait"]	= function(b:*):* { broadcast(arg(b, 0), true); }
		primTable["whenIReceive"]		= primNoop;
		primTable["doForeverIf"]		= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1, true); else yield = true; }
		primTable["doForLoop"]			= primForLoop;
		primTable["doIf"]				= function(b:*):* 
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																app.ArduinoMathNum = 0;
																arg(b, 0);
																if(app.ArduinoReadFlag == true)
																{
																	if(app.ArduinoLoopFlag == true)
																	{
																		app.ArduinoLoopFs.writeUTFBytes("if(" + app.ArduinoReadStr[0] + ")" + " {" + '\n');
																		app.ArduinoReadFlag = false;
																	}
																	else
																	{
																		app.ArduinoDoFs.writeUTFBytes("if(" + app.ArduinoReadStr[0] + ")" + " {" + '\n');
																		app.ArduinoReadFlag = false;
																	}
																}
																else
																{
																	if(app.ArduinoMathFlag == true)
																	{
																		if(app.ArduinoLoopFlag == true)
																		{
																			app.ArduinoLoopFs.writeUTFBytes("if(" + app.ArduinoMathStr[0] + ")" + " {" + '\n');
																			app.ArduinoMathFlag = false;
																		}
																		else
																		{
																			app.ArduinoDoFs.writeUTFBytes("if(" + app.ArduinoMathStr[0] + ")" + " {" + '\n');
																			app.ArduinoMathFlag = false;
																		}
																	}
																}
																app.ArduinoBracketXF[app.ArduinoBracketN ++] = 1;
																startCmdList(b.subStack1);
															}
															else
															{
																var BF:Boolean = arg(b, 0);
																if(activeThread.ArduinoNA)//加有效性判断_wh
																{
																	activeThread.ArduinoNA = false;
																	return;
																}
																if(BF)
																	startCmdList(b.subStack1);
															}
														}
		primTable["doIfElse"]			= function(b:*):*
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																app.ArduinoMathNum = 0;
//																if(app.ArduinoBracketN)
//																	app.ArduinoIEBracketFlag ++;
																arg(b, 0);
																if(app.ArduinoReadFlag == true)
																{
																	if(app.ArduinoLoopFlag == true)
																	{
																		app.ArduinoLoopFs.writeUTFBytes("if(" + app.ArduinoReadStr[0] + ")" + " {" + '\n');
																		app.ArduinoReadFlag = false;
																	}
																	else
																	{
																		app.ArduinoDoFs.writeUTFBytes("if(" + app.ArduinoReadStr[0] + ")" + " {" + '\n');
																		app.ArduinoReadFlag = false;
																	}
																}
																else
																{
																	if(app.ArduinoMathFlag == true)
																	{
																		if(app.ArduinoLoopFlag == true)
																		{
																			app.ArduinoLoopFs.writeUTFBytes("if(" + app.ArduinoMathStr[0] + ")" + " {" + '\n');
																			app.ArduinoMathFlag = false;
																		}
																		else
																		{
																			app.ArduinoDoFs.writeUTFBytes("if(" + app.ArduinoMathStr[0] + ")" + " {" + '\n');
																			app.ArduinoMathFlag = false;
																		}
																	}
																}
																app.ArduinoMathNum = 0;
																app.ArduinoBracketXF[app.ArduinoBracketN ++] = 2;
																xj[app.ArduinoElseYi ++] = app.ArduinoBracketN - 1;
																startCmdList(b.subStack1);										
																ArduinoIfElseB[xj[--app.ArduinoElseYi]] = b.subStack2;//在stepActiveThread中处理_wh
															}
															else
															{
																var BF:Boolean = arg(b, 0);
																if(activeThread.ArduinoNA)//加有效性判断_wh
																{
																	activeThread.ArduinoNA = false;
																	return;
																}
																if(BF)
																	startCmdList(b.subStack1);
																else
																	startCmdList(b.subStack2);
															}
														}
		primTable["doWaitUntil"]		= function(b:*):*
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																app.ArduinoMathNum = 0;
																arg(b, 0);
																if(app.ArduinoReadFlag == true)
																{
																	if(app.ArduinoLoopFlag == true)
																	{
																		app.ArduinoLoopFs.writeUTFBytes("while(!" + app.ArduinoReadStr[0] + ");" + '\n');
																	}
																	else
																	{
																		app.ArduinoDoFs.writeUTFBytes("while(!" + app.ArduinoReadStr[0] + ");" + '\n');
																	}
																	app.ArduinoReadFlag = false;
																}
																else
																{
																	if(app.ArduinoMathFlag == true)
																	{
																		if(app.ArduinoLoopFlag == true)
																		{
																			app.ArduinoLoopFs.writeUTFBytes("while(!" + app.ArduinoMathStr[0] + ");" + '\n');
																		}
																		else
																		{
																			app.ArduinoDoFs.writeUTFBytes("while(!" + app.ArduinoMathStr[0] + ");" + '\n');
																		}
																		app.ArduinoMathFlag = false;
																	}
																}
															}
															else
															{
																var BF:Boolean = !arg(b, 0);
																if(activeThread.ArduinoNA)//加有效性判断_wh
																{
																	activeThread.ArduinoNA = false;
																	return;
																}
																if(BF)
																	yield = true;
															}
														}
		primTable["doWhile"]			= function(b:*):* { if (arg(b, 0)) startCmdList(b.subStack1, true); }
		primTable["doUntil"]			= function(b:*):*
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																app.ArduinoMathNum = 0;
																arg(b, 0);
																if(app.ArduinoReadFlag == true)
																{
																	if(app.ArduinoLoopFlag == true)
																	{
																		app.ArduinoLoopFs.writeUTFBytes("while(!" + app.ArduinoReadStr[0] + ")" + " {" + '\n');
																		app.ArduinoReadFlag = false;
																	}
																	else
																	{
																		app.ArduinoDoFs.writeUTFBytes("while(!" + app.ArduinoReadStr[0] + ")" + " {" + '\n');
																		app.ArduinoReadFlag = false;
																	}
																}
																else
																{
																	if(app.ArduinoMathFlag == true)
																	{
																		if(app.ArduinoLoopFlag == true)
																		{
																			app.ArduinoLoopFs.writeUTFBytes("while(!" + app.ArduinoMathStr[0] + ")" + " {" + '\n');
																			app.ArduinoMathFlag = false;
																		}
																		else
																		{
																			app.ArduinoDoFs.writeUTFBytes("while(!" + app.ArduinoMathStr[0] + ")" + " {" + '\n');
																			app.ArduinoMathFlag = false;
																		}
																	}
																}
																app.ArduinoBracketXF[app.ArduinoBracketN ++] = 1;
																startCmdList(b.subStack1);
															}
															else
															{
																var BF:Boolean = !arg(b, 0);
																if(activeThread.ArduinoNA)//加有效性判断_wh
																{
																	activeThread.ArduinoNA = false;
																	return;
																}
																if(BF)
																	startCmdList(b.subStack1, true);
															}
														}
		primTable["doReturn"]			= primReturn;
		primTable["stopAll"]			= function(b:*):*
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("stop all"), null, app.stage);//软件界面中部显示提示框_wh
															}
															else
															{
																app.runtime.stopAll(); yield = true;
															}
														}
		primTable["stopScripts"]		=  function(b:*):* 
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("stop ..."), null, app.stage);//软件界面中部显示提示框_wh
															}
															else
																primStop(b);
														}
		primTable["warpSpeed"]			= primOldWarpSpeed;

		// procedures
		primTable[Specs.CALL]			= primCall;

		// variables
		primTable[Specs.GET_VAR]		= primVarGet;
		primTable[Specs.SET_VAR]		= primVarSet;
		primTable[Specs.CHANGE_VAR]		= primVarChange;
		primTable[Specs.GET_PARAM]		= primGetParam;

		// edge-trigger hat blocks
		primTable["whenDistanceLessThan"]	= primNoop;
		primTable["whenSensorConnected"]	= primNoop;
		primTable["whenSensorGreaterThan"]	= primNoop;
		primTable["whenTiltIs"]				= primNoop;

		addOtherPrims(primTable);
	}

	protected function addOtherPrims(primTable:Dictionary):void {
		// other primitives
		new Primitives(app, this).addPrimsTo(primTable);
	}

	private function checkPrims():void {
		var op:String;
		var allOps:Array = ["CALL", "GET_VAR", "NOOP"];
		for each (var spec:Array in Specs.commands) {
			if (spec.length > 3) {
				op = spec[3];
				allOps.push(op);
				if (primTable[op] == undefined) trace("Unimplemented: " + op);
			}
		}
		for (op in primTable) {
			if (allOps.indexOf(op) < 0) trace("Not in specs: " + op);
		}
	}

	public function primNoop(b:Block):void { }

	private function primForLoop(b:Block):void {
		var list:Array = [];
		var loopVar:Variable;

		if (activeThread.firstTime) {
			if (!(arg(b, 0) is String)) return;
			var listArg:* = arg(b, 1);
			if (listArg is Array) {
				list = listArg as Array;
			}
			if (listArg is String) {
				var n:Number = Number(listArg);
				if (!isNaN(n)) listArg = n;
			}
			if ((listArg is Number) && !isNaN(listArg)) {
				var last:int = int(listArg);
				if (last >= 1) {
					list = new Array(last - 1);
					for (var i:int = 0; i < last; i++) list[i] = i + 1;
				}
			}
			loopVar = activeThread.target.lookupOrCreateVar(arg(b, 0));
			activeThread.args = [list, loopVar];
			activeThread.tmp = 0;
			activeThread.firstTime = false;
		}

		list = activeThread.args[0];
		loopVar = activeThread.args[1];
		if (activeThread.tmp < list.length) {
			loopVar.value = list[activeThread.tmp++];
			startCmdList(b.subStack1, true);
		} else {
			activeThread.args = null;
			activeThread.tmp = 0;
			activeThread.firstTime = true;
		}
	}

	private function primOldWarpSpeed(b:Block):void {
		// Semi-support for old warp block: run substack at normal speed.
		if (b.subStack1 == null) return;
		startCmdList(b.subStack1);
	}

	private function primRepeat(b:Block):void {
		if (activeThread.firstTime) {
			var repeatCount:Number = Math.max(0, Math.min(Math.round(numarg(b, 0)), 2147483647)); // clip to range: 0 to 2^31-1
			activeThread.tmp = repeatCount;
			activeThread.firstTime = false;
		}
		if (activeThread.tmp > 0) {
			activeThread.tmp--; // decrement count
			startCmdList(b.subStack1, true);
		} else {
			activeThread.firstTime = true;
		}
	}

	private function primStop(b:Block):void {
		var type:String = arg(b, 0);
		if (type == 'all') { app.runtime.stopAll(); yield = true }
		if (type == 'this script') primReturn(b);
		if (type == 'other scripts in sprite') stopThreadsFor(activeThread.target, true);
		if (type == 'other scripts in stage') stopThreadsFor(activeThread.target, true);
	}

	private function primWait(b:Block):void {
		if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.ArduinoMathNum = 0;
			numarg(b, 0);
			if(app.ArduinoValueFlag == true)
			{
				if(app.ArduinoLoopFlag == true)
					app.ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + app.ArduinoValueStr + ");" + '\n');
				else
					app.ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + app.ArduinoValueStr + ");" + '\n');
				app.ArduinoValueFlag = false;
			}
			else
				if(app.ArduinoMathFlag == true)
				{
					if(app.ArduinoLoopFlag == true)
						app.ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + app.ArduinoMathStr[0] + ");" + '\n');
					else
						app.ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + app.ArduinoMathStr[0] + ");" + '\n');
					app.ArduinoMathFlag = false;
				}
				else
					if(app.ArduinoReadFlag == true)
					{
						if(app.ArduinoLoopFlag == true)
							app.ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + app.ArduinoReadStr[0] + ");" + '\n');
						else
							app.ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + app.ArduinoReadStr[0] + ");" + '\n');
						app.ArduinoReadFlag = false;
					}
					else
					{
						if(app.ArduinoLoopFlag == true)
							app.ArduinoLoopFs.writeUTFBytes("delay(" + "1000*" + numarg(b, 0) + ");" + '\n');
						else
							app.ArduinoDoFs.writeUTFBytes("delay(" + "1000*" + numarg(b, 0) + ");" + '\n');
					}
		}
		else
		{
			if (activeThread.firstTime) {
				startTimer(numarg(b, 0));
				redraw();
			} else checkTimer();
		}
		
	}

	// Broadcast and scene starting

	public function broadcast(msg:String, waitFlag:Boolean):void {
		var pair:Array;
		if (activeThread.firstTime) {
			var receivers:Array = [];
			var newThreads:Array = [];
			msg = msg.toLowerCase();
			var findReceivers:Function = function (stack:Block, target:ScratchObj):void {
				if ((stack.op == "whenIReceive") && (stack.args[0].argValue.toLowerCase() == msg)) {
					receivers.push([stack, target]);
				}
			}
			app.runtime.allStacksAndOwnersDo(findReceivers);
			// (re)start all receivers
			for each (pair in receivers) newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag) return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done:Boolean = true;
		for each (var t:Thread in activeThread.tmpObj) { if (threads.indexOf(t) >= 0) done = false }
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		} else {
			yield = true;
		}
	}

	public function startScene(sceneName:String, waitFlag:Boolean):void {
		var pair:Array;
		if (activeThread.firstTime) {
			function findSceneHats(stack:Block, target:ScratchObj):void {
				if ((stack.op == "whenSceneStarts") && (stack.args[0].argValue == sceneName)) {
					receivers.push([stack, target]);
				}
			}
			var receivers:Array = [];
			app.stagePane.showCostumeNamed(sceneName);
			redraw();
			app.runtime.allStacksAndOwnersDo(findSceneHats);
			// (re)start all receivers
			var newThreads:Array = [];
			for each (pair in receivers) newThreads.push(restartThread(pair[0], pair[1]));
			if (!waitFlag) return;
			activeThread.tmpObj = newThreads;
			activeThread.firstTime = false;
		}
		var done:Boolean = true;
		for each (var t:Thread in activeThread.tmpObj) { if (threads.indexOf(t) >= 0) done = false }
		if (done) {
			activeThread.tmpObj = null;
			activeThread.firstTime = true;
		} else {
			yield = true;
		}
	}

	// Procedure call/return

	private function primCall(b:Block):void {
		// Call a procedure. Handle recursive calls and "warp" procedures.
		// The activeThread.firstTime flag is used to mark the first call
		// to a procedure running in warp mode. activeThread.firstTime is
		// false for subsequent calls to warp mode procedures.

		// Lookup the procedure and cache for future use
		var obj:ScratchObj = activeThread.target;
		var spec:String = b.spec;
		var proc:Block = obj.procCache[spec];
		if (!proc) {
			proc = obj.lookupProcedure(spec);
			obj.procCache[spec] = proc;
		}
		if (!proc) return;

		if (warpThread) {
			activeThread.firstTime = false;
			if ((currentMSecs - startTime) > warpMSecs) yield = true;
		} else {
			if (proc.warpProcFlag) {
				// Start running in warp mode.
				warpBlock = b;
				warpThread = activeThread;
				activeThread.firstTime = true;
			}
			else if (activeThread.isRecursiveCall(b, proc)) {
				yield = true;
			}
		}
		var argCount:int = proc.parameterNames.length;
		var argList:Array = [];
		for (var i:int = 0; i < argCount; ++i) argList.push(arg(b, i));
		startCmdList(proc, false, argList);
	}

	private function primReturn(b:Block):void {
		// Return from the innermost procedure. If not in a procedure, stop the thread.
		var didReturn:Boolean = activeThread.returnFromProcedure();
		if (!didReturn) {
			activeThread.stop();
			yield = true;
		}
	}

	// Variable Primitives
	// Optimization: to avoid the cost of looking up the variable every time,
	// a reference to the Variable object is cached in the target object.

	private function primVarGet(b:Block):* {
		var v:Variable = activeThread.target.varCache[b.spec];
		if (v == null) {
			v = activeThread.target.varCache[b.spec] = activeThread.target.lookupOrCreateVar(b.spec);
			if (v == null) return 0;
		}
		
		/****************************************************/
		//Arduino程序生成过程时需保持变量名称_wh
		if(app.ArduinoFlag == true)
		{
			app.ArduinoValueStr = v.name;
			app.ArduinoValueFlag = true;
		}
		/****************************************************/
		
		// XXX: Do we need a get() for persistent variables here ?
		return v.value;
	}

	protected function primVarSet(b:Block):Variable {
		var name:String = arg(b, 0);
		var v:Variable = activeThread.target.varCache[name];
		if (!v) {
			v = activeThread.target.varCache[name] = activeThread.target.lookupOrCreateVar(name);
			if (!v) return null;
			ArduinoValDefStr[ArduinoValDefi] = name;
			ArduinoValDefFlag[ArduinoValDefi] = 0;
			ArduinoValDefi ++;
		}
		var oldvalue:* = v.value;
		
		var checkvalue:*;
		checkvalue = arg(b, 1);
		if(checkvalue == undefined)
			;
		else
			if(activeThread.ArduinoNA)//加有效性判断_wh
				activeThread.ArduinoNA = false;
			else
				v.value = Number(checkvalue);
		
		/*******************************************************************************/
		if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.ArduinoMathNum = 0;
			if(ArduinoValDefFlag[ArduinoValDefStr.indexOf(name)] == 0)
			{
				app.ArduinoHeadFs.writeUTFBytes("double " + v.name + ";" + '\n');
				ArduinoValDefFlag[ArduinoValDefStr.indexOf(name)] = 1;
			}
			if(app.ArduinoReadFlag == true)
			{
				if(app.ArduinoLoopFlag == true)
				{
					app.ArduinoLoopFs.writeUTFBytes(v.name  + " = " + app.ArduinoReadStr[0] + ";" + '\n');
				}
				else
				{
					app.ArduinoDoFs.writeUTFBytes(v.name  + " = " + app.ArduinoReadStr[0] + ";" + '\n');
				}
				app.ArduinoReadFlag = false;
			}
			else
				if(app.ArduinoMathFlag == true)
				{
					if(app.ArduinoLoopFlag == true)
					{
						app.ArduinoLoopFs.writeUTFBytes(v.name  + " = " + app.ArduinoMathStr[0] + ";" + '\n');
					}
					else
					{
						app.ArduinoDoFs.writeUTFBytes(v.name  + " = " + app.ArduinoMathStr[0] + ";" + '\n');
					}
					app.ArduinoMathFlag = false;
				}
				else
					if(app.ArduinoValueFlag == true)
					{
						if(app.ArduinoLoopFlag == true)
						{
							app.ArduinoLoopFs.writeUTFBytes(v.name  + " = " + app.ArduinoValueStr + ";" + '\n');
						}
						else
						{
							app.ArduinoDoFs.writeUTFBytes(v.name  + " = " + app.ArduinoValueStr + ";" + '\n');
						}
						app.ArduinoValueFlag = false;
					}
					else
					{
						if(app.ArduinoLoopFlag == true)
							app.ArduinoLoopFs.writeUTFBytes(v.name  + " = " + v.value + ";" + '\n');
						else
							app.ArduinoDoFs.writeUTFBytes(v.name  + " = " + v.value + ";" + '\n');
					}
		}
		/*******************************************************************************/
		
		return v;
	}

	protected function primVarChange(b:Block):Variable {
		var name:String = arg(b, 0);
		var v:Variable = activeThread.target.varCache[name];
		if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
		{
			app.ArduinoMathNum = 0;
			var num:Number = numarg(b, 1);
			var strcp:String = new String();
			if(app.ArduinoValueFlag == true)
			{
				strcp = app.ArduinoValueStr;
				app.ArduinoValueFlag = false;
			}
			else
				if(app.ArduinoMathFlag == true)
				{
					strcp = app.ArduinoMathStr[0];
					app.ArduinoMathFlag = false;
				}
				else
					if(app.ArduinoReadFlag == true)
					{
						strcp = app.ArduinoReadStr[0];
						app.ArduinoReadFlag = false;
					}
					else
						strcp = num.toString();
			
			if(app.ArduinoLoopFlag == true)
				app.ArduinoLoopFs.writeUTFBytes(v.name + " += " + strcp + ";" + '\n');
			else
				app.ArduinoDoFs.writeUTFBytes(v.name + " += " + strcp + ";" + '\n');
		}
		else
		{
			if (!v) {
				v = activeThread.target.varCache[name] = activeThread.target.lookupOrCreateVar(name);
				if (!v) return null;
			}
			var checkvalue:*;
			 checkvalue = arg(b, 1);
			if(activeThread.ArduinoNA)//加有效性判断_wh
				activeThread.ArduinoNA = false;
			else
				v.value = Number(v.value) + Number(checkvalue);
		}
		return v;
	}

	private function primGetParam(b:Block):* {
		if (b.parameterIndex < 0) {
			var proc:Block = b.topBlock();
			if (proc.parameterNames) b.parameterIndex = proc.parameterNames.indexOf(b.spec);
			if (b.parameterIndex < 0) return 0;
		}
		if ((activeThread.args == null) || (b.parameterIndex >= activeThread.args.length)) return 0;
		return activeThread.args[b.parameterIndex];
	}
}}
