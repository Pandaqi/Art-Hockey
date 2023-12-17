local emitterParams = {
  emitterType = 0,
  
  particleLifespan = 0.4,
  particleLifespanVariance = 0.2,
  maxParticles = 20,
  
  startParticleSize = 10,
  startParticleSizeVariance = 5,
  
  finishParticleSize = -1,
  finishParticleSizeVariance = 0,
  
  startColorAlpha = 0.5,
  startColorGreen = 1,
  startColorBlue = 1,
  startColorRed = 1,
  
  finishColorAlpha = 0.5,
  finishColorGreen = 1,
  finishColorBlue = 1,
  finishColorRed = 1,

  textureFileName = "particles/ballParticle.png",

  gravityx = 0,
  gravityy = 0,
  
  speed = 100,
  speedVariance = 20,
  
  tangentialAcceleration = 100,
  tangentialAccelerationVariance = 0,
  
  duration = 0.1,
  
  angleVariance = 180,
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