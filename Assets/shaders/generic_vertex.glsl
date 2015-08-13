
varying vec4 v_color;

#ifdef USE_TEXTURE
varying vec2 v_uv;
#endif /* USE_TEXTURE */

#if (defined (PHONG_LIGHTING) && defined (MAX_LIGHTS))

varying vec3 v_ecPosition3;
varying vec3 v_normal;
varying vec3 v_eye;

void doPhongLightingPrepare(const in vec4 vertexPosition,
						const in vec3 vertexNormal) {

	v_ecPosition3 = vec3(u_modelViewMatrix * vertexPosition);
	v_eye = -normalize(v_ecPosition3);
	v_normal = normalize(u_normalMatrix * vertexNormal);
}

#endif // PHONG_LIGHTING


void main(void) {

	// Set position (use bones if necessary)
	vec4 position = a_position;

#ifdef USE_TEXTURE
	// Set uv
	v_uv = a_uv * u_uvScaleOffset.xy + u_uvScaleOffset.zw;
#endif /* USE_TEXTURE */

	// Initialise color from uniform color
	vec4 color = u_color;

#ifdef GOURAUD_LIGHTING
	// Do gouraud vertex lighting
	color *= doGouraudLighting(position, a_normal);
#endif /* GOURAUD_LIGHTING */

#ifdef USE_VERTEX_COLOR
	// Apply vertex color
	color *= a_color;
#endif /* USE_VERTEX_COLOR */

	// Set varying color for fragment shader
	v_color = color;

#ifdef PHONG_LIGHTING
	doPhongLightingPrepare(position, a_normal);
#endif

//	vec4 mvPosition = u_modelViewMatrix * a_position;
//	gl_Position = u_projectionMatrix * mvPosition;

	gl_Position = u_modelViewProjectionMatrix * a_position;
//	gl_Position.xy += a_userData;
}