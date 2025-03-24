#version 460 core

precision mediump float;

uniform vec2 iResolution;
uniform float iTime;

/* 

	
	http://bit.ly/shadertoy-plugin
 


*/

// speed
#define t (iTime * .6) 

// PI value
#define PI 3.14159265

// random
#define H(P) fract(sin(dot(P,vec2(127.1,311.7)))*43758.545)

// rotate 
#define pR(a) mat2(cos(a),sin(a),-sin(a),cos(a))

out vec4 fragColor;

void main() {
    vec2 fragCoord = gl_FragCoord.xy;
    vec2 uv = (fragCoord - .5 * iResolution.xy - .5) / iResolution.y;

    uv *= 2.4; // FOV
    
    // camera
    vec3 
        vuv = vec3(sin(iTime * .3), 1., cos(iTime)), // up
        ro = vec3(0., 0., 134.), // pos
        vrp = vec3(5., sin(iTime) * 60., 20.); // look at
    
    vrp.xz *= pR(iTime);
    vrp.yz *= pR(iTime * .2);
    
    vec3
    	vpn = normalize(vrp - ro),
        u = normalize(cross(vuv, vpn)),
    	rd = normalize(
            vpn + uv.x * u  + uv.y * cross(vpn, u)
        ); // ray direction
    
    vec3 sceneColor = vec3(0.0, 0., 0.3); // background color
    
    vec3 flareCol = vec3(0.); // flare color accumulator   
    float flareIntensivity = 0.; // flare intensity accumulator

    for (float k = 0.; k < 400.; k++) {
        float r = H(vec2(k)) * 2. - 1.; // random

        // 3d flare position, xyz
        vec3 flarePos =  vec3(
            H(vec2(k) * r) * 20. - 10.,
            r * 8.,
            (mod(sin(k / 200. * PI * 4.) * 15. - t * 13. * k * .007, 25.))
        );
		
        float v = max(0., abs(dot(normalize(flarePos), rd)));
        
        // main dot
        flareIntensivity += pow(v, 30000.) * 4.;
        
        // dot glow
        flareIntensivity += pow(v, 1e2) * .15; 
        
        // fade far
        flareIntensivity *= 1.- flarePos.z / 25.; 
        
        // accumulate
        flareCol += vec3(flareIntensivity) * (vec3(sin(r * 3.12 - k), r, cos(k) * 2.)) * .3; 
    }
    
    sceneColor += abs(flareCol);
    
    // go grayscale from screen center
    sceneColor = mix(sceneColor, sceneColor.rrr * 1.4, length(uv) / 2.);
    
    // adjust contrast
    fragColor.rgb = pow(sceneColor, vec3(1.1));
    fragColor.a = 1.0;
}
