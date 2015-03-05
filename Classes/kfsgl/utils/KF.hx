package kfsgl.utils;

import haxe.Timer;

class KF  {

	private static var timer:Float = Timer.stamp();

	public static function Log(v:Dynamic, ?info:haxe.PosInfos):Void {
#if KF_DEBUG
		var ms = (Std.int)((Timer.stamp() - timer) * 1000) % 1000;
		haxe.Log.trace(DateTools.format(Date.now(), "%d/%m/%Y %H:%M:%S") + "." + ms + ": " + v, info);
#else
		// Do nothing
#end		
	}
	

	public static function jsonToMap(jsonData:Dynamic):Map<String, String> {
		var result = new Map<String, String>();

		for (key in Reflect.fields(jsonData)) {
			var value = Reflect.getProperty(jsonData, key);
			result.set(key, value);
		}

		return result;
	}

}
