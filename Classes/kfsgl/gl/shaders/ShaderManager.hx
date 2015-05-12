package kfsgl.gl.shaders;

import kfsgl.gl.GLTextureManager;
import kfsgl.gl.KFGL;
import kfsgl.gl.KFGL;
import openfl.gl.GL;
import openfl.gl.GLShaderPrecisionFormat;
import kfsgl.gl.shaders.ShaderProgram;
import kfsgl.gl.shaders.ShaderLib;
import kfsgl.utils.errors.KFException;
import kfsgl.utils.KF;

class ShaderManager {


	private var _programs:Map<String,  ShaderProgram>;

	private static var _instance:ShaderManager = null;

	private var _desiredPrecision:String = KFGL.MEDIUM_PRECISION;
	private var _precision:String;
	private var _highPrecisionAvailable:Bool = true;
	private var _mediumPrecisionAvailable:Bool = true;
	private var _precisionAvailable:Bool = true;

	public static function instance():ShaderManager {
		if (_instance == null) {
			_instance = new ShaderManager();
			_instance.init();
		}

		return _instance;
	}

	private function new() {
	}

	private function init():Void {
		_programs = new Map<String, ShaderProgram>();

		// Get available precisions
		var vertexShaderPrecisionHighpFloat:GLShaderPrecisionFormat = GL.getShaderPrecisionFormat(GL.VERTEX_SHADER, GL.HIGH_FLOAT);
		var vertexShaderPrecisionMediumpFloat:GLShaderPrecisionFormat = GL.getShaderPrecisionFormat(GL.VERTEX_SHADER, GL.MEDIUM_FLOAT);
		var fragmentShaderPrecisionHighpFloat:GLShaderPrecisionFormat = GL.getShaderPrecisionFormat(GL.FRAGMENT_SHADER, GL.HIGH_FLOAT);
		var fragmentShaderPrecisionMediumpFloat:GLShaderPrecisionFormat = GL.getShaderPrecisionFormat(GL.FRAGMENT_SHADER, GL.MEDIUM_FLOAT);

		if (vertexShaderPrecisionHighpFloat != null) {
			this._highPrecisionAvailable = (vertexShaderPrecisionHighpFloat.precision > 0 && fragmentShaderPrecisionHighpFloat.precision > 0);
			this._mediumPrecisionAvailable = (vertexShaderPrecisionMediumpFloat.precision > 0 && fragmentShaderPrecisionMediumpFloat.precision > 0);

		} else {
			this._precisionAvailable = false;
		}

		// Set max precision (compared to desired precision) in shader lib
		this.setShaderPrecision(this._desiredPrecision);
	}

	public function setShaderPrecision(precision:String):Void {
		this._desiredPrecision = precision;
		if (this._precisionAvailable) {
			this._precision = precision;
			if (precision == KFGL.HIGH_PRECISION && !this._highPrecisionAvailable) {
				if (this._mediumPrecisionAvailable) {
					this._precision = KFGL.MEDIUM_PRECISION;
					KF.Warn("high precision not supported, reverting to medium precision");

				} else {
					this._precision = KFGL.LOW_PRECISION;
					KF.Warn("high precision not supported, reverting to low precision");
				}
			} else if (precision == KFGL.MEDIUM_PRECISION && !this._mediumPrecisionAvailable) {
				this._precision = KFGL.LOW_PRECISION;
				KF.Warn("medium precision not supported, reverting to low precision");
			}
		} else {
			this._precision = null;
		}
	}

	public function purgeShaders():Void {
		var keys = _programs.keys();
		while (keys.hasNext()) {
			var key = keys.next();
			var program = _programs.get(key);

			// destroy program
			program.dispose();

			// Remove program for map
			_programs.remove(key);

		}
	}

	public function loadDefaultShaders(textureManager:GLTextureManager):Void {
		// Get all shader configs
		var shaderConfigs = ShaderLib.instance().shaderConfigs;

		// Iterate over all shaders
		var shaderNames = shaderConfigs.keys();
		while (shaderNames.hasNext()) {
			var shaderName = shaderNames.next();
			var shaderInfo = shaderConfigs.get(shaderName);

			// Create program for each shader
			var program = ShaderProgram.create(shaderName, shaderInfo, this._precision, textureManager.maxTextureSlots);

			// Verify program
			if (program != null) {
				// Add program to map
				this.addProgramWithName(shaderName, program);

			} else {
				throw new KFException("UnableToCreateProgram", "The shader program \"" + shaderName + "\" did not compile");
			}
		}
	}
	
	public function addProgramWithName(name:String, program:ShaderProgram):Void {
		// Verify that a program doesn't already exist for the given name
		if (_programs.exists(name)) {
			throw new KFException("ProgramAlreadyExists", "A shader program with the name \"" + name + "\" already exists");
		}

		// Verify that program is not null
		if (program == null) {
			throw new KFException("ProgramIsNull", "The shader program with the name \"" + name + "\" is null when added");
		}

		// Add the program
		_programs.set(name, program);

		//KF.Log("Added shader program \"" + name + "\"");
	}

	public function programWithName(name:String):ShaderProgram {
		var program = _programs.get(name);
		if (program == null) {
			throw new KFException("NoProgramExistsForKey", "No shader program exists with the name \"" + name + "\"");
		}

		return program;
	}
	

}