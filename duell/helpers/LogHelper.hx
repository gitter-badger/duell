/**
 * @autor rcam
 * @date 15.07.2014.
 * @company Gameduell GmbH
 */
 
package duell.helpers;

import duell.helpers.PlatformHelper;

import neko.Lib;
import haxe.io.Bytes;
import sys.io.Process;

class LogHelper 
{		
	public static var enableColor : Bool = Sys.args().indexOf("-nocolor") == -1;
	public static var mute : Bool = Sys.args().indexOf("-mute") != -1;
	public static var verbose : Bool = Sys.args().indexOf("-verbose") != -1;
	
	private static var colorCodes : EReg = ~/\x1b\[[^m]+m/g;
	private static var colorSupported : Null<Bool>;
	private static var sentWarnings : Map<String, Bool> = new Map<String, Bool>();
	
	public static function error(message : String, verboseMessage : String = "", e : Dynamic = null) : Void 
	{	
		if (message != "" && !mute)
		{
			var output;
			if(verbose && verboseMessage != "") 
			{	
				output = "\x1b[31;1mError:\x1b[0m\x1b[1m " + verboseMessage + "\x1b[0m\n";	
			} 
			else
			{	
				output = "\x1b[31;1mError:\x1b[0m \x1b[1m" + message + "\x1b[0m\n";	
			}
			
			Sys.stderr().write(Bytes.ofString(stripColor(output)));
		}
		
		if(verbose && e != null) 
		{
			Lib.rethrow(e);	
		}
		
		Sys.exit (1);
	}
	
	public static function info(message : String, verboseMessage : String = "") : Void 
	{
		if (!mute) 
		{
			if (verbose && verboseMessage != "") 
			{
				println (verboseMessage);
			} 
			else if (message != "") 
			{
				println (message);
			}
		}
	}

	public static function print(message : String) : Void 
	{	
		Sys.print(stripColor(message));	
	}
	
	public static function println(message : String) : Void 
	{
		Sys.println(stripColor(message));
	}
	
	public static function warn(message : String, verboseMessage : String = "", allowRepeat : Bool = false) : Void 
	{
		if(!mute) 
		{
			var output = "";
			
			if (verbose && verboseMessage != "")
			{
				output = "\x1b[33;1mWarning:\x1b[0m \x1b[1m" + verboseMessage + "\x1b[0m";
				
			} 
			else if (message != "")
			{
				output = "\x1b[33;1mWarning:\x1b[0m \x1b[1m" + message + "\x1b[0m";
			}
			
			if (!allowRepeat && sentWarnings.exists(output)) 
				return;
			
			sentWarnings.set (output, true);
			println (output);
		}
	}

	private static function stripColor(output : String) : String 
	{	
		if (colorSupported == null) 
		{
			if (PlatformHelper.hostPlatform != Platform.WINDOWS) 
			{
				var result = -1;
				
				try {
					var process = new Process("tput", [ "colors" ]);
					result = process.exitCode();
					process.close();
				
				} catch (e:Dynamic) {};
				
				colorSupported = (result == 0);
			} 
			else 
			{
				colorSupported = (Sys.getEnv("ANSICON") != null);
			}
			
		}
		
		if (enableColor && colorSupported) 
			return output;
		else 
			return colorCodes.replace (output, "");
	}
}
