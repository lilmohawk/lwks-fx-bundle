// @Maintainer jwrl
// @Released 2018-04-07
// @Author schrauber
// @see https://www.lwks.com/media/kunena/attachments/6375/magnifying_glass_640.png
//-----------------------------------------------------------------------------------------//
// Lightworks user effect magnifying_glass.fx
//
// This is similar in operation to the regional zoom effect, but instead of non-linear
// distortion a linear zoom is performed.  It can be used as-is, or fed into another
// effect to generate borders and/or generate shadows or blend with another background.
//
// Added subcategory for LW14 - jwrl 18 February 2017
//
// Modified 7 April 2018 jwrl.
// Added authorship and description information for GitHub, and reformatted the original
// code to be consistent with other Lightworks user effects.
//-----------------------------------------------------------------------------------------//

int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Magnifying glass";
   string Category    = "Stylize";
   string SubCategory = "Distortion";
> = 0;




///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// Parameters, which can be changed by the user in the effects settings.
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


int lens
<
   string Description = "Shape";
   string Enum = "Round or elliptical lens,Rectangular lens";
> = 0;


float zoom
<
   string Description = "zoom";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;


float dimensions
<
   string Group ="Glass size";
   string Description = "Dimensions";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.1;

float AspectRatio
<
   string Group ="Glass size";
   string Description = "Aspect Ratio";
   float MinVal = 0.1;
   float MaxVal = 10.0;
> = 1;


float Xcentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointX";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;

float Ycentre
<
   string Description = "Effect centre";
   string Flags = "SpecifiesPointY";
   float MinVal = 0.0;
   float MaxVal = 1.0;
> = 0.5;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Inputs       Samplers
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


texture Input;

sampler FgSampler = sampler_state
{
   Texture = <Input>;
   AddressU = Mirror;
   AddressV = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};



///////////////////////////////////////////////
// Definitions  and declarations             //
///////////////////////////////////////////////

float _OutputAspectRatio; 




//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//--------------------------------------------------------------


float4 Zoom (float2 xy : TEXCOORD1) : COLOR
{
 float2 xydist = float2 (Xcentre, 1.0 - Ycentre) - xy; 									// XY Distance between the current position to the adjusted effect centering
 float distance = length (float2 (xydist.x / AspectRatio, (xydist.y / _OutputAspectRatio) * AspectRatio)); 		// Hypotenuse of xydistance, the shortest distance between the currently processed pixels to the center of the distortion.
 
 if ((distance > dimensions) && (lens == 0)) return float4 (tex2D(FgSampler, xy).rgb, 0.0);						// Background, round lens
 
 if (((abs(xydist.x) / AspectRatio > dimensions)
    || (abs(xydist.y) * AspectRatio > dimensions))
    && (lens == 1))
    return float4 (tex2D(FgSampler, xy).rgb, 0.0);											// Background, rectangular lens

 return tex2D (FgSampler, zoom * xydist + xy);										// Zoom  (lens)
} 



//--------------------------------------------------------------
// Technique
//
// Specifies the order of passes (we only have a single pass, so
// there's not much to do)
//--------------------------------------------------------------
technique SampleFxTechnique
{
   pass SinglePass
   {
      PixelShader = compile PROFILE Zoom();
   }
}
