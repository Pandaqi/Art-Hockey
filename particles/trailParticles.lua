local emitterParams = {
  emitterType = 0,
  
  particleLifespan = 1.5,
  particleLifespanVariance = 0.5,
  maxParticles = 50,
  
  startParticleSize = 10,
  startParticleSizeVariance = 5,
  
  finishParticleSize = -1,
  finishParticleSizeVariance = 0,

  textureFileName = "particles/ballParticle.png",

  gravityx = 0,
  gravityy = 0,
  
  speed = 0,
  speedVariance = 0,
  
  duration = -1,
  
  startColorAlpha = 0.5,
  startColorGreen = 1,
  startColorBlue = 1,
  startColorRed = 1,
  
  finishColorAlpha = 0,
  finishColorGreen = 1,
  finishColorBlue = 1,
  finishColorRed = 1,
  
  angleVariance = 0,
  angle = 0,
  
  -- WHAT'S THIS SORCERY??
  -- (apparently, you want different settings on different backgrounds (more white/more black))
  --blendFuncSource = 0,
  --blendFuncDestination = 769,
  
  -- ABOUT BLEND MODES:
  -- URL: http://www.glprogramming.com/blue/ch05.html#id5452795
  -- URL (all options for EmitterObject in Corona): https://docs.coronalabs.com/api/type/EmitterObject/index.html
  -- URL (another thing about blending; not directly applicable): http://ssp.impulsetrain.com/porterduff.html
  
  --blendFuncSource = 768,
  --blendFuncDestination = 774,
  
  blendFuncSource = 1,
  blendFuncDestination = 771,
}

return emitterParams