#version 300 es
in vec4 vertexPosition;
in vec4 vertexTexCoord;
in vec4 vertexNormal;
in vec4 blendIndices;
in vec4 blendWeights;

// LABTODO: attributes for rigging/blending
out vec4 texCoord;// passed to FS
out vec4 worldPosition;
out vec4 worldNormal;

struct DualQuat {
    vec4 q;
    vec4 t;
};

uniform struct {
    sampler2D boneQTexture;
    sampler2D boneTTexture;
/*iMSc: instance*/
    float nBones;
} multiMesh;

uniform struct{
    mat4 viewProjMatrix;
    vec3 position;
} camera;

void main(void) {

    DualQuat dq;

    DualQuat dq0;
    DualQuat dq1;
    DualQuat dq2;
    DualQuat dq3;

    dq0.q = texture(multiMesh.boneQTexture, vec2((float(blendIndices.x)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq0.t = texture(multiMesh.boneTTexture, vec2((float(blendIndices.x)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq1.q = texture(multiMesh.boneQTexture, vec2((float(blendIndices.y)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq1.t = texture(multiMesh.boneTTexture, vec2((float(blendIndices.y)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq2.q = texture(multiMesh.boneQTexture, vec2((float(blendIndices.z)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq2.t = texture(multiMesh.boneTTexture, vec2((float(blendIndices.z)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq3.q = texture(multiMesh.boneQTexture, vec2((float(blendIndices.w)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));
    dq3.t = texture(multiMesh.boneTTexture, vec2((float(blendIndices.w)  + 0.5)/multiMesh.nBones, 0.0 /*iMSc: instance*/));


//    dq.q = dq0.q*blendWeights.x + dq1.q*blendWeights.y + dq2.q*blendWeights.z +dq3.q*blendWeights.w;
//    dq.t = dq0.t*blendWeights.x + dq1.t*blendWeights.y + dq2.t*blendWeights.z +dq3.t*blendWeights.w;

    vec3 podality = vec3(
    (dot(dq0.q, dq1.q)>=0.0)?1.0:-1.0,
    (dot(dq0.q, dq2.q)>=0.0)?1.0:-1.0,
    (dot(dq0.q, dq3.q)>=0.0)?1.0:-1.0);

    vec4 w = blendWeights;
    w.w = 1.0-dot(w.xyz, vec3(1, 1, 1));
    w.yzw *= podality;

        dq.q = dq0.q*w.x + dq1.q*w.y + dq2.q*w.z +dq3.q*w.w;
        dq.t = dq0.t*w.x + dq1.t*w.y + dq2.t*w.z +dq3.t*w.w;

    float length = length(dq.q);

    dq.q = dq.q / length;
    dq.t = dq.t / length;

    // LABTODO: read all DQ data for smooth skinning
    // LABTODO: fix podality
    // LABTODO: blending for smooth skinning
    // LABTODO: normalize dq

    // rotate with dq
    vec3 blendedPos = vertexPosition.xyz + 2.0 * cross(dq.q.xyz,
    cross(dq.q.xyz, vertexPosition.xyz) +
    dq.q.w * vertexPosition.xyz);
    // translate by dq
    blendedPos += 2.0*(dq.q.w*dq.t.xyz - dq.t.w*dq.q.xyz + cross(dq.q.xyz, dq.t.xyz));
    // iMSc: offset by instance

    worldPosition = vec4(blendedPos, 1);
    gl_Position = worldPosition * camera.viewProjMatrix;
    texCoord = vertexTexCoord;
    // rotate by dq
    worldNormal.xyz = vertexNormal.xyz + 2.0 * cross(dq.q.xyz, cross(dq.q.xyz, vertexNormal.xyz) + dq.q.w * vertexNormal.xyz);
}
