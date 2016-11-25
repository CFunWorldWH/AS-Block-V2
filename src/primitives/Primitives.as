﻿/*
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

// Primitives.as
// John Maloney, April 2010
//
// Miscellaneous primitives. Registers other primitive modules.
// Note: A few control structure primitives are implemented directly in Interpreter.as.

package primitives {
	import flash.utils.Dictionary;
	import blocks.*;
	import interpreter.*;
	import scratch.ScratchSprite;
	import translation.Translator;
	import uiwidgets.DialogBox;

public class Primitives {

	private const MaxCloneCount:int = 300;

	protected var app:Scratch;
	protected var interp:Interpreter;
	private var counter:int;

	public function Primitives(app:Scratch, interpreter:Interpreter) {
		this.app = app;
		this.interp = interpreter;
	}

	public function addPrimsTo(primTable:Dictionary):void {
		// operators
		primTable["+"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.numarg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") + (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") + (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") + (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") + (";
															app.ArduinoMathNum ++;
															interp.numarg(b, 1);
															app.ArduinoMathNum --;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
															
														}
														else
															return interp.numarg(b, 0) + interp.numarg(b, 1)
													};
		primTable["-"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.numarg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") - (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") - (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") - (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") - (";
															app.ArduinoMathNum ++;
															interp.numarg(b, 1);
															app.ArduinoMathNum --;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
														}
														else
															return interp.numarg(b, 0) - interp.numarg(b, 1)
													};
		primTable["*"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.numarg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") * (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") * (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") * (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") * (";
															app.ArduinoMathNum++;
															interp.numarg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
														}
														else
															return interp.numarg(b, 0) * interp.numarg(b, 1)
													};
		primTable["/"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.numarg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(double)(" + app.ArduinoReadStr[0] + ") / (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(double)(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") / (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(double)(" + app.ArduinoValueStr + ") / (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(double)(" + interp.numarg(b, 0) + ") / (";
															app.ArduinoMathNum++;
															interp.numarg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
														}
														else
															return interp.numarg(b, 0) / interp.numarg(b, 1)
													};
		primTable["randomFrom:to:"]	= function(b:*):* {
																if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
																{
																	app.ArduinoMathNum++;
																	interp.numarg(b, 0);
																	app.ArduinoMathNum--;
																	if(app.ArduinoReadFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "random(" + app.ArduinoReadStr[0] + ",";
																		app.ArduinoReadFlag = false;
																	}
																	else
																		if(app.ArduinoMathFlag == true)
																		{
																			app.ArduinoMathStr[app.ArduinoMathNum] = "random(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ",";
																			app.ArduinoMathFlag = false;
																		}
																		else
																			if(app.ArduinoValueFlag == true)
																			{
																				app.ArduinoMathStr[app.ArduinoMathNum] = "random(" + app.ArduinoValueStr + ",";
																				app.ArduinoValueFlag = false;
																			}
																			else
																				app.ArduinoMathStr[app.ArduinoMathNum] = "random(" + interp.numarg(b, 0) + ",";
																	app.ArduinoMathNum++;
																	interp.numarg(b, 1);
																	app.ArduinoMathNum--;
																	if(app.ArduinoReadFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + ")";
																		app.ArduinoReadFlag = false;
																	}
																	else
																		if(app.ArduinoMathFlag == true)
																		{
																			app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
																			app.ArduinoMathFlag = false;
																		}
																		else
																			if(app.ArduinoValueFlag == true)
																			{
																				app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + ")";
																				app.ArduinoValueFlag = false;
																			}
																			else
																				app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + ")";
																	app.ArduinoMathFlag = true;
																}
																else
																	return primRandom(b);
															}
		primTable["<"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.arg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") < (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") < (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") < (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") < (";
															app.ArduinoMathNum++;
															interp.arg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
														}
														else
															return compare(interp.arg(b, 0), interp.arg(b, 1)) < 0
													};
		primTable["="]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.arg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") == (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") == (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") == (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") == (";
															app.ArduinoMathNum++;
															interp.arg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
														}
														else
															return compare(interp.arg(b, 0), interp.arg(b, 1)) == 0
													};
		primTable[">"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.arg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") > (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") > (";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") > (";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") > (";
															app.ArduinoMathNum++;
															interp.arg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
																else
																	if(app.ArduinoValueFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																		app.ArduinoValueFlag = false;
																	}
																	else
																		app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
															app.ArduinoMathFlag = true;
														}
														else
															return compare(interp.arg(b, 0), interp.arg(b, 1)) > 0
													};
		primTable["&"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.arg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") && (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") && (";
																	app.ArduinoMathFlag = false;
																}
															app.ArduinoMathNum++;
															interp.arg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
															app.ArduinoMathFlag = true;
														}
														else
															return interp.arg(b, 0) && interp.arg(b, 1)
													};
		primTable["|"]				= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.arg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") || (";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") || (";
																	app.ArduinoMathFlag = false;
																}
															app.ArduinoMathNum++;
															interp.arg(b, 1);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																	app.ArduinoMathFlag = false;
																}
															app.ArduinoMathFlag = true;
														}
														else
															return interp.arg(b, 0) || interp.arg(b, 1)
													};
		primTable["not"]			= function(b:*):*
													{
														if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
														{
															app.ArduinoMathNum++;
															interp.arg(b, 0);
															app.ArduinoMathNum--;
															if(app.ArduinoReadFlag == true)
															{
																app.ArduinoMathStr[app.ArduinoMathNum] = "!(" + app.ArduinoReadStr[0] + ")";
																app.ArduinoReadFlag = false;
															}
															else
																if(app.ArduinoMathFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "!(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
																	app.ArduinoMathFlag = false;
																}
															app.ArduinoMathFlag = true;
														}
														else
															return !interp.arg(b, 0)
													};
		
		primTable["abs"]			= function(b:*):* { return Math.abs(interp.numarg(b, 0)) };
		primTable["sqrt"]			= function(b:*):* { return Math.sqrt(interp.numarg(b, 0)) };


		primTable["concatenate:with:"]	= function(b:*):*
															{
																if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
																{
																	DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("jion ... ..."), null, app.stage);//软件界面中部显示提示框_wh
																}
																else
																	return ("" + interp.arg(b, 0) + interp.arg(b, 1)).substr(0, 10240)
															};
		primTable["letter:of:"]			= function(b:*):*
															{
																if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
																{
																	DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("letter ...of ..."), null, app.stage);//软件界面中部显示提示框_wh
																}
																else
																	return primLetterOf(b)
															};
		primTable["stringLength:"]		= function(b:*):*
		{
			if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
			{
				DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("length of ..."), null, app.stage);//软件界面中部显示提示框_wh
			}
			else
				return String(interp.arg(b, 0)).length
		};

		primTable["%"]					= function(b:*):*
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																app.ArduinoMathNum++;
																interp.numarg(b, 0);
																app.ArduinoMathNum--;
																if(app.ArduinoReadFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoReadStr[0] + ") % (";
																	app.ArduinoReadFlag = false;
																}
																else
																	if(app.ArduinoMathFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ") % (";
																		app.ArduinoMathFlag = false;
																	}
																	else
																		if(app.ArduinoValueFlag == true)
																		{
																			app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + app.ArduinoValueStr + ") % (";
																			app.ArduinoValueFlag = false;
																		}
																		else
																			app.ArduinoMathStr[app.ArduinoMathNum] = "(" + "(" + interp.numarg(b, 0) + ") % (";
																app.ArduinoMathNum++;
																interp.numarg(b, 1);
																app.ArduinoMathNum--;
																if(app.ArduinoReadFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoReadStr[0] + "))";
																	app.ArduinoReadFlag = false;
																}
																else
																	if(app.ArduinoMathFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoMathStr[app.ArduinoMathNum+1] + "))";
																		app.ArduinoMathFlag = false;
																	}
																	else
																		if(app.ArduinoValueFlag == true)
																		{
																			app.ArduinoMathStr[app.ArduinoMathNum] += app.ArduinoValueStr + "))";
																			app.ArduinoValueFlag = false;
																		}
																		else
																			app.ArduinoMathStr[app.ArduinoMathNum] += interp.numarg(b, 1) + "))";
																app.ArduinoMathFlag = true;
															}
															else
																return primModulo(b)
														};
		primTable["rounded"]			= function(b:*):*
														{ 
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																app.ArduinoMathNum++;
																interp.numarg(b, 0);
																app.ArduinoMathNum--;
																if(app.ArduinoReadFlag == true)
																{
																	app.ArduinoMathStr[app.ArduinoMathNum] = "round(" + app.ArduinoReadStr[0] + ")";
																	app.ArduinoReadFlag = false;
																}
																else
																	if(app.ArduinoMathFlag == true)
																	{
																		app.ArduinoMathStr[app.ArduinoMathNum] = "round(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
																		app.ArduinoMathFlag = false;
																	}
																	else
																		if(app.ArduinoValueFlag == true)
																		{
																			app.ArduinoMathStr[app.ArduinoMathNum] = "round(" + app.ArduinoValueStr + ")";
																			app.ArduinoValueFlag = false;
																		}
																		else
																			app.ArduinoMathStr[app.ArduinoMathNum] = "round(" + interp.numarg(b, 0) + ")";
																app.ArduinoMathFlag = true;
															}
															else
																return Math.round(interp.numarg(b, 0))
														};
		primTable["computeFunction:of:"] = primMathFunction;

		// clone
		primTable["createCloneOf"]		=  function(b:*):*
															{
																if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
																{
																	DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("create clone ..."), null, app.stage);//软件界面中部显示提示框_wh
																}
																else
																	primCreateCloneOf(b);
															}
		primTable["deleteClone"]		= function(b:*):*
														{
															if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
															{
																DialogBox.warnconfirm(Translator.map("can't support this block,please remove it"),Translator.map("delete clone"), null, app.stage);//软件界面中部显示提示框_wh
															}
															else
																primDeleteClone(b);
														}
		primTable["whenCloned"]			= interp.primNoop;

		// testing (for development)
		primTable["NOOP"]				= interp.primNoop;
		primTable["COUNT"]				= function(b:*):* { return counter };
		primTable["INCR_COUNT"]			= function(b:*):* { counter++ };
		primTable["CLR_COUNT"]			= function(b:*):* { counter = 0 };

		new LooksPrims(app, interp).addPrimsTo(primTable);
		new MotionAndPenPrims(app, interp).addPrimsTo(primTable);
		new SoundPrims(app, interp).addPrimsTo(primTable);
		new VideoMotionPrims(app, interp).addPrimsTo(primTable);
		new CFunPrims(app, interp).addPrimsTo(primTable);//此处新建类后才能添加积木模块_wh
		addOtherPrims(primTable);
	}

	protected function addOtherPrims(primTable:Dictionary):void {
		new SensingPrims(app, interp).addPrimsTo(primTable);
		new ListPrims(app, interp).addPrimsTo(primTable);
	}

	private function primRandom(b:Block):Number {
		var n1:Number = interp.numarg(b, 0);
		var n2:Number = interp.numarg(b, 1);
		var low:Number = (n1 <= n2) ? n1 : n2;
		var hi:Number = (n1 <= n2) ? n2 : n1;
		if (low == hi) return low;
		// if both low and hi are ints, truncate the result to an int
		if ((int(low) == low) && (int(hi) == hi)) {
			return low + int(Math.random() * ((hi + 1) - low));
		}
		return (Math.random() * (hi - low)) + low;
	}

	private function primLetterOf(b:Block):String {
		var s:String = interp.arg(b, 1);
		var i:int = interp.numarg(b, 0) - 1;
		if ((i < 0) || (i >= s.length)) return "";
		return s.charAt(i);
	}

	private function primModulo(b:Block):Number {
		var n:Number = interp.numarg(b, 0);
		var modulus:Number = interp.numarg(b, 1);
		var result:Number = n % modulus;
		if (result / modulus < 0) result += modulus;
		return result;
	}

	private function primMathFunction(b:Block):Number {
		var op:* = interp.arg(b, 0);
		app.ArduinoMathNum++;
		var n:Number = interp.numarg(b, 1);
		app.ArduinoMathNum--;
		switch(op) {
		case "abs":
		{
			if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
			{
				if(app.ArduinoReadFlag == true)
				{
					app.ArduinoMathStr[app.ArduinoMathNum] = "abs(" + app.ArduinoReadStr[0] + ")";
					app.ArduinoReadFlag = false;
				}
				else
					if(app.ArduinoMathFlag == true)
					{
						app.ArduinoMathStr[app.ArduinoMathNum] = "abs(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
						app.ArduinoMathFlag = false;
					}
					else
						if(app.ArduinoValueFlag == true)
						{
							app.ArduinoMathStr[app.ArduinoMathNum] = "abs(" + app.ArduinoValueStr + ")";
							app.ArduinoValueFlag = false;
						}
						else
							app.ArduinoMathStr[app.ArduinoMathNum] = "abs(" + n + ")";
				app.ArduinoMathFlag = true; 
			}
			else
				return Math.abs(n);
		}
		case "floor":
		{
			if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
			{
				if(app.ArduinoReadFlag == true)
				{
					app.ArduinoMathStr[app.ArduinoMathNum] = "floor(" + app.ArduinoReadStr[0] + ")";
					app.ArduinoReadFlag = false;
				}
				else
					if(app.ArduinoMathFlag == true)
					{
						app.ArduinoMathStr[app.ArduinoMathNum] = "floor(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
						app.ArduinoMathFlag = false;
					}
					else
						if(app.ArduinoValueFlag == true)
						{
							app.ArduinoMathStr[app.ArduinoMathNum] = "floor(" + app.ArduinoValueStr + ")";
							app.ArduinoValueFlag = false;
						}
						else
							app.ArduinoMathStr[app.ArduinoMathNum] = "floor(" + n + ")";
				app.ArduinoMathFlag = true; 
			}
			else
				return Math.floor(n);
		}
		case "ceiling":
		{
			if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
			{
				if(app.ArduinoReadFlag == true)
				{
					app.ArduinoMathStr[app.ArduinoMathNum] = "ceil(" + app.ArduinoReadStr[0] + ")";
					app.ArduinoReadFlag = false;
				}
				else
					if(app.ArduinoMathFlag == true)
					{
						app.ArduinoMathStr[app.ArduinoMathNum] = "ceil(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
						app.ArduinoMathFlag = false;
					}
					else
						if(app.ArduinoValueFlag == true)
						{
							app.ArduinoMathStr[app.ArduinoMathNum] = "ceil(" + app.ArduinoValueStr + ")";
							app.ArduinoValueFlag = false;
						}
						else
							app.ArduinoMathStr[app.ArduinoMathNum] = "ceil(" + n + ")";
				app.ArduinoMathFlag = true; 
			}
			else
				return Math.ceil(n);
		}
		case "int": return n - (n % 1); // used during alpha, but removed from menu
		case "sqrt":
		{
			if(app.ArduinoFlag == true)//判断是否为Arduino语句生成过程_wh
			{
				if(app.ArduinoReadFlag == true)
				{
					app.ArduinoMathStr[app.ArduinoMathNum] = "sqrt(" + app.ArduinoReadStr[0] + ")";
					app.ArduinoReadFlag = false;
				}
				else
					if(app.ArduinoMathFlag == true)
					{
						app.ArduinoMathStr[app.ArduinoMathNum] = "sqrt(" + app.ArduinoMathStr[app.ArduinoMathNum+1] + ")";
						app.ArduinoMathFlag = false;
					}
					else
						if(app.ArduinoValueFlag == true)
						{
							app.ArduinoMathStr[app.ArduinoMathNum] = "sqrt(" + app.ArduinoValueStr + ")";
							app.ArduinoValueFlag = false;
						}
						else
							app.ArduinoMathStr[app.ArduinoMathNum] = "sqrt(" + n + ")";
				app.ArduinoMathFlag = true; 
			}
			else
				return Math.sqrt(n);
		}
		case "sin": return Math.sin((Math.PI * n) / 180);
		case "cos": return Math.cos((Math.PI * n) / 180);
		case "tan": return Math.tan((Math.PI * n) / 180);
		case "asin": return (Math.asin(n) * 180) / Math.PI;
		case "acos": return (Math.acos(n) * 180) / Math.PI;
		case "atan": return (Math.atan(n) * 180) / Math.PI;
		case "ln": return Math.log(n);
		case "log": return Math.log(n) / Math.LN10;
		case "e ^": return Math.exp(n);
		case "10 ^": return Math.exp(n * Math.LN10);
		}
		return 0;
	}

	private static var lcDict:Dictionary = new Dictionary();
	public static function compare(a1:*, a2:*):int {
		// This is static so it can be used by the list "contains" primitive.
		var n1:Number = Interpreter.asNumber(a1);
		var n2:Number = Interpreter.asNumber(a2);
		if (isNaN(n1) || isNaN(n2)) {
			// at least one argument can't be converted to a number: compare as strings
			var s1:String = lcDict[a1];
			if(!s1) s1 = lcDict[a1] = String(a1).toLowerCase();
			var s2:String = lcDict[a2];
			if(!s2) s2 = lcDict[a2] = String(a2).toLowerCase();
			return s1.localeCompare(s2);
		} else {
			// compare as numbers
			if (n1 < n2) return -1;
			if (n1 == n2) return 0;
			if (n1 > n2) return 1;
		}
		return 1;
	}

	private function primCreateCloneOf(b:Block):void {
		var objName:String = interp.arg(b, 0);
		var proto:ScratchSprite = app.stagePane.spriteNamed(objName);
		if ('_myself_' == objName) proto = interp.activeThread.target;
		if (!proto) return;
		if (app.runtime.cloneCount > MaxCloneCount) return;
		var clone:ScratchSprite = new ScratchSprite();
		if (proto.parent == app.stagePane)
			app.stagePane.addChildAt(clone, app.stagePane.getChildIndex(proto));
		else
			app.stagePane.addChild(clone);

		clone.initFrom(proto, true);
		clone.objName = proto.objName;
		clone.isClone = true;
		for each (var stack:Block in clone.scripts) {
			if (stack.op == "whenCloned") {
				interp.startThreadForClone(stack, clone);
			}
		}
		app.runtime.cloneCount++;
	}

	private function primDeleteClone(b:Block):void {
		var clone:ScratchSprite = interp.targetSprite();
		if ((clone == null) || (!clone.isClone) || (clone.parent == null)) return;
		if (clone.bubble && clone.bubble.parent) clone.bubble.parent.removeChild(clone.bubble);
		clone.parent.removeChild(clone);
		app.interp.stopThreadsFor(clone);
		app.runtime.cloneCount--;
	}

}}
