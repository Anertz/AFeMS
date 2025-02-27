//#extension GL_EXT_gpu_shader4 : disable
//#extension GL_ARB_shader_texture_lod : disable

#include "/lib/settings.glsl"

flat varying int NameTags;

#ifdef HAND
#undef POM
#endif

#ifndef USE_LUMINANCE_AS_HEIGHTMAP
#ifndef MC_NORMAL_MAP
#undef POM
#endif
#endif

#ifdef POM
#define MC_NORMAL_MAP
#endif


varying float VanillaAO;

const float mincoord = 1.0/4096.0;
const float maxcoord = 1.0-mincoord;

const float MAX_OCCLUSION_DISTANCE = MAX_DIST;
const float MIX_OCCLUSION_DISTANCE = MAX_DIST*0.9;
const int   MAX_OCCLUSION_POINTS   = MAX_ITERATIONS;

uniform vec2 texelSize;
uniform int framemod8;

// #ifdef POM
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec4 vtexcoord;

vec2 dcdx = dFdx(vtexcoord.st*vtexcoordam.pq)*exp2(Texture_MipMap_Bias);
vec2 dcdy = dFdy(vtexcoord.st*vtexcoordam.pq)*exp2(Texture_MipMap_Bias);
// #endif

#include "/lib/res_params.glsl"
varying vec4 lmtexcoord;

varying vec4 color;

uniform float far;


uniform float wetness;
varying vec4 normalMat;


#ifdef MC_NORMAL_MAP
	uniform sampler2D normals;
	varying vec4 tangent;
	varying vec3 FlatNormals;
#endif


uniform sampler2D specular;



uniform sampler2D texture;
uniform sampler2D colortex1;//albedo(rgb),material(alpha) RGBA16
uniform float frameTimeCounter;
uniform int frameCounter;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float rainStrength;
uniform sampler2D noisetex;//depth
uniform sampler2D depthtex0;

uniform vec4 entityColor;

in vec3 velocity;

flat varying int PHYSICSMOD_SNOW;
flat varying float blockID;

flat varying float SSSAMOUNT;
flat varying float EMISSIVE;
flat varying int LIGHTNING;
flat varying int PORTAL;
flat varying int SIGN;


flat varying float HELD_ITEM_BRIGHTNESS;
uniform float noPuddleAreas;


// float interleaved_gradientNoise(){
// 	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y)+frameTimeCounter*51.9521);
// }
float interleaved_gradientNoise_temp(){
	vec2 alpha = vec2(0.75487765, 0.56984026);
	vec2 coord = vec2(alpha.x * gl_FragCoord.x,alpha.y * gl_FragCoord.y)+ 1.0/1.6180339887 * frameCounter;
	float noise = fract(52.9829189*fract(0.06711056*coord.x + 0.00583715*coord.y));
	return noise;
}
float interleaved_gradientNoise(){
	vec2 coord = gl_FragCoord.xy;
	float noise = fract(52.9829189*fract(0.06711056*coord.x + 0.00583715*coord.y));
	return noise;
}
float blueNoise(){
  return fract(texelFetch2D(noisetex, ivec2(gl_FragCoord.xy)%512, 0).a + 1.0/1.6180339887 * frameCounter);
}
float R2_dither(){
	vec2 alpha = vec2(0.75487765, 0.56984026);
	return fract(alpha.x * gl_FragCoord.x + alpha.y * gl_FragCoord.y + 1.0/1.6180339887 * frameCounter) ;
}

mat3 inverse(mat3 m) {
  float a00 = m[0][0], a01 = m[0][1], a02 = m[0][2];
  float a10 = m[1][0], a11 = m[1][1], a12 = m[1][2];
  float a20 = m[2][0], a21 = m[2][1], a22 = m[2][2];

  float b01 = a22 * a11 - a12 * a21;
  float b11 = -a22 * a10 + a12 * a20;
  float b21 = a21 * a10 - a11 * a20;

  float det = a00 * b01 + a01 * b11 + a02 * b21;

  return mat3(b01, (-a22 * a01 + a02 * a21), (a12 * a01 - a02 * a11),
              b11, (a22 * a00 - a02 * a20), (-a12 * a00 + a02 * a10),
              b21, (-a21 * a00 + a01 * a20), (a11 * a00 - a01 * a10)) / det;
}

