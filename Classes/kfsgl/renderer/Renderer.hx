package kfsgl.renderer;

import kfsgl.utils.gl.GLTextureManager;
import kfsgl.utils.gl.GLBufferManager;
import kfsgl.utils.gl.GLAttributeManager;
import kfsgl.utils.gl.GLStateManager;
import kfsgl.renderer.shaders.ShaderProgram;
import kfsgl.renderer.shaders.UniformLib;
import openfl.geom.Matrix3D;
import kfsgl.utils.Color;
import kfsgl.utils.gl.KFGL;
import kfsgl.renderer.shaders.ShaderManager;
import kfsgl.core.Camera;
import kfsgl.core.Material;
import kfsgl.node.Scene;
import kfsgl.node.RenderObject;
import openfl.gl.GL;
import openfl.geom.Rectangle;



class Renderer {

	// properties
	public var textureManager(get, null):GLTextureManager;


	// members
	private var _stateManager:GLStateManager;
	private var _bufferManager:GLBufferManager;
	private var _attributeManager:GLAttributeManager;
	private var _textureManager:GLTextureManager;
	private var _needsStateInit:Bool = true;

	private var _viewport:Rectangle;
	private var _viewProjectionMatrix = new Matrix3D();

	private var _currentProgram:ShaderProgram = null;
	private var _currentMaterial:Material = null;
	private var _renderPassShaders:Map<String, ShaderProgram> = null;

	public static function create():Renderer {
		var object = new Renderer();

		if (object != null && !(object.init())) {
			object = null;
		}

		return object;
	}

	public function init():Bool {

		this._stateManager = GLStateManager.create();
		this._bufferManager = GLBufferManager.create();
		this._attributeManager = GLAttributeManager.create();
		this._textureManager = GLTextureManager.create();

		// Build all shaders
		ShaderManager.instance().loadDefaultShaders(this._textureManager);

		return true;
	}


	public function new() {
	}


	// Properties

	public function get_textureManager():GLTextureManager {
		return this._textureManager;
	}


// Implementation

	public function clear(viewport:Rectangle, color:Color) {
		// Set the viewport
		if (_viewport == null || !_viewport.equals(viewport)) {
			_viewport = viewport;
			GL.viewport(Std.int (_viewport.x), Std.int (_viewport.y), Std.int (_viewport.width), Std.int (_viewport.height));
			//KF.Log("Setting viewport to " + Std.int (_viewport.x) + ", " + Std.int (_viewport.y) + ", " + Std.int (_viewport.width) + ", " + Std.int (_viewport.height));
		}

		// Clear color
		GL.clearColor(color.red, color.green, color.blue, 1.0);

		// clear buffer bits
		GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT);
	}


	public function render(scene:Scene, camera:Camera) {

		// Not great... can only set the default here ? Not before the first render ?
		if (this._needsStateInit) {
			this._stateManager.setDefaultGLState();
			this._needsStateInit = false;
		}

		if (scene != null && camera != null) {

			// Update world matrices of scene graph
			scene.updateWorldMatrix();

			// Make sure camera matrix is updated even if it has not been added to the scene
			if (camera.parent == null) {
				camera.updateWorldMatrix();
			}

			// Update objects - anything that needs to be done before rendering
			scene.updateObjects(scene);

			// Project objects if we want to sort them in z

			// Sort transparent objects


			// Send custom-pre-render-pass event

			// Render opaque objects
			_stateManager.setBlending(KFGL.NoBlending);
			this.renderObjects(scene.opaqueObjects, camera/*, scene.lights*/, false/*, overrideMaterial*/);

			// Render transparent objects
			this.renderObjects(scene.transparentObjects, camera/*, scene.lights*/, true/*, overrideMaterial*/);

			// Prepare objects for the next frame
			scene.prepareObjectForNextFrame();

			// Prepare all common uniforms too
			UniformLib.instance().prepareUniforms();

			// Send custom-post-render-pass event
		}
	}

	/**
	 * Render list of objects
	 **/
	public function renderObjects(renderObjects:Array<RenderObject>, camera:Camera/*, lights:Array<Light>*/, useBlending:Bool/*, overrideMaterial:Material*/) {

		// Get view projection matrix
		this._viewProjectionMatrix.copyFrom(camera.viewProjectionMatrix);

		// Set global uniforms
		UniformLib.instance().uniform("viewMatrix").matrixValue = camera.viewMatrix;
		UniformLib.instance().uniform("projectionMatrix").matrixValue = camera.projectionMatrix;

		// lights
		//UniformLib.instance().uniform("lights", "...").matrixValue = ...;

		// Initialise states of shader programs
		this._renderPassShaders = new Map<String, ShaderProgram>();
		this._currentProgram = null;
		this._currentMaterial = null;

		for (renderObject in renderObjects) {

			// Update model matrices
			renderObject.updateRenderMatrices(camera);

			// Set matrices in uniform lib
			UniformLib.instance().uniform("modelMatrix").matrixValue = renderObject.modelMatrix;
			UniformLib.instance().uniform("modelViewMatrix").matrixValue = renderObject.modelViewMatrix;
			UniformLib.instance().uniform("modelViewProjectionMatrix").matrixValue = renderObject.modelViewProjectionMatrix;
			UniformLib.instance().uniform("normalMatrix").matrixValue = renderObject.normalMatrix;

			// Update shader program
			var material = renderObject.material;

			// Set blending
			if (useBlending) {
				_stateManager.setBlending(material.blending, material.blendEquation, material.blendSrc, material.blendDst);
			}

			// Depth
			_stateManager.setDepthTest(material.depthTest);
			_stateManager.setDepthWrite(material.depthWrite);

			// Polygon offset
			_stateManager.setPolygonOffset(material.polygonOffset, material.polygonOffsetFactor, material.polygonOffsetUnits);

			// Set material face sides
			_stateManager.setMaterialSides(material.side);

			// Render the object buffers
			this.renderBuffer(material, renderObject, camera/*, lights*/);


		}
	}

	private function renderBuffer(material:Material, renderObject:RenderObject, camera:Camera/*, lights:Array<Light>*/):Void {

		// Set program and uniforms
		this.setProgram(material, renderObject, camera/*, lights*/);

		// Render the buffers
		renderObject.renderBuffer(material.program, this._attributeManager, this._bufferManager);
	}

	private function setProgram(material:Material, renderObject:RenderObject, camera:Camera/*, lights:Array<Light>*/):Void {

		var program = material.program;

		//var refreshLights:Bool = false;

		if (this._currentProgram != program) {
			this._currentProgram = program;

			// Use program
			program.use();

			// If the program has already been used in this render pass then don't update global uniforms
			// NB: this just stops the values been updated locally - all uniforms check for changed values before sending to the GPU
			if (!this._renderPassShaders.exists(program.name)) {
				// Update global uniforms in the shader
				program.updateGlobalUniforms(this._textureManager);

				this._renderPassShaders.set(program.name, program);
			}
		}

		// If material has changed then update the program uniforms from the material uniforms
		// TODO: maybe should always update uniforms... if they haven't changed then they are not sent to the GPU anyway
		if (this._currentMaterial != material) {
			this._currentMaterial = material;

			// Send material uniform values to program
			material.updateProgramUniforms(this._textureManager);
		}

		// Set textures
		// TODO

	}


}