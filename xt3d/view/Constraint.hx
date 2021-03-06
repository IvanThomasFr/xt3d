package xt3d.view;


import xt3d.utils.XT;
import xt3d.utils.errors.XTException;
typedef ConstraintValue = {
	value: Float,
	type: Int,
}

class Constraint {


	private static inline var CONSTRAINT_TYPE_P0_L:Int = 0;
	private static inline var CONSTRAINT_TYPE_P1_L:Int = 1;
	private static inline var CONSTRAINT_TYPE_P0_P1:Int = 2;

	private static inline var VALUE_TYPE_POINT:Int = 0;
	private static inline var VALUE_TYPE_PIXEL:Int = 1;
	private static inline var VALUE_TYPE_PERCENT:Int = 2;

	// properties
	public var minorMargin(null, set):String;
	public var majorMargin(null, set):String;

	// members
	private var _p0:Float;
	private var _p0Type:Int;
	private var _p1:Float;
	private var _p1Type:Int;
	private var _l:Float;
	private var _lType:Int;
	private var _constraintType:Int = CONSTRAINT_TYPE_P0_L;

	private var _margin0:Float = 0.0;
	private var _margin0Type:Int = VALUE_TYPE_POINT;
	private var _margin1:Float = 0.0 ;
	private var _margin1Type:Int = VALUE_TYPE_POINT;

	public function initConstraint(constraintType:Int = CONSTRAINT_TYPE_P0_L, value1:String = "0pt", value2:String = "100%"):Bool {
		this._constraintType = constraintType;
		var constraintValue1:ConstraintValue = parseConstraintValue(value1);
		var constraintValue2:ConstraintValue = parseConstraintValue(value2);

		if (constraintType == CONSTRAINT_TYPE_P0_L) {
			this._p0 = constraintValue1.value;
			this._p0Type = constraintValue1.type;
			this._l = constraintValue2.value;
			this._lType = constraintValue2.type;

		} else if (constraintType == CONSTRAINT_TYPE_P1_L) {
			this._p1 = constraintValue1.value;
			this._p1Type = constraintValue1.type;
			this._l = constraintValue2.value;
			this._lType = constraintValue2.type;

		} else if (constraintType == CONSTRAINT_TYPE_P0_P1) {
			this._p0 = constraintValue1.value;
			this._p0Type = constraintValue1.type;
			this._p1 = constraintValue2.value;
			this._p1Type = constraintValue2.type;
		} else {
			throw new XTException("UnknownConstraintType", "Type constraint type is unknown : " + constraintType);
		}

		return true;
	}


	public function new() {

	}


	/* ----------- Properties ----------- */

	function set_minorMargin(value:String) {
		this.setMinorMargin(value);
		return value;
	}

	function set_majorMargin(value:String) {
		this.setMajorMargin(value);
		return value;
	}


	/* --------- Implementation --------- */


	public function getOriginInPoints(fullLengthInPoints:Int, contentScaleFactor:Float):Int {
		var p0InPoints:Float = 0.0;
		var lengthInPoints:Float;
		if (this._constraintType == CONSTRAINT_TYPE_P0_L) {
			p0InPoints = this.convertToPoints(this._p0, this._p0Type, fullLengthInPoints, contentScaleFactor);
			lengthInPoints = this.convertToPoints(this._l, this._lType, fullLengthInPoints, contentScaleFactor);

		} else if (this._constraintType == CONSTRAINT_TYPE_P0_P1) {
			p0InPoints = this.convertToPoints(this._p0, this._p0Type, fullLengthInPoints, contentScaleFactor);
			var p1InPoints = this.convertToPoints(this._p1, this._p1Type, fullLengthInPoints, contentScaleFactor);

			lengthInPoints = fullLengthInPoints - p0InPoints - p1InPoints;

		} else if (this._constraintType == CONSTRAINT_TYPE_P1_L) {
			var p1InPoints = this.convertToPoints(this._p1, this._p1Type, fullLengthInPoints, contentScaleFactor);
			lengthInPoints = this.convertToPoints(this._l, this._lType, fullLengthInPoints, contentScaleFactor);

			p0InPoints = fullLengthInPoints - p1InPoints - lengthInPoints;

		} else {
			return 0;
		}

		// Add on minor margin to origin
		var margin0InPoints = this.convertToPoints(this._margin0, this._margin0Type, lengthInPoints, contentScaleFactor);

		return Std.int(p0InPoints + margin0InPoints);
	}

	public function getLengthInPoints(fullLengthInPoints:Int, contentScaleFactor:Float):Int {
		var constraintLengthInPoints:Float;
		if (this._constraintType == CONSTRAINT_TYPE_P0_L || this._constraintType == CONSTRAINT_TYPE_P1_L) {
			constraintLengthInPoints = this.convertToPoints(this._l, this._lType, fullLengthInPoints, contentScaleFactor);

		} else if (this._constraintType == CONSTRAINT_TYPE_P0_P1) {
			var p0InPoints = this.convertToPoints(this._p0, this._p0Type, fullLengthInPoints, contentScaleFactor);
			var p1InPoints = this.convertToPoints(this._p1, this._p1Type, fullLengthInPoints, contentScaleFactor);

			constraintLengthInPoints = fullLengthInPoints - (p1InPoints + p0InPoints);

		} else {
			return 0;
		}

		// Remove margin from length
		var margin0InPoints = this.convertToPoints(this._margin0, this._margin0Type, constraintLengthInPoints, contentScaleFactor);
		var margin1InPoints = this.convertToPoints(this._margin1, this._margin1Type, constraintLengthInPoints, contentScaleFactor);
		constraintLengthInPoints = constraintLengthInPoints - margin0InPoints - margin1InPoints;

		return Std.int(constraintLengthInPoints);
	}

	public function setMinorMargin(value:String):Void {
		var constraintValue:ConstraintValue = parseConstraintValue(value);
		this._margin0 = constraintValue.value;
		this._margin0Type = constraintValue.type;
	}

	public function setMajorMargin(value:String):Void {
		var constraintValue:ConstraintValue = parseConstraintValue(value);
		this._margin1 = constraintValue.value;
		this._margin1Type = constraintValue.type;
	}

	private function parseConstraintValue(value:String):ConstraintValue {
		var valueLength = value.length;

		// Get the type : default points
		var type = VALUE_TYPE_POINT;
		if (value.lastIndexOf("px") == valueLength - 2) {
			type = VALUE_TYPE_PIXEL;
			valueLength -= 2;

		} else if (value.lastIndexOf("pt") == valueLength - 2) {
			type = VALUE_TYPE_POINT;
			valueLength -= 2;

		} else if (value.lastIndexOf("%") == valueLength - 1) {
			type = VALUE_TYPE_PERCENT;
			valueLength -= 1;
		}

		// Get the value
		var floatValue = Std.parseFloat(value.substr(0, valueLength));
		if (Math.isNaN(floatValue)) {
			throw new XTException("UnableToParseConstraintValue", "Could not parse the constraint value " + value);
		}

		return {
			value: floatValue,
			type: type
		};
	}

	private function convertToPoints(value:Float, valueType:Int, fullLengthInPoints:Float, contentScaleFactor:Float):Float {
		if (valueType == VALUE_TYPE_POINT) {
			return value;

		} else if (valueType == VALUE_TYPE_PIXEL) {
			return value / contentScaleFactor;

		} else if (valueType == VALUE_TYPE_PERCENT) {
			return fullLengthInPoints * value / 100.0;
		}

		return 0;
	}
}
