# This code is for gathering the data from the market and having synthetic data for my option trading engine.

Real_Option_Chain = function(ticker){
  library(quantmod)
  chain = getOptionChain(ticker, Exp = NULL)
  option.chain = data.frame()
  
  for(exp in names(chain)){
    calls = chain[[exp]]$calls
    
    if(!is.null(calls) && nrow(calls) > 0){
      premium = ifelse(calls$Last > 0, calls$Last, (calls$Bid + calls$Ask)/2)
      calls = data.frame(Strike = as.numeric(calls$Strike), Premium = as.numeric(premium), Volume = as.numeric(calls$Vol), Open.Interest = as.numeric(calls$OI), IV = as.numeric(calls$IV), Type = "Call", Expiration = as.Date(calls$Expiration), stringsAsFactors = FALSE)
      option.chain = rbind(option.chain, calls)
    }
    
    puts = chain[[exp]]$puts
    
    if(!is.null(puts) && nrow(puts) > 0){
      premium = ifelse(puts$Last > 0, puts$Last, (puts$Bid + puts$Ask)/2)
      puts = data.frame(Strike = as.numeric(puts$Strike), Premium = as.numeric(premium), Volume = as.numeric(puts$Vol), Open.Interest = as.numeric(puts$OI), IV = as.numeric(puts$IV), Type = "Put", Expiration = as.Date(puts$Expiration), stringsAsFactors = FALSE)
      option.chain = rbind(option.chain, puts)
    }
  }
  
  if(nrow(option.chain) == 0){
    return(NULL)
  }
  
  option.chain = option.chain[complete.cases(option.chain),]
  option.chain = subset(option.chain, Strike > 0 & Premium > 0 & Expiration >= Sys.Date())
  
  minimum.premium = .05
  option.chain = subset(option.chain, Premium >= minimum.premium)
  
  option.chain = subset(option.chain, IV > 0 & is.finite(IV))
  
  option.chain = subset(option.chain, !(Volume == 0 & Open.Interest == 0))
  
  option.chain = option.chain[!duplicated(option.chain[,c("Expiration", "Type", "Strike")]),]
  
  option.chain = option.chain[order(option.chain$Expiration, option.chain$Type, option.chain$Strike),]
  
  rownames(option.chain) = NULL
  option.chain = data.frame(ID = seq_len(nrow(option.chain)), option.chain)
  return(option.chain)
}

Get_Data = function(universe){
  library(quantmod)
  market.data = list()
  for(ticker in universe){
    stock = suppressWarnings(getSymbols(ticker, src = "yahoo", auto.assign = FALSE))
    returns = dailyReturn(Ad(stock), type = "log")
    current.price = as.numeric(last(Ad(stock)))
    option.chain = tryCatch(Real_Option_Chain(ticker), error = function(e) NULL)
    market.data[[ticker]] = list(ticker = ticker, prices = stock, adjusted.prices = Ad(stock), returns = returns, current.price = current.price, option.chain = option.chain, risk.free.rate = NULL, dividend.yield = NULL)
  }
  class(market.data) = "Market Data"
  return(market.data)
}

Exact.Price.GBM = function(S.0, T, r, sigma, K, type){
  d1 = (log(S.0/K) + (r + 0.5*sigma^2)*T) / (sigma*sqrt(T))
  d2 = d1 - sigma*sqrt(T)
  
  if(type == "call"){
    price = S.0*pnorm(d1) - K*exp(-r*T)*pnorm(d2)
  } else {
    price = K*exp(-r*T)*pnorm(-d2) - S.0*pnorm(d1)
  }
  return(price)
}

Synthetic_Option_Chain = function(S.0, sigma, r = 0.04, expiration = 45, strike.spacing = 5){
  T = expiration/252
  strikes = seq(floor(S.0*.8/strike.spacing)*strike.spacing, ceiling(S.0*1.2/strike.spacing)*strike.spacing, by = strike.spacing)
  call.premiums = sapply(strikes, function(K){
    Exact.Price.GBM(S.0 = S.0, T = T, r = r, sigma = sigma, K = K, type = "call")
  })
  put.premiums = sapply(strikes, function(K){
    Exact.Price.GBM(S.0 = S.0, T = T, r = r, sigma = sigma, K = K, type = "put")
  })
  calls = data.frame(Strike = strikes, Premium = call.premiums, Type = "Call", Expiration = expiration)
  puts = data.frame(Strike = strikes, Premium = put.premiums, Type = "Put", Expiration = expiration)
  option.chain = rbind(calls, puts)
  option.chain = data.frame(ID = 1:nrow(option.chain), option.chain)
  return(option.chain)
}

Market_State = function(market.data){
  library(moments)
  market.state = list()
  
  for(ticker in names(market.data)){
    asset = market.data[[ticker]]
    r = na.omit(asset$returns)
    
    mu = mean(r)*252
    sigma = sd(r)*sqrt(252)
    
    skew = skewness(r)
    kurt = kurtosis(r)
    trend = if(mu > 0){
      "Bull"
    } else {
      "Bear"
    }
    vol.regime = cut(sigma, breaks = c(-Inf, .15, .30, Inf), labels = c("Low", "Moderate", "High"))
    market.state[[ticker]] = list(mu = mu, sigma = sigma, trend = trend, volatility.regime = as.character(vol.regime), skewness = skew, kurtosis = kurt)
  }
  class(market.state) = "Market State"
  return(market.state)
}

Candidate_Universe = function(asset.data, research.parameters, quality.filters){
  option.chain = asset.data$option.chain
  
  if(is.null(option.chain) || nrow(option.chain) == 0){
    return(option.chain)
  }
  
  today = Sys.Date()
  option.chain$Days.To.Expiration = as.numeric(as.Date(option.chain$Expiration) - today)
  option.chain = subset(option.chain, Days.To.Expiration >= research.parameters$Min.Days & Days.To.Expiration <= research.parameters$Max.Days)
  
  if(nrow(option.chain) == 0){
    return(option.chain)
  }
  
  S.0 = asset.data$current.price
  lower.strike = S.0*(1 - research.parameters$Strike.Range)
  upper.strike = S.0*(1 + research.parameters$Strike.Range)
  option.chain = subset(option.chain, Strike >= lower.strike & Strike <= upper.strike)
  
  if(nrow(option.chain) == 0){
    return(option.chain)
  }
  
  option.chain = subset(option.chain, Volume >= quality.filters$Minimum.Volume & Open.Interest >= quality.filters$Minimum.Open.Interest)
  
  if(nrow(option.chain) == 0){
    return(option.chain)
  }
  
  option.chain = subset(option.chain, IV >= quality.filters$Minimum.IV & IV <= quality.filters$Maximum.IV)
  
  if(nrow(option.chain) == 0){
    return(option.chain)
  }
  
  option.chain = option.chain[order(option.chain$Expiration, option.chain$Type, option.chain$Strike),]
  
  rownames(option.chain) = NULL
  return(option.chain)
}