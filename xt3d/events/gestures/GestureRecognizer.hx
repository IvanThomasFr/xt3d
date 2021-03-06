package xt3d.events.gestures;

import xt3d.core.Director;
import xt3d.node.Node3D;
import lime.math.Vector2;
import lime.ui.Touch;

class GestureRecognizer extends Node3D {

	// properties

	// members


	public function new() {
		super();
	}

	override public function onEnter() {
		super.onEnter();

		Director.current.gestureDispatcher.addGestureRecognizer(this);
	}

	override public function onExit() {
		super.onExit();

		Director.current.gestureDispatcher.removeGestureRecognizer(this);
	}

	/* ----------- Properties ----------- */

	/* --------- Implementation --------- */

	public function onGestureClaimed():Void {
	}

	public function onMouseDown (x:Float, y:Float, button:Int):Bool {
		return false;
	}

	public function onMouseMove (x:Float, y:Float):Bool {
		return false;
	}

	public function onMouseUp (x:Float, y:Float, button:Int):Bool {
		return false;
	}

	public function onMouseWheel (deltaX:Float, deltaY:Float):Bool {
		return false;
	}

	public function onTouchStart (touch:Touch):Bool {
		return false;
	}

	public function onTouchEnd (touch:Touch):Bool {
		return false;
	}

	public function onTouchMove (touch:Touch):Bool {
		return false;
	}


	private function distanceBetweenPoints(p1:Vector2, p2:Vector2):Float {
		var deltaX = p2.x - p1.x;
		var deltaY = p2.y - p1.y;
		return Math.sqrt(deltaX * deltaX + deltaY * deltaY);
	}

}