vec3 viewToWorld(vec3 viewPosition) {
    vec4 pos;
    pos.xyz = viewPosition;
    pos.w = 0.0;
    pos = gbufferModelViewInverse * pos;
    return pos.xyz;
}
vec3 worldToView(vec3 worldPos) {
    vec4 pos = vec4(worldPos, 0.0);
    pos = gbufferModelView * pos;
    return pos.xyz;
}
vec4 encode (vec3 n, vec2 lightmaps){
	n.xy = n.xy / dot(abs(n), vec3(1.0));
	n.xy = n.z <= 0.0 ? (1.0 - abs(n.yx)) * sign(n.xy) : n.xy;
    vec2 encn = clamp(n.xy * 0.5 + 0.5,-1.0,1.0);
	
    return vec4(encn,vec2(lightmaps.x,lightmaps.y));
}

//encoding by jodie
float encodeVec2(vec2 a){
    const vec2 constant1 = vec2( 1., 256.) / 65535.;
    vec2 temp = floor( a * 255. );
	return temp.x*constant1.x+temp.y*constant1.y;
}
float encodeVec2(float x,float y){
    return encodeVec2(vec2(x,y));
}

#ifdef MC_NORMAL_MAP
	vec3 applyBump(mat3 tbnMatrix, vec3 bump, float puddle_values){
		float bumpmult = clamp(puddle_values,0.0,1.0);
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		return normalize(bump*tbnMatrix);
	}
#endif


#define diagonal3(m) vec3((m)[0].x, (m)[1].y, m[2].z)
#define  projMAD(m, v) (diagonal3(m) * (v) + (m)[3].xyz)

vec3 toScreenSpace(vec3 p) {
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = p * 2. - 1.;
    vec4 fragposition = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragposition.xyz / fragposition.w;
}
vec3 toClipSpace3(vec3 viewSpacePosition) {
    return projMAD(gbufferProjection, viewSpacePosition) / -viewSpacePosition.z * 0.5 + 0.5;
}

