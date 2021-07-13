##############################################################
# 
# FillDrops
# 
# A filter to detect and replace duplicate frames
# with a motion-interpolation of the adjacent frames.
# 
# This is a VapourSynth port of FillDrops by johnmeyer
# https://forum.doom9.org/showthread.php?p=1775184#post1775184
# 
# By Selur and Myrsloik
# https://forum.doom9.org/showthread.php?p=1947291#post1947291
# 
# Mod by JKyle for StaxRip
# 
# Last update 2021-07-11
# 
##############################################################
# 
# Requirements:
# MVTools (https://github.com/dubhater/vapoursynth-mvtools)
# 
##############################################################
# 
# Syntax:
# filldrops.FillDrops(clip, thresh=0.1)
#
# Argument:
# thresh (default=0.1) - Luma Difference Threshold
#    Lets you specify how different a frame has to be (from the previous frame)
#    before it's considered not to be a duplicate, and therefore not replaced with a motion interpolated frame.
#    If the threshold is too small, some duplicate will not be replaced.
#    If it's too large, many frames which aren't duplicates (just having very small motions) will be replaced.
#    (explanation by jagabo on VideoHelp)
# 
##############################################################

import vapoursynth as vs

def FillDrops(clip, thresh=0.1):
    core = vs.get_core()
    if not isinstance(clip, vs.VideoNode):
        raise ValueError('This is not a clip')

    diffclip = core.std.PlaneStats(clip, clip[0] + clip)
    super = core.mv.Super(clip, pel=2)
    vfe = core.mv.Analyse(super, truemotion=True, isb=False, delta=1)
    vbe = core.mv.Analyse(super, truemotion=True, isb=True, delta=1)
    filldrops = core.mv.FlowInter(clip, super, mvbw=vbe, mvfw=vfe, time=50)
    def selectFunc(n, f):
        if f.props['PlaneStatsDiff'] < thresh:
            return clip
        else:
            return filldrops

    fixed = core.std.FrameEval(clip, selectFunc, prop_src=diffclip)
    return fixed
