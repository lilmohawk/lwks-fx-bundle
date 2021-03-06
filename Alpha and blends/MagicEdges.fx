// @Maintainer jwrl
// @Released 2018-07-05
// @Author jwrl
// @Author Robert Schütze
// @Created 2016-05-08
// @see https://www.lwks.com/media/kunena/attachments/6375/Magic_Edges_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect MagicEdges.fx
//
// The fractal generation component was created by Robert Schütze in GLSL sandbox
// (http://glslsandbox.com/e#29611.0).  It has been somewhat modified to better suit the
// needs of its use in this context.
//
// The star point component is similar to khaver's Glint.fx, but modified to create four
// star points in one loop, to have no blur component, no choice of number of points, and
// to compile and run under the default Lightworks shader profile.  A different means of
// setting and calculating rotation is also used.  Apart from that it's identical.
//
// LW 14+ version 11 January 2017
// Category changed from "Mixes" to "Key", subcategory "Edge Effects" added.
//
// Bug fix 26 February 2017
// This corrects for a bug in the way that Lightworks handles interlaced media.  It
// returns only half the actual frame height when interlaced media is stationary.
//
// Bug fix 26 July 2017 by jwrl:
// Because Windows and Linux-OS/X have differing defaults for undefined samplers they
// have now been explicitly declared.
//
// Modified 5 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//
// Modified 5 July 2018 jwrl.
// Changed edge generation to be frame based rather than pixel based.
// Reduced number of required passes from thirteen to seven.
// As a result, reduced samplers required by 3.
// Halved the rotation gamut from 360 to 180 degrees.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Magic edges";
   string Category    = "Key";
   string SubCategory = "Edge Effects";
   string Notes       = "Fractal edges with star-shaped radiating blurs";
> = 0;

//-----------------------------------------------------------------------------------------//
// Inputs
//-----------------------------------------------------------------------------------------//

texture Fg;
texture Bg;

texture Fractals : RenderColorTarget;
texture Border   : RenderColorTarget;

texture Sample_1 : RenderColorTarget;
texture Sample_2 : RenderColorTarget;

//-----------------------------------------------------------------------------------------//
// Samplers
//-----------------------------------------------------------------------------------------//

