﻿Shader "Unity Shaders Book/Chapter 13/Chapter13-EdgeDetectNormalAndDepth" {
	Properties {
		_MainTex("Base (RGB)", 2D) = "white" {}
		_EdgeOnly("Edge Only", Float) = 1.0
		_EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance("Sample Distance", Float) = 1.0
		_Sensitivity("Sensitivity", Vector) = (1, 1, 1, 1)//其中xy分量保存法线和深度检测灵敏度，zw分量没用
	}
	SubShader {
		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;//纹素大小
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;

		sampler2D _CameraDepthNormalsTexture;//深度+法线纹理

		//顶点着色器输出
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;//第一个元素保存屏幕空间纹理坐标，其他四个保存Robert算子所需的四个领域纹理坐标
		};

		//顶点着色器
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;
			o.uv[0] = uv;

			//平台差异化处理
			#if UNITY_UV_STARTS_AT_TOP
				if (_MainTex_TexelSize.y < 0)
					uv.y = 1 - uv.y;
			#endif

			//通过_SampleDistance控制采样距离
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance;

			return o;
		}

		//计算对角线上两个纹理值的插值函数，返回值为0表明这两点之间存在一条边界，反之返回1
		half CheckSame(half4 center, half4 sample) {
			//获取两个采样点的法线和深度值
			half2 centerNormal = center.xy;
			float centerDepth = DecodeFloatRG(center.zw);
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);

			// difference in normals
			// do not bother decoding normals - there's no need here
			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;//如果小于0.1，说明差异不明显，不存在一条边界，返回1
			// difference in depth
			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
			// scale the required threshold by the distance
			int isSameDepth = diffDepth < 0.1 * centerDepth;

			// return:
			// 1 - if normals and depth are similar enough
			// 0 - otherwise
			return isSameNormal * isSameDepth ? 1.0 : 0.0;
		}

		//片段着色器
		fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target{
			//使用4个纹理坐标对深度+法线纹理进行采样
			half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);

			half edge = 1.0;

			edge *= CheckSame(sample1, sample2);
			edge *= CheckSame(sample3, sample4);

			fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
			fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
		}

		ENDCG

		//定义边缘检测的Pass
		Pass {
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM

			#pragma vertex vert  
			#pragma fragment fragRobertsCrossDepthAndNormal

			ENDCG
		}
	}
	FallBack Off
}
