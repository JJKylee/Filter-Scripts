#########################################################################################
#
# ChubbyRain2.avsi
#
# 2021-07-20 mod by Asd-g
#
# (This is a polished-up version by JKyle)
#
### Note ###
#------------
# Only progressive clips supported.
# If you have an interlaced clip, make sure you deinterlace it before using this filter.
#
# http://avisynth.nl/index.php/ChubbyRain2
#
# - based on Mug Funky's ChubbyRain
# - ChubbyRain2 by Lothar on Doom9's forum (https://forum.doom9.org/showthread.php?p=589885#post589885)
# - updated to support HBD (Asd-g)
# - Replaced mt_convolution with Expr for speed-up (Asd-g)
#
### Requirements ###
#-------------------
# Bifrost (https://github.com/Asd-g/AviSynth-bifrost)
# vsCnr2 (https://github.com/Asd-g/AviSynth-vsCnr2)
# MaskTools2 (https://github.com/pinterf/masktools)
# Avsresize (http://avisynth.nl/index.php/Avsresize)
#
### Changelog ###
#---------------
# Changed requirements: replaced Cnr2 with vsCnr2 (Asd-g)
# Added support for 10..16-bit clips (Asd-g)
# Removed restriction for only 420 video (Asd-g)
# Made parameter "interlaced" dummy (Asd-g)
# Replaced mt_convolution with GeneralConvolution for speed up (Asd-g)
# Replaced GeneralConvolution with Expr for speed up (Asd-g)
#
#########################################################################################


function ChubbyRain2(clip c, int "th", int "radius", int "sft", bool "interlaced", bool "show")
{

    th          = Default(th, 10)
    radius      = Default(radius, 10)
    sft         = Default(sft, 10)
    # interlaced  = Default(interlaced, false) # made dummy
    show        = Default(show, false)
    
    # uc = mt_convolution(c, horizontal="1", vertical="1 -2 1", Y=1, U=3, V=3)
    # mt_convolution(c, horizontal="1", vertical="1 2 1", Y=2, U=3, V=3)
    
    # uc = GeneralConvolution(c, matrix="0 1 0 0 -2 0 0 1 0", luma=false, alpha=false) # mt_convolution replacement (1st update)
    # GeneralConvolution(c, matrix="0 1 0 0 2 0 0 1 0", luma=false, alpha=false) # mt_convolution replacement (1st update)
    
    uc = Expr(c, "", "x[0,-1] x[0,0] -2 * + x[0,1] +") # GeneralConvolution replacement (2nd update)
    Expr(c, "", "x[0,-1] x[0,0] 2 * + x[0,1] + 0.250001 *") # GeneralConvolution replacement (2nd update)
    Bifrost(interlaced=false)
    vsCnr2()
    cc = TemporalSoften(radius, 0, sft, 2, 2)
    
    mt_lutxy(ExtractU(uc), ExtractV(uc), "x y + "+String(th)+" > 255 0 ?", scale_inputs="allf", use_expr=1)
    z_PointResize(c.width, c.height)
    rainbow = mt_expand(y=3, u=-128, v=-128)#.blur(1.5)
    
    mt_merge(c, cc, rainbow, y=2, luma=true)
    
    return (show) ? rainbow : last
}
