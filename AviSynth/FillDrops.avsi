#########################################################################################
#
# FillDrops.avsi
#
# mod 2021-07-10
# 
# - based on Mug Funky's FillDrops
# - FillDrops by johnmeyer on Doom9's forum
# https://forum.doom9.org/showthread.php?p=1775184#post1775184
# - mod by Selur to parametrize Luma Difference Threshold
# https://forum.videohelp.com/threads/402416-repair-Videos-with-duplicates-and-dropped-frames#post2624936
#
### Requirements ###
#-------------------
# MvTools2 (https://github.com/pinterf/mvtools)
#
### Changelog ###
#---------------
# Changed requirements: from MvTools to MvTools2 (johnmeyer)
# Parametrized Luma Difference Threshold (Selur)
#
#########################################################################################

function FillDrops(clip c, float "thresh")
{
  thresh = Default(thresh, 0.1)

  super = MSuper(c, pel=2)
  vfe = MAnalyse(super, truemotion=true, isb=false, delta=1)
  vbe = MAnalyse(super, truemotion=true, isb=true, delta=1)
  filldrops = MFlowInter(c, super, vbe, vfe, time=50)
  fixed = ConditionalFilter(c, filldrops, c, "YDifferenceFromPrevious()", "lessthan", String(thresh))
  return fixed
}