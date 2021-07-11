/*
# CASm
#
# An improved sharpening script based on CAS and aWarpSharp2
#
# Original work by Atak_Snajpera for RipBot264
# Renamed and modded by JKyle 2021-04-22 for StaxRip
#
# ---Requirements---
#
# Core plugins:
#    CAS
#    aWarpSharp2
#
# ---Parameters---
# 
# float "strength" (default: 1.0)
# ----------------------------
# Same as CAS's parameter.
# Must be between 0.0 and 1.0.
#
*/

function CASm(clip video, float "strength")
{
strength = default(strength, 1.0)

LevelLimit = (video.BitsPerComponent == 8) ? 255 : 1023
IntensityMask = ConvertToY(video).Levels(0, 2, LevelLimit, 0, LevelLimit, coring = false)
EdgeMask = aSobel(IntensityMask, chroma = 0, thresh = 255, SetAffinity = false).invert.Levels(0, 2, LevelLimit, 0, LevelLimit, coring=false).Blur(1)
SharpMask = Overlay(IntensityMask, EdgeMask, mode = "Multiply", opacity = 1.0)
SharpenedVideo = CAS(video, strength)
video = Overlay(video, SharpenedVideo, mask = SharpMask, opacity = 1.0)

return video
}