// @ReleaseDate 2018-03-31
// @Author gr00by
// @OriginalAuthor "Mark Ransom"
//--------------------------------------------------------------//
// HueRotate.fx by Lightworks user gr00by 14 June 2016
//
// This code is based on the Mark Ransom alghoritm 
// written in Python and published on:
// http://stackoverflow.com/a/8510751/512594
//
// The template of this file is based on TwoAxis.fx by
// Lightworks user jwrl.
//
// Bug fix by jwrl 4 January 2017 to add missing comma to
// sincos (Hue * PI, s c).
//
// Subcategory added by jwrl for v.14 and up 10 Feb 2017
//
// Cross platform compatibility check 30 July 2017 jwrl.
//
// Explicitly defined samplers so we aren't bitten by cross
// platform default sampler state differences.
//--------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Hue rotate";
   string Category    = "Colour";
   string SubCategory = "Technical";
> = 0;

//--------------------------------------------------------------//
// Parameters
//--------------------------------------------------------------//

float Hue
<
   string Description = "Hue";
   float MinVal = -1.0;
   float MaxVal = 1.0;
> = 0.0;


//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

texture Input;

//--------------------------------------------------------------//
// Samplers
//--------------------------------------------------------------//

sampler InputSampler = sampler_state { Texture = <Input>; };

//--------------------------------------------------------------//
// Declarations and definitions
//--------------------------------------------------------------//

#define PI         3.14159

#define ONE_THIRD  0.33333

#define SQRT_THIRD 0.57735


//--------------------------------------------------------------//
// Shaders
//--------------------------------------------------------------//

float4 ps_main (float2 xy : TEXCOORD1) : COLOR
{
   float c, s;

   sincos (Hue * PI, s, c);
   
   float4 rMat =float4 (c + ONE_THIRD * (1.0 - c), ONE_THIRD * (1.0 - c) - SQRT_THIRD * s, ONE_THIRD * (1.0 - c) + SQRT_THIRD * s, 1.0);
   float4 gMat =float4 (ONE_THIRD * (1.0 - c) + SQRT_THIRD * s, c + ONE_THIRD * (1.0 - c), ONE_THIRD * (1.0 - c) - SQRT_THIRD * s, 1.0);
   float4 bMat =float4 (ONE_THIRD * (1.0 - c) - SQRT_THIRD * s, ONE_THIRD * (1.0 - c) + SQRT_THIRD * s, c + ONE_THIRD * (1.0 - c), 1.0);

   float4 Image  = tex2D (InputSampler, xy);

   float4 retval = float4 (
      Image.r * rMat.r + Image.g * rMat.g + Image.b * rMat.b,
      Image.r * gMat.r + Image.g * gMat.g + Image.b * gMat.b,
      Image.r * bMat.r + Image.g * bMat.g + Image.b * bMat.b,
      Image.a);

   return retval;
}

//--------------------------------------------------------------//
// Techniques
//--------------------------------------------------------------//

technique ColourTemp
{
   pass pass_one
   {
      PixelShader = compile PROFILE ps_main ();
   }
}

