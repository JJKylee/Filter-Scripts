#########################################################################################
#
# DeJump.avsi
#
# mod 2021-07-14 by JKyle
#
# An AviSynth filter that smooths out jumps and drops
# preserving the original frame rate
#
# Input must be a planar YUV pixel type (HBD supported)
#
# - Based on script created by Didée
#
# - Modified by John Meyer on June 29, 2011
# - Further modification by John Meyer on June 8, 2013
# https://forum.videohelp.com/threads/402416-repair-Videos-with-duplicates-and-dropped-frames#post2625132
#
# - Modified by JKyle
#    - Transformed into `DeJump` filter function (July 12, 2021)
#        - parametrized input clip, `jumpthresh`, and `thresh` (for `FillDrops`)
#        - parametrized `num` and `den` options for `double` via `MFlowFps` to take input clip properties
#        - removed `ShowMetrics` function needed for test
#        - removed `FillDrops` function to make use of the externalized filter script `FillDrops.avsi` (mod by Selur)
#        - unglobalized and internalized some variables to be used in `GenerateMask`: `jumpthresh`, `blackframe`, `whiteframe`
#    - Enabled HBD support (July 13, 2021)
#        - removed 8-bit conversion of input clip, `ConvertToYV12`, to enable HBD support
#        - (removed `KillAudio`)
#        - put input clip pixel type warning
#        - (changed color names from hex values to preset names)
#    - Parametrized decimation cycle (July 14, 2021)
#
### Requirements ###
#-------------------
# MvTools2 (https://github.com/pinterf/mvtools)
# MaskTools2 (https://github.com/pinterf/masktools)
# TIVTC (https://github.com/pinterf/TIVTC)
# FillDrops mod 2021-07-10 by Selur (https://github.com/JJKylee/Filter-Scripts/blob/main/AviSynth/FillDrops.avsi)
#
### Arguments ###
#-----------------
# jumpthresh (default=0.88) - Threshold for detecting jumps
#    Increase to catch more jumps
#    Should always be less than 1.0
#
# thresh (default=0.4) - Luma Difference Threshold for FillDrops
#
# dcycle (default=20) - decimation cycle
#     The smallest even number >= dcycle will be used as the decimation cycle for `TDecimate`
#     Using larger values can help when the drops and dups are widely scattered.
#     But the larger the values, the slower the script will run.
#
# showdot (default=false) - Troubleshooting
#    true for troubleshooting; otherwise, false
#
### How this filter works ###
#----------------------------
# Create interpolated frames a 2x original frame rate using MVTools2
# Detect jumps 
# Create white mask at each jump point; black mask for all other frames
# Repeat each frame of original video and use mask to "choose" between original video, or motion estimated video
# Decimate exactly 50% to get back to original frame rate. 
# This decimation removes the dup frames from the original video and also the dups created by repeating each frame of original video
# However, at each point where motion-estimated frame was inserted, no decimation occurs. Thus, if dups=drops, and the drop happens 
# within < "cycle" (TDecimate parameter) of the dup, the dup will be removed and the drop will be filled. 
# If no drops or dups occur within "cycle," then no motion estimation happens, and decimation merely gets back to original, 
# unchanged video.
#
#########################################################################################


function DeJump (clip c, float "jumpthresh", float "thresh", int "dcycle", bool "showdot")
{

    jumpthresh  = Default(jumpthresh, 0.88)
    thresh      = Default(thresh, 0.4)
    dcycle      = Default(dcycle, 20) # decimation cycle is parametrized (JKyle)
    showdot     = Default(showdot, false)

    Assert(IsYUV(c)==true && IsPlanar(c)==true, "DeJump supports planar YUV formats only") # input clip pixel type warning (JKyle)

    source = c#.KillAudio # removed `ConvertToYV12` to support HBD, and removed `KillAudio` (JKyle)
    newnum = source.FrameRateNumerator * 2 # added for `double` (JKyle)
    newden = source.FrameRateDenominator # added for `double` (JKyle)
    blackframe = BlankClip(source, color=color_black)
    # removed internalized `whiteframe` (JKyle)

    super = showdot ? source.Subtitle("***").MSuper(pel=2) : source.MSuper(pel=2)
    bvec  = MAnalyse(super, overlap=0, blksize=16, isb=true, search=4, dct=0)
    fvec  = MAnalyse(super, overlap=0, blksize=16, isb=false, search=4, dct=0)
    double = source.MFlowFps(super, bvec, fvec, num=newnum, den=newden, blend=false)

    # generate a white or black frame, depending on frame difference
    bwmask = GenerateMask(source, jumpthresh)

    # generate the 2x framerate mask needed to choose the motion-estimated frames
    themask = Interleave(blackframe, Trim(bwmask, 1, 0))

    # merge double framerate from original with motion-esimated frames, but only where there are jumps
    # (i.e., original frames are used except at jump points)
    Interleave(source, source).mt_merge(double, themask, luma=true, U=3, V=3)

    # decimate part
    dcycle = (dcycle%2==0) ? dcycle : dcycle+1 # assign the smallest even number >= dcycle as the decimation cycle (JKyle)
    
    RequestLinear
    # decimate half of all frames (set to twice the length of "normal" dup/drop cycle)
    decimated = TDecimate(display=false, mode=1, cycleR=dcycle/2, cycle=dcycle)

    # some repeats are still left after decimation, so fix those as well
    final = FillDrops(decimated, thresh)
    return final

}


#----------------
# This function returns a white clip whenever a big jump is detected; otherwise a black clip is returned
# Each YDiff must eliminate Ydiff=0 (duplicate) from moving average

# `jumpthresh` argument added for internal use (JKyle)

function GenerateMask (clip c, float jumpthresh)
{

    blackframe = BlankClip(c, color=color_black) # internalized for `GenerateMask` (JKyle)
    whiteframe = BlankClip(c, color=color_white) # internalized for `GenerateMask` (JKyle)
    mymask = c.ScriptClip("""
    \ (( (YDifferenceFromPrevious(SelectEvery(c, 1, 2)) < 0.3 ? 
    \       YDifferenceFromPrevious(SelectEvery(c, 1, 3))  :
    \       YDifferenceFromPrevious(SelectEvery(c, 1, 2)) )
    \  +
    \    (YDifferenceFromPrevious(SelectEvery(c, 1, 1)) < 0.3 ? 
    \     YDifferenceFromPrevious(SelectEvery(c, 1, 2))  :
    \     YDifferenceFromPrevious(SelectEvery(c, 1, 1))  )
    \  +
    \    (YDifferenceFromPrevious(SelectEvery(c, 1, -1)) < 0.3 ? 
    \     YDifferenceFromPrevious(SelectEvery(c, 1, -2))  :
    \     YDifferenceFromPrevious(SelectEvery(c, 1, -1))  )
    \  +
    \    (YDifferenceFromPrevious(SelectEvery(c, 1, -2)) < 0.3 ? 
    \     YDifferenceFromPrevious(SelectEvery(c, 1, -3))  :
    \     YDifferenceFromPrevious(SelectEvery(c, 1, -2))  )
    \     )/4) / 
    \    (YDifferenceFromPrevious(c) + 0.01) <= jumpthresh 
    \ ? whiteframe : blackframe """)
    return mymask

}
