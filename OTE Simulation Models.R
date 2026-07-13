# This code is for the different simulation models for my option trading engine.

GBM_MC = function(asset.data, asset.state, horizon, steps, iters){
  S.0 = asset.data$current.price
  mu = asset.state$mu
  sigma = asset.state$sigma
  T = horizon/252
  dt = T/steps
  paths = matrix(0, nrow = steps + 1, ncol = iters)
  paths[1,] = S.0
  
  for(i in 2:(steps+1)){
    Z = rnorm(iters)
    paths[i,] = paths[i-1,]*exp((mu - 0.5*sigma^2)*dt + sigma*sqrt(dt)*Z)
  }
  
  simulation = list(model = "GBM", ticker = asset.data$ticker, horizon = horizon, steps = steps, iters = iters, parameters = list(S.0 = S.0, mu = mu, sigma = sigma), paths = paths, terminal.prices = paths[nrow(paths),], diagnostics = list(runtime = NULL, warnings = NULL, convergence = NULL))
  class(simulation) = "Simulation Result"
  return(simulation)
}