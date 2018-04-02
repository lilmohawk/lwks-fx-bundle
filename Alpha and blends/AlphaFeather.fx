// @ReleaseDate: 2018-03-31
//--------------------------------------------------------------//
// Header
//
// Lightworks effects have to have a _LwksEffectInfo block
// which defines basic information about the effect (ie. name
// and category). EffectGroup must be "GenericPixelShader".
//
// Cross platform compatibility check 26 July 2017 jwrl.
//
// Explicitly define samplers so we aren't bitten by the cross
// platform default bug.
//
// Added workaround for the interlaced media height bug in
// Lightworks effects.
//--------------------------------------------------------------//
int _LwksEffectInfo
<
   string EffectGroup = "GenericPixelShader";
   string Description = "Alpha Feather";
   string Category    = "Mix";
   string SubCategory = "User Effects";
> = 0;

//--------------------------------------------------------------//
// Inputs
//--------------------------------------------------------------//

// For each 'texture' declared here, Lightworks adds a matching
// input to your effect (so for a four input effect, you'd need
// to delcare four textures and samplers)

texture fg;
texture bg;

texture composite : RenderColorTarget;

// Explicitly defined the filters for these samplers - jwrl.

sampler FgSampler = sampler_state {
   Texture   = <fg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler BgSampler = sampler_state {
   Texture   = <bg>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

sampler CompSampler = sampler_state {
   Texture   = <composite>;
   AddressU  = Mirror;
   AddressV  = Mirror;
   MinFilter = Linear;
   MagFilter = Linear;
   MipFilter = Linear;
};

//--------------------------------------------------------------//
// Define parameters here.
//
// The Lightworks application will automatically generate
// sliders/controls for all parameters which do not start
// with a a leading '_' character
//--------------------------------------------------------------//
float Opacity
<
	string Description = "Opacity";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 1.0f;

float thresh
<
	string Description = "Threshold";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 0.2f;

float Feather
<
	string Description = "Radius";
	float MinVal = 0.0f;
	float MaxVal = 2.0f;
> = 0.0f;

float Mix
<
	string Description = "Mix";
	float MinVal = 0.0f;
	float MaxVal = 1.0f;
> = 1.0f;

bool Show
<
	string Description = "Show alpha";
> = false;

float _OutputWidth;
float _OutputAspectRatio;

#pragma warning ( disable : 3571 )

//--------------------------------------------------------------
// Pixel Shader
//
// This section defines the code which the GPU will
// execute for every pixel in an output image.
//
// Note that pixels are processed out of order, in parallel.
// Using shader model 2.0, so there's a 64 instruction limit -
// use multple passes if you need more.
//--------------------------------------------------------------

float offset[5] = {0.0, 1.0, 2.0, 3.0, 4.0 };
float weight[5] = {0.2734375, 0.21875 / 4.0, 0.109375 / 4.0,0.03125 / 4.0, 0.00390625 / 4.0};

float4 Composite(float2 xy1 : TEXCOORD1) : COLOR
{
	float4 fg = tex2D( FgSampler, xy1 );
	float4 bg = tex2D( BgSampler, xy1 );
	
	float4 ret = lerp( bg, fg, fg.a * Opacity );
	ret.a = fg.a;
	
	return ret;
}


float4 AlphaFeather(float2 uv : TEXCOORD1) : COLOR
{
	float2 pixel = float2(1.0, _OutputAspectRatio) / _OutputWidth;     // Corrects for Lightworks' output height bug with interlaced media - jwrl.
	float4 color;
	float4 Cout;
	float check;
	float4 orig = tex2D(CompSampler,uv);
	check = orig.a;
	color = tex2D(CompSampler, uv) * (weight[0]);
	for (int i=1; i<5; i++) {
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i],0.0f)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv - (float2(pixel.x * offset[i],0.0)*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv - (float2(0.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv - (float2(pixel.x * offset[i],pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i] * -1.0,pixel.y * offset[i])*Feather)) * weight[i];
		else color += orig * (weight[i]);
		Cout = tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather));
		if (abs(check-Cout.a) > thresh) color += tex2D(CompSampler, uv + (float2(pixel.x * offset[i],pixel.y * offset[i] * -1.0)*Feather)) * weight[i];
		else color += orig * (weight[i]);
	}
		
	color.a = 1.0;
	orig.a = 1.0;

	if (Show) return check.xxxx;
	else return lerp(orig,color,Mix);
}


technique Alph
{
	pass one
   	<
    	string Script = "RenderColorTarget0 = composite;";
   	>
	{
		PixelShader = compile PROFILE Composite();
	}
	
	pass two
	{
		PixelShader = compile PROFILE AlphaFeather();
	}
}