sampler s_Foreground = sampler_state {
   Texture   = <Fg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Background = sampler_state {
   Texture   = <Bg>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Fractals = sampler_state {
   Texture   = <Fractals>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Border = sampler_state {
   Texture   = <Border>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Sample_1 = sampler_state {
   Texture = <Sample_1>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler s_Sample_2 = sampler_state {
   Texture   = <Sample_2>;
   AddressU  = Clamp;
   AddressV  = Clamp;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//-----------------------------------------------------------------------------------------//
// Parameters
//-----------------------------------------------------------------------------------------//

float Amount
<
   string Description = "Opacity";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float EdgeWidth
<
   string Description = "Edge width";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Rate
<
   string Description = "Speed";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float StartPoint
<
   string Description = "Start point";   
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float Threshold
<
   string Group = "Stars";
   string Description = "Threshold";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.25;

float Brightness
<
   string Group = "Stars";
   string Description = "Brightness";
   float MinVal = 1.0;
   float MaxVal = 10.0;
> = 1.0;

float StarLen
<
   string Group = "Stars";
   string Description = "Length";
   float MinVal = 0.0;
   float MaxVal = 20.0;
> = 5.0;

float Rotation
<
   string Group = "Stars";
   string Description = "Rotation";
   float MinVal = 0.0;
   float MaxVal = 180.0;
> = 45.0;

float Strength
<
   string Group = "Stars";
   string Description = "Strength";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 1.0;

float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.00;
   float MaxVal = 1.00;
> = 0.5;

float Size
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointZ";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float ColourMix
<
   string Description = "Colour modulation";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.0;

float4 Colour
<
   string Description = "Modulation value";
   bool SupportsAlpha = false;
> = { 0.69, 0.26, 1.0, 1.0 };

bool ShowFractal
<
   string Description = "Show pattern";
> = false;

//-----------------------------------------------------------------------------------------//
// Definitions and declarations
//-----------------------------------------------------------------------------------------//

#define PI_2        6.28318530718

#define R_VAL       0.2989
#define G_VAL       0.5866
#define B_VAL       0.1145

#define SCL_RATE    224

#define LOOP        60

#define DELTANG     25
#define ANGLE       0.1256637061

#define A_SCALE     0.005
#define B_SCALE     0.0005

#define STAR_LENGTH 0.00025

float _Progress;
float _OutputAspectRatio;

//-----------------------------------------------------------------------------------------//
// Shaders
//-----------------------------------------------------------------------------------------//

float4 ps_fractals (float2 uv : TEXCOORD1) : COLOR
{
   float progress = ((_Progress + StartPoint) * PI_2) / sqrt (SCL_RATE + 1.0 - (SCL_RATE * Rate));

   float2 seed = float2 (cos (progress) * 0.3, sin (progress) * 0.5) + 0.5;
   float2 xy = uv - float2 (Xcentre, 1.0 - Ycentre);

   float3 retval = float3 (xy / (Size + 0.01), seed.x);

   float4 fg = tex2D (s_Foreground, uv);

   for (int i = 0; i < LOOP; i++) {
      retval.rbg = float3 (1.2, 0.999, 0.9) * (abs ((abs (retval) / dot (retval, retval) - float3 (1.0, 1.0, seed.y * 0.4))));
   }

   retval = saturate (retval);

   float luma = (retval.r * R_VAL) + (retval.g * G_VAL) + (retval.b * B_VAL);
   float Yscl = (Colour.r * R_VAL) + (Colour.g * G_VAL) + (Colour.b * B_VAL);

   Yscl = saturate (Yscl - 0.5);
   Yscl = 1 / (Yscl + 0.5);

   float4 buffer = Colour * luma  * Yscl;

   return float4 (lerp (retval, buffer.rgb, ColourMix), fg.a);
}

float4 ps_border_1 (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * (EdgeWidth + 0.1) * A_SCALE;
   float2 offset, scale;

   float angle  = 0.0;
   float border = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (s_Foreground, uv + offset).a;
      border += tex2D (s_Foreground, uv - offset).a;
      angle += ANGLE;
   }

   border = (border / DELTANG) - 1.0;
   border = (border > 0.95) ? 0.0 : 1.0;
   border = min (border, tex2D (s_Foreground, uv).a);

   return border.xxxx;
}

float4 ps_border_2 (float2 uv : TEXCOORD1) : COLOR
{
   float2 pixsize = float2 (1.0, _OutputAspectRatio) * B_SCALE;
   float2 offset, scale;

   float border = 0.0;
   float angle  = 0.0;

   for (int i = 0; i < DELTANG; i++) {
      sincos (angle, scale.x, scale.y);
      offset = pixsize * scale;
      border += tex2D (s_Sample_1, uv + offset).a;
      border += tex2D (s_Sample_1, uv - offset).a;
      angle += ANGLE;
   }

   border = saturate (border / DELTANG);

   float3 retval = lerp (0.0.xxx, tex2D (s_Fractals, uv).rgb, border);

   return float4 (retval, border);
}

float4 ps_threshold (float2 uv : TEXCOORD1) : COLOR
{
   float4 retval = tex2D (s_Border, uv);

   return ((retval.r + retval.g + retval.b) / 3.0 > 1.0 - Threshold) ? retval : 0.0.xxxx;
}

float4 ps_stretch_1 (float2 uv : TEXCOORD1) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3 = 0.0.xx, xy4 = 0.0.xx;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   for (int i = 0; i < 18; i++) {
      delt = tex2D (s_Sample_2, uv + xy3).rgb;
      delt = max (delt, tex2D (s_Sample_2, uv - xy3).rgb);
      delt = max (delt, tex2D (s_Sample_2, uv + xy4).rgb);
      delt = max (delt, tex2D (s_Sample_2, uv - xy4).rgb);
      delt *= 1.0 - (i / 36.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   return float4 (ret, 1.0);
}

float4 ps_stretch_2 (float2 uv : TEXCOORD1) : COLOR
{
   float3 delt, ret = 0.0.xxx;

   float2 xy1, xy2, xy3, xy4;

   sincos (radians (Rotation), xy1.y, xy1.x);
   sincos (radians (Rotation + 90), xy2.y, xy2.x);

   xy1 *= StarLen * STAR_LENGTH;
   xy2 *= StarLen * STAR_LENGTH;

   xy1.y *= _OutputAspectRatio;
   xy2.y *= _OutputAspectRatio;

   xy3 = xy1 * 18.0;
   xy4 = xy2 * 18.0;

   for (int i = 0; i < 18; i++) {
      delt = tex2D (s_Sample_2, uv + xy3).rgb;
      delt = max (delt, tex2D (s_Sample_2, uv - xy3).rgb);
      delt = max (delt, tex2D (s_Sample_2, uv + xy4).rgb);
      delt = max (delt, tex2D (s_Sample_2, uv - xy4).rgb);
      delt *= 0.5 - (i / 36.0);
      ret += delt;
      xy3 += xy1;
      xy4 += xy2;
   }

   ret = (ret + tex2D (s_Sample_1, uv).rgb) / 3.6;

   return float4 (ret, 1.0);
}

float4 ps_main (float2 xy1 : TEXCOORD1, float2 xy2 : TEXCOORD2) : COLOR
{
   float4 Fgd = tex2D (s_Foreground, xy1);
   float4 Bgd = tex2D (s_Background, xy2);
   float4 retval = lerp (Bgd, Fgd, Fgd.a * Amount);

   float4 border = tex2D (s_Border, xy1);

   if (ShowFractal) return lerp (tex2D (s_Fractals, xy1), border, (border.a + 1.0) / 2);

   retval = lerp (retval, border, Brightness * border.a);

   float4 glint = tex2D (s_Sample_2, xy1);
   float4 comb  = retval + (glint * (1.0 - retval));

   return lerp (retval, comb, Strength);
}

//-----------------------------------------------------------------------------------------//
// Techniques
//-----------------------------------------------------------------------------------------//

technique doMatte
{
   pass P_1
   < string Script = "RenderColorTarget0 = Fractals;"; >
   { PixelShader = compile PROFILE ps_fractals (); }

   pass P_2
   < string Script = "RenderColorTarget0 = Sample_1;"; >
   { PixelShader = compile PROFILE ps_border_1 (); }

   pass P_3
   < string Script = "RenderColorTarget0 = Border;"; >
   { PixelShader = compile PROFILE ps_border_2 (); }

   pass P_4
   < string Script = "RenderColorTarget0 = Sample_2;"; >
   { PixelShader = compile PROFILE ps_threshold (); }

   pass P_5
   < string Script = "RenderColorTarget0 = Sample_1;"; >
   { PixelShader = compile PROFILE ps_stretch_1 (); }

   pass P_6
   < string Script = "RenderColorTarget0 = Sample_2;"; >
   { PixelShader = compile PROFILE ps_stretch_2 (); }

   pass P_7
   { PixelShader = compile PROFILE ps_main (); }
}
