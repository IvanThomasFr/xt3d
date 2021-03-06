
#if (defined (GOURAUD_LIGHTING) && defined (MAX_LIGHTS))

varying vec4 v_specular;

vec3 ecPosition3;
vec3 normal;
vec3 eye;


void gouraudLight(const in Light light,
				inout vec4 ambient,
				inout vec4 diffuse,
				inout vec4 specular,
				const in float shininess) {

	float nDotVP;
	float eDotRV;
	float pf;
	float attenuation;
	float d;
	vec3 VP;
	vec3 reflectVector;

	// Check if light source is directional
	if (light.position.w != 0.0) {
		// Vector between light position and vertex
		VP = vec3(light.position.xyz - ecPosition3);

		// Distance between the two
		d = length(VP);

		// Normalise
		VP = normalize(VP);

		// Calculate attenuation
		vec3 attDist = vec3(1.0, d, d * d);
		attenuation = 1.0 / dot(light.attenuation, attDist);

		// Calculate spot lighting effects
		if (light.spotCutoffAngle > 0.0) {
			float spotFactor = dot(-VP, light.spotDirection);
			float spotCutoff = cos(radians(light.spotCutoffAngle));
			if (spotFactor >= spotCutoff) {
				spotFactor = (1.0 - (1.0 - spotFactor) * 1.0/(1.0 - spotCutoff));
				spotFactor = pow(spotFactor, light.spotFalloffExponent);

			} else {
				spotFactor = 0.0;
			}
			attenuation *= spotFactor;
		}
	} else {
		attenuation = 1.0;
		VP = light.position.xyz;
	}

	// angle between normal and light-vertex vector
	nDotVP = max(0.0, dot(VP, normal));

 	ambient += light.ambientColor * attenuation;
	if (nDotVP > 0.0) {
		diffuse += light.diffuseColor * (nDotVP * attenuation);

		// reflected vector
		reflectVector = normalize(reflect(-VP, normal));

		// angle between eye and reflected vector
		eDotRV = max(0.0, dot(eye, reflectVector));
		eDotRV = pow(eDotRV, 16.0);

		pf = pow(eDotRV, shininess);
		specular += light.specularColor * (pf * attenuation);
	}
}

vec4 doGouraudLighting(const in vec4 vertexPosition,
						const in vec3 vertexNormal) {


	vec4 amb = vec4(0.0);
	vec4 diff = vec4(0.0);
	vec4 spec = vec4(0.0);

	vec4 ambient;
	vec4 diffuse;
	vec4 specular;

	if (u_lightingEnabled) {

#ifdef USE_MATERIAL_COLOR
		float shininess = u_material.shininess;
#else
		float shininess = u_defaultShininess;
#endif

		ecPosition3 = vec3(u_modelViewMatrix * vertexPosition);

		eye = -normalize(ecPosition3);

		normal = u_normalMatrix * vertexNormal;
		normal = normalize(normal);

		for (int i = 0; i < MAX_LIGHTS; i++) {
			if (u_lights[i].enabled) {
				gouraudLight(u_lights[i], amb, diff, spec, shininess);
			}
		}

		ambient = u_sceneAmbientColor + amb,
		diffuse = diff;
		specular = spec;

	} else {
		ambient = amb;
		diffuse = vec4(1.0);
		specular = spec;
	}


#ifdef USE_MATERIAL_COLOR
	ambient *= u_material.ambientColor;
	diffuse *= u_material.diffuseColor;
	specular *= u_material.specularColor;
#endif /* USE_MATERIAL_COLOR */

	// Set specular for fragement shader
	v_specular = specular;

	// Create combined color
	vec4 color = ambient + diffuse;
	color = clamp(color, 0.0, 1.0);

	return color;
}

#endif // GOURAUD_LIGHTING

