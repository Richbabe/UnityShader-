Shader "Unity Shaders Book/Chapter7-SingleTexture" {
	Properties {
		_Color ("Color Tint", Color) = (1,1,1,1) //控制整体色调
		_MainTex ("Main Tex", 2D) = "white" {}
		_Specular ("Specular", Color) = (1,1,1,1)
		_Gloss("Gloss", Range(8.0,256)) = 20
	}
	SubShader{
		Pass{
			Tags{ "LightMode" = "ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;//用于处理纹理缩放和偏移
			fixed4 _Specular;
			float _Gloss;


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
				float2 uv : TEXCOORD2;//缩放平移后的纹理坐标
			};

			//顶点着色器
			v2f vert(a2v v) {
				v2f o;

				//模型空间到裁剪空间的坐标变化
				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				//计算缩放平移后的纹理坐标
				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;//或者o.uv = TRANSFORM_TEX(v.texcoord,_MainTex)

				return o;
			}

			//片段着色器函数
			fixed4 frag(v2f i) : SV_Target{
				//使用纹理代替漫反射颜色
				fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

				//获取环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

				//将法线从模型空间转换到世界空间
				fixed3 worldNormal = normalize(i.worldNormal);

				//获得世界空间下的光照方向
				fixed3 worldLight = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//计算漫反射光照
				fixed3 diffuse = _LightColor0.rgb * albedo.rgb * saturate(dot(worldNormal, worldLight));

				//获取世界空间下的反射方向
				//fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));

				//获取世界空间下的视线方向
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				//计算半角向量
				fixed3 halfDir = normalize(worldLight + viewDir);

				//计算镜面反射光照
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(halfDir, worldNormal)), _Gloss);

				fixed3 color = ambient + diffuse + specular;

				return fixed4(color,1.0);
			}

			ENDCG
		}
	}
	FallBack "Specular"
}
