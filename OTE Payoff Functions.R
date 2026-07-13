# This code is for the Payoff functions for my options research engine.

covered_call = function(S, S.0, long.contract = NULL, short.contract){
  K = short.contract$Strike
  premium = short.contract$Premium
  
  stock.PL = S - S.0
  short.call.PL = premium - pmax(S-K,0)
  PL = stock.PL + short.call.PL
  return(PL)
}

cash_secured_put = function(S, S.0 = NULL, long.contract = NULL, short.contract){
  K = short.contract$Strike
  premium = short.contract$Premium
  PL = premium - pmax(K-S,0) 
  return(PL)
}

long_call = function(S, S.0 = NULL, long.contract, short.contract = NULL){
  K = long.contract$Strike
  premium = long.contract$Premium
  PL = pmax(S - K, 0) - premium
  return(PL)
}

long_put = function(S, S.0 = NULL, long.contract, short.contract = NULL){
  K = long.contract$Strike
  premium = long.contract$Premium
  PL = pmax(K - S, 0) - premium
  return(PL)
}

bull_call_spread = function(S, S.0 = NULL, long.contract, short.contract){
  K.long = long.contract$Strike
  premium.long = long.contract$Premium
  K.short = short.contract$Strike
  premium.short = short.contract$Premium
  
  long.payoff = pmax(S - K.long, 0) - premium.long
  short.payoff = premium.short - pmax(S - K.short, 0)
  PL = long.payoff + short.payoff
  return(PL)
}

bear_put_spread = function(S, S.0 = NULL, long.contract, short.contract){
  K.long = long.contract$Strike
  premium.long = long.contract$Premium
  K.short = short.contract$Strike
  premium.short = short.contract$Premium
  
  long.payoff = pmax(K.long-S,0) - premium.long
  short.payoff = premium.short - pmax(K.short-S,0)
  PL = long.payoff + short.payoff
  return(PL)
}
