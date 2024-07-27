Shader "Custom/PostProcess"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Noise", 2D) = "white" {}
        _NoiseFactor ("Noise Factor", Range(10, 600)) = 150
         [ToggleUI] _GammaCorrect ("Gamma Correction", Float) = 1
    }
    SubShader
    {
        Pass
        {
            ZTest Always Cull Off ZWrite Off
            Fog { Mode Off }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            struct appdata_t
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            uniform float4 _MainTex_TexelSize;
            sampler2D _NoiseTex;
            uniform float4 _NoiseTex_TexelSize;
            float _GammaCorrect;
            float _Resolutionx;
            float _Resolutiony;
            float _NoiseFactor;

            #define iResolution float2(_MainTex_TexelSize.z, _MainTex_TexelSize.w)


            // Global access to uv data
            static v2f vertex_output;

            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

#define PI 3.1415927
#define Dash 
            float4 paper(float2 fragCoord)
            {
                return float4(1., 1., 0.95, 1.);
            }

            float4 applyGrid(float2 fragCoord, float4 baseColor)
            {
                float2 uv = fragCoord/iResolution.xy;
                float2 adjustedUV = float2(uv.x*iResolution.x/iResolution.y, uv.y);
                float4 inkColor = float4(0.6, 0.6, 0.6, 0.1);
                inkColor.rgb += baseColor.rgb*0.009;
                float horizontalLineIntensity = 1.-clamp(64.+cos(adjustedUV.x*PI*64.)*64., 0., 1.);
#ifdef Dash
                float horizontalDashV = 256.;
                float horizontalDashIntensity = clamp(cos(adjustedUV.y*PI*horizontalDashV), 0., 1.);
                horizontalLineIntensity = horizontalLineIntensity*horizontalDashIntensity;
#endif
                float verticalLineIntensity = 1.-clamp(64.+cos(adjustedUV.y*PI*64.)*64., 0., 1.);
#ifdef Dash
                float verticalDashV = 256.;
                float verticalDashIntensity = clamp(cos(adjustedUV.x*PI*verticalDashV), 0., 1.);
                verticalLineIntensity = verticalLineIntensity*verticalDashIntensity;
#endif
                float3 backgroundColor = lerp(baseColor.rgb, inkColor.rgb, max(horizontalLineIntensity, verticalLineIntensity));
                return float4(backgroundColor, 1.);
            }

            float4 getRand(float2 fragCoord)
            {
                float2 tres = _NoiseTex_TexelSize.zw;
                float4 r = tex2D(_NoiseTex, fragCoord/tres/sqrt(iResolution.x/_NoiseFactor));
                return r;
            }

            float4 applyPaperishEffect(float2 fragCoord, float4 baseColor)
            {
                float4 r = getRand(fragCoord*1.1)-getRand(fragCoord*1.1+float2(1., -1.));
                float4 c = baseColor*(0.95+0.06*r.xxxx+0.06*r);
                return c;
            }

            float4 applyVignette(float2 fragCoord, float4 baseColor)
            {
                float2 sc = (fragCoord-0.5*iResolution.xy)/iResolution.x;
                float vign = 1.-0.5*dot(sc, sc);
                vign *= 1.-0.7*exp(-sin(fragCoord.x/iResolution.x*PI)*20.);
                vign *= 1.-0.7*exp(-sin(fragCoord.y/iResolution.y*PI)*10.);
                return baseColor*vign;
            }

            float4 frag (v2f __vertex_output) : SV_Target
            {
                vertex_output = __vertex_output;
                float4 fragColor = 0;
                float2 fragCoord = vertex_output.uv * iResolution;
                fragColor = paper(fragCoord);
                fragColor = applyPaperishEffect(fragCoord, fragColor);
                fragColor = applyGrid(fragCoord, fragColor);
                fragColor.w = 1.;
                if (_GammaCorrect) fragColor.rgb = pow(fragColor.rgb, 2.2);
                return fragColor;
            }
            ENDCG
        }
    }
}
