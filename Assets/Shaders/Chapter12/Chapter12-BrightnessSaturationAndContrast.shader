Shader "Unity Shaders Book/Chapter 12/Chapter12-BrightnessSaturationAndContrast" {
	Properties {
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 1
		_Saturation ("Saturation", Float) = 1
		_Contrast ("Contrast", Float) = 1
	}
	SubShader {
		Pass{
			ZTest Always Cull Off Zwrite Off //关闭深度测试和深度写入，以免影响透明物体的渲染

			CGPROGRAM
			#pragma vertex vert  
			#pragma fragment frag  

			#include "UnityCG.cginc"  

			//声明Properties中的变量
			sampler2D _MainTex;
			half _Brightness;
			half _Saturation;
			half _Contrast;

			struct v2f {
				float4 pos : SV_POSITION;
				half2 uv : TEXCOORD0;
			};

			//顶点着色器
			v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}

			//片段着色器
			fixed4 frag(v2f i) : SV_Target{
				fixed4 renderTex = tex2D(_MainTex, i.uv);//纹理颜色

				//添加亮度
				fixed3 finalColor = renderTex.rgb * _Brightness;

				//添加饱和度
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;//计算该像素的亮度值(luminance)，即RBG转YUV计算灰度通道
				fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
				finalColor = lerp(luminanceColor, finalColor, _Saturation);

				//添加对比度
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);

				return fixed4(finalColor, renderTex.a);
			}

			ENDCG
		}
	}
	FallBack Off
}