#ifdef POM
	vec4 readNormal(in vec2 coord)
	{
		return texture2DGradARB(normals,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
	}
	vec4 readTexture(in vec2 coord)
	{
		return texture2DGradARB(texture,fract(coord)*vtexcoordam.pq+vtexcoordam.st,dcdx,dcdy);
	}
#endif


float luma(vec3 color) {
	return dot(color,vec3(0.21, 0.72, 0.07));
}


vec3 toLinear(vec3 sRGB){
	return sRGB * (sRGB * (sRGB * 0.305306011 + 0.682171111) + 0.012522878);
}


const vec2[8] offsets = vec2[8](vec2(1./8.,-3./8.),
									vec2(-1.,3.)/8.,
									vec2(5.0,1.)/8.,
									vec2(-3,-5.)/8.,
									vec2(-5.,5.)/8.,
									vec2(-7.,-1.)/8.,
									vec2(3,7.)/8.,
									vec2(7.,-7.)/8.);
vec3 srgbToLinear2(vec3 srgb){
    return mix(
        srgb / 12.92,
        pow(.947867 * srgb + .0521327, vec3(2.4) ),
        step( .04045, srgb )
    );
}
vec3 blackbody2(float Temp)
{
    float t = pow(Temp, -1.5);
    float lt = log(Temp);

    vec3 col = vec3(0.0);
         col.x = 220000.0 * t + 0.58039215686;
         col.y = 0.39231372549 * lt - 2.44549019608;
         col.y = Temp > 6500. ? 138039.215686 * t + 0.72156862745 : col.y;
         col.z = 0.76078431372 * lt - 5.68078431373;
         col = clamp(col,0.0,1.0);
         col = Temp < 1000. ? col * Temp * 0.001 : col;

    return srgbToLinear2(col);
}

uniform float near;


float ld(float dist) {
    return (2.0 * near) / (far + near - dist * (far - near));
}


vec4 readNoise(in vec2 coord){
	// return texture2D(noisetex,coord*vtexcoordam.pq+vtexcoord.st);
		return texture2DGradARB(noisetex,coord*vtexcoordam.pq + vtexcoordam.st,dcdx,dcdy);
}
float EndPortalEffect(
	inout vec4 ALBEDO,
	vec3 FragPos,
	vec3 WorldPos,
	mat3 tbnMatrix
){	

	int maxdist = 25;
	int quality = 35;

	vec3 viewVec = normalize(tbnMatrix*FragPos);
	if ( viewVec.z < 0.0 && length(FragPos) < maxdist) {
		float endportalGLow = 0.0;
		float Depth = 0.3;
		vec3 interval = (viewVec.xyz /-viewVec.z/quality*Depth) * (0.7 + (blueNoise()-0.5)*0.1);

		vec3 coord = vec3(WorldPos.xz , 1.0);
		coord += interval;

		for (int loopCount = 0; (loopCount < quality) && (1.0 - Depth + Depth * ( 1.0-readNoise(coord.st).r - readNoise(-coord.st*3).b*0.2 ) ) < coord.p  && coord.p >= 0.0; ++loopCount) {
			coord = coord+interval ; 
			endportalGLow += (0.3/quality);
		}

  		ALBEDO.rgb = vec3(0.5,0.75,1.0) * sqrt(endportalGLow);

		return clamp(pow(endportalGLow*3.5,3),0,1);
	}
}

float bias(){
	return Texture_MipMap_Bias + (blueNoise()-0.5)*0.5;
}
vec4 texture2D_POMSwitch(
	sampler2D sampler, 
	vec2 lightmapCoord,
	vec4 dcdxdcdy, 
	bool ifPOM
){
	if(ifPOM){
		return texture2DGradARB(sampler, lightmapCoord, dcdxdcdy.xy, dcdxdcdy.zw);
	}else{
		return texture2D(sampler, lightmapCoord, bias());
	}
}



//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

/* RENDERTARGETS: 1,7,8,15 */
void main() {


	bool ifPOM = false;

	#ifdef POM
		ifPOM = true;
	#endif

	if(SIGN > 0) ifPOM = false;

	vec3 normal = normalMat.xyz;

	#ifdef MC_NORMAL_MAP
		vec3 tangent2 = normalize(cross(tangent.rgb,normal)*tangent.w);
		mat3 tbnMatrix = mat3(tangent.x, tangent2.x, normal.x,
							  tangent.y, tangent2.y, normal.y,
							  tangent.z, tangent2.z, normal.z);
	#endif

	vec2 tempOffset=offsets[framemod8];

	vec3 fragpos = toScreenSpace(gl_FragCoord.xyz*vec3(texelSize/RENDER_SCALE,1.0)-vec3(vec2(tempOffset)*texelSize*0.5,0.0));
	vec3 worldpos = mat3(gbufferModelViewInverse) * fragpos  + gbufferModelViewInverse[3].xyz + cameraPosition;

	float torchlightmap = lmtexcoord.z;

	#ifdef Hand_Held_lights
		if(HELD_ITEM_BRIGHTNESS > 0.0) torchlightmap = max(torchlightmap, HELD_ITEM_BRIGHTNESS * clamp( pow(max(1.0-length(fragpos)/10,0.0),1.5),0.0,1.0));
	#endif
	
	float lightmap = clamp( (lmtexcoord.w-0.8) * 10.0,0.,1.);

	float rainfall = rainStrength * noPuddleAreas;
	float Puddle_shape = 0.;
	
	#ifndef ENTITIES
	#ifndef HAND
	#ifdef WORLD
	#ifdef Puddles
		Puddle_shape = (1.0 - clamp(exp(-15 * pow(texture2D(noisetex, worldpos.xz * (0.020 * Puddle_Size)	).b  ,5)),0,1)) * lightmap		;
		Puddle_shape *= clamp( viewToWorld(normal).y*0.5+0.5 ,0.0,1.0);
		Puddle_shape *= rainfall;
	#endif
	#endif
	#endif
	#endif
	
	vec2 adjustedTexCoord = lmtexcoord.xy;

#ifdef POM
	#ifdef WORLD
			// vec2 tempOffset=offsets[framemod8];
			adjustedTexCoord = fract(vtexcoord.st)*vtexcoordam.pq+vtexcoordam.st;
			// vec3 fragpos = toScreenSpace(gl_FragCoord.xyz*vec3(texelSize/RENDER_SCALE,1.0)-vec3(vec2(tempOffset)*texelSize*0.5,0.0));
			vec3 viewVector = normalize(tbnMatrix*fragpos);
			float dist = length(fragpos);

			float maxdist = MAX_OCCLUSION_DISTANCE;
			if(!ifPOM) maxdist = 0.0;

			gl_FragDepth = gl_FragCoord.z;

	    	if (dist < maxdist) {

				float depthmap = readNormal(vtexcoord.st).a;
				float used_POM_DEPTH = 1.0;

	   	 		if ( viewVector.z < 0.0 && depthmap < 0.9999 && depthmap > 0.00001) {	
					// float noise = interleaved_gradientNoise_temp();
	  				#ifdef Adaptive_Step_length
						vec3 interval = (viewVector.xyz /-viewVector.z/MAX_OCCLUSION_POINTS * POM_DEPTH) * clamp(1.0-pow(depthmap,2),0.1,1.0);
						used_POM_DEPTH = 1.0;
	  				#else
	  					vec3 interval = viewVector.xyz /-viewVector.z/MAX_OCCLUSION_POINTS*POM_DEPTH;
					#endif
					vec3 coord = vec3(vtexcoord.st , 1.0);

					coord += interval * used_POM_DEPTH;

					float sumVec = 0.5;
					for (int loopCount = 0; (loopCount < MAX_OCCLUSION_POINTS) && (1.0 - POM_DEPTH + POM_DEPTH * readNormal(coord.st).a  ) < coord.p  && coord.p >= 0.0; ++loopCount) {
						coord = coord + interval  * used_POM_DEPTH; 
						sumVec += 1.0 * used_POM_DEPTH; 
					}
	
					if (coord.t < mincoord) {
	  					if (readTexture(vec2(coord.s,mincoord)).a == 0.0) {
	  						coord.t = mincoord;
	  						discard;
	  					}
	  				}
					
	  				adjustedTexCoord = mix(fract(coord.st)*vtexcoordam.pq+vtexcoordam.st, adjustedTexCoord, max(dist-MIX_OCCLUSION_DISTANCE,0.0)/(MAX_OCCLUSION_DISTANCE-MIX_OCCLUSION_DISTANCE));

	  				vec3 truePos = fragpos + sumVec*inverse(tbnMatrix)*interval;
	  				// #ifdef Depth_Write_POM
	  					gl_FragDepth = toClipSpace3(truePos).z;
	  				// #endif
				}
	    	}
	#endif
#endif

	if(!ifPOM) adjustedTexCoord = lmtexcoord.xy;
	

	//////////////////////////////// 				////////////////////////////////
	////////////////////////////////	ALBEDO		////////////////////////////////
	//////////////////////////////// 				//////////////////////////////// 
	
	vec4 Albedo = texture2D_POMSwitch(texture, adjustedTexCoord.xy, vec4(dcdx,dcdy), ifPOM) * color;



	if(LIGHTNING > 0) Albedo = vec4(1);
	float ENDPORTAL_EFFECT = PORTAL > 0 ? EndPortalEffect(Albedo, fragpos, worldpos, tbnMatrix) : 0;

	#ifdef WhiteWorld
		Albedo.rgb = vec3(1.0);
	#endif
		

	#ifdef AEROCHROME_MODE
		vec3 aerochrome_color = mix(vec3(1.0, 0.0, 0.0), vec3(0.715, 0.303, 0.631), AEROCHROME_PINKNESS);
		float gray = dot(Albedo.rgb, vec3(0.2, 01.0, 0.07));
		if(blockID == 10001 || blockID == 10003 || blockID == 10004 || blockID == 10006) {
		// IR Reflective (Pink-red)
			Albedo.rgb = mix(vec3(gray), aerochrome_color, 0.7);
		}
		else if(blockID == 10008) {
		// Special handling for grass block
			float strength = 1.0 - color.b;
			Albedo.rgb = mix(Albedo.rgb, aerochrome_color, strength);
		}
		#ifdef AEROCHROME_WOOL_ENABLED
			else if(blockID == 200) {
			// Wool
				Albedo.rgb = mix(Albedo.rgb, aerochrome_color, 0.3);
			}
		#endif
		else if(blockID == 8 || blockID == 10002)
		{
		// IR Absorbsive? Dark.
			Albedo.rgb = mix(Albedo.rgb, vec3(0.01, 0.08, 0.15), 0.5);
		}
	#endif

	#ifdef WORLD
		if (Albedo.a > 0.1) Albedo.a = normalMat.a;
		else Albedo.a = 0.0;
	#endif

	#ifdef HAND
		if (Albedo.a > 0.1) Albedo.a = 0.75;
		else Albedo.a = 0.0;
	#endif


	//////////////////////////////// 				////////////////////////////////
	////////////////////////////////	NORMAL		////////////////////////////////
	//////////////////////////////// 				//////////////////////////////// 

	#ifdef WORLD
		#ifdef MC_NORMAL_MAP
		
			vec4 NormalTex = texture2D_POMSwitch(normals, adjustedTexCoord.xy, vec4(dcdx,dcdy), ifPOM);
			NormalTex.xy = NormalTex.xy*2.0-1.0;
			NormalTex.z = clamp(sqrt(1.0 - dot(NormalTex.xy, NormalTex.xy)),0.0,1.0) ;

			if(PHYSICSMOD_SNOW < 1) normal = applyBump(tbnMatrix, NormalTex.xyz,  mix(1.0,1-Puddle_shape,rainfall)	);
		#endif
	#endif
	
	//////////////////////////////// 				////////////////////////////////
	////////////////////////////////	SPECULAR	////////////////////////////////
	//////////////////////////////// 				//////////////////////////////// 
	
	#ifdef WORLD
		vec4 SpecularTex = texture2D_POMSwitch(specular, adjustedTexCoord.xy, vec4(dcdx,dcdy), ifPOM);

		SpecularTex.r = max(SpecularTex.r, Puddle_shape);
		SpecularTex.g = max(SpecularTex.g, Puddle_shape*0.02);

		gl_FragData[2].rg = SpecularTex.rg;

		#if EMISSIVE_TYPE == 0
			gl_FragData[2].a = 0.0;
		#endif

		#if EMISSIVE_TYPE == 1
			gl_FragData[2].a = EMISSIVE;
		#endif

		#if EMISSIVE_TYPE == 2
			gl_FragData[2].a = SpecularTex.a;
			if(SpecularTex.a <= 0.0) gl_FragData[2].a = EMISSIVE;
		#endif

		#if EMISSIVE_TYPE == 3		
			gl_FragData[2].a = SpecularTex.a;
		#endif

		#if SSS_TYPE == 0
			gl_FragData[2].b = 0.0;
		#endif

		#if SSS_TYPE == 1
			gl_FragData[2].b = SSSAMOUNT;
		#endif

		#if SSS_TYPE == 2
			gl_FragData[2].b = SpecularTex.b;
			if(SpecularTex.b < 65.0/255.0) gl_FragData[2].b = SSSAMOUNT;
		#endif

		#if SSS_TYPE == 3		
			gl_FragData[2].b = SpecularTex.b;
		#endif

		if(PORTAL > 0){
			gl_FragData[2].rgb = vec3(0);
			gl_FragData[2].a = clamp(ENDPORTAL_EFFECT * 0.9, 0,0.9);
		}
	#endif

	// hit glow effect...
	#ifdef ENTITIES
		Albedo.rgb = mix(Albedo.rgb, entityColor.rgb, entityColor.a);
		gl_FragData[2].a = mix(gl_FragData[2].a, 0.5, entityColor.a);;
	#endif

	//////////////////////////////// 				////////////////////////////////
	////////////////////////////////	FINALIZE	////////////////////////////////
	//////////////////////////////// 				////////////////////////////////

	#ifdef WORLD

		#ifdef Puddles
			float porosity = 0.4;
			#ifdef Porosity
				porosity = SpecularTex.z >= 64.5/255.0 ? 0.0 : (SpecularTex.z*255.0/64.0)*0.65;
			#endif
			if(SpecularTex.g < 229.5/255.0) Albedo.rgb = mix(Albedo.rgb, vec3(0), Puddle_shape*porosity);
		#endif

		// apply noise to lightmaps to reduce banding.
		vec2 PackLightmaps = vec2(torchlightmap,lmtexcoord.w);
		
		#ifndef ENTITIES
		#ifndef HAND
			PackLightmaps = max(PackLightmaps*blueNoise()*0.05 + PackLightmaps,0.0);
		#endif
		#endif

		vec4 data1 = clamp( encode(viewToWorld(normal),PackLightmaps), 0.0, 1.0);

		gl_FragData[0] = vec4(encodeVec2(Albedo.x,data1.x),	encodeVec2(Albedo.y,data1.y),	encodeVec2(Albedo.z,data1.z),	encodeVec2(data1.w,Albedo.w));

		gl_FragData[1].a = 0.0;
	#endif


	
	#ifdef WORLD

		// #ifdef ENTITIES
		// 	gl_FragData[5].xyz = velocity *0.5+0.5;
		// #endif

		gl_FragData[3] = vec4(FlatNormals * 0.5 + 0.5, VanillaAO);	
	#endif
}