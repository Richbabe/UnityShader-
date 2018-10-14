﻿Shader "Unity Shaders Book/Chapter 8/Chapter8-AlphaTestBothSided" {
	Properties{
		_Color("Main Tint", Color) = (1,1,1,1)
		_MainTex("Main Tex", 2D) = "white" {}
	_Cutoff("Alpha Cutoff", Range(0,1)) = 0.5//决定调用clip进行透明度测试时的判断条件
	}
		SubShader{
		Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout" }
		Pass{
		Tags{ "LightMode" = "ForwardBase" }

		//关闭（背面）剔除
		Cull Off

		CGPROGRAM

#pragma vertex vert
#pragma fragment frag
#include "Lighting.cginc"

		//定义Properties中的属性
		fixed4 _Color;
	sampler2D _MainTex;
	float4 _MainTex_ST;
	fixed _Cutoff;

	//顶点着色器输入
	struct a2v {
		float4 vertex : POSITION;
		float3 normal : NORMAL;
		float4 texcoord : TEXCOORD0;
	};

	//顶点着色器输出
	struct v2f {
		float4 pos : SV_POSITION;
		float3 worldNormal : TEXCOORD0;
		float3 worldPos : TEXCOORD1;
		float2 uv : TEXCOORD2;
	};

	//顶点着色器
	v2f vert(a2v v) {
		v2f o;

		//模型空间到裁剪空间的坐标变化
		o.pos = UnityObjectToClipPos(v.vertex);

		o.worldNormal = UnityObjectToWorldNormal(v.normal);

		o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

		o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

		return o;
	}

	//片段着色器
	fixed4 frag(v2f i) : SV_Target{
		fixed3 worldNormal = normalize(i.worldNormal);
	fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

	fixed4 texColor = tex2D(_MainTex, i.uv);

	//透明度测试Alpha test
	clip(texColor.a - _Cutoff);
	//相当于：
	//if((texColor.a - _CutOff) < 0.0){
	//discard;
	//}

	fixed3 albedo = texColor.rgb * _Color.rgb;

	fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

	fixed3 diffuse = _LightColor0.rgb * albedo * max(dot(worldNormal, worldLightDir), 0);

	fixed3 color = ambient + diffuse;

	return fixed4(color, 1.0);
	}

		ENDCG
	}
	}
		FallBack "Transparent/CutOut/VertexLit"
}
