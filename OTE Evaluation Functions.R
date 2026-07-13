# This code is for performing statistical analysis on the data and ranking strategies for my option research engine.

Trade_Summary = function(results){
  summary.results = data.frame()
  
  for(result in results){
    PL = result$PL
    expected.PL = mean(PL)
    
    summary.results = rbind(summary.results, data.frame(Ticker = result$ticker, Model = result$model, Strategy = result$strategy, Capital.Required = result$capital.required, Expected.PL = expected.PL, Expected.Return = expected.PL/result$capital.required, Probability.Profit = mean(PL > 0), Median = median(PL), VaR5 = quantile(PL, .05), SD = sd(PL), Min.PL = min(PL), Max.PL = max(PL), stringsAsFactors = FALSE))
  }
  rownames(summary.results) = NULL
  return(summary.results)
}

Evaluate_Strategies = function(strategies, simulation, asset.data, strategy.registry){
  results = vector("list", length = nrow(strategies))
  S.T = simulation$terminal.prices
  S.0 = simulation$parameters$S.0
  option.chain = asset.data$option.chain
  
  for(i in seq_len(nrow(strategies))){
    long.contract = NULL
    short.contract = NULL
    
    if(!is.na(strategies$Long_Row[i])){
      long.contract = option.chain[strategies$Long_Row[i],]
    }
    
    if(!is.na(strategies$Short_Row[i])){
      short.contract = option.chain[strategies$Short_Row[i],]
    }
    
    if(!is.null(long.contract) && nrow(long.contract) != 1){
      stop("Invalid long conttract.")
    }
    
    if(!is.null(short.contract) && nrow(short.contract) != 1){
      stop("Invalid short contract.")
    }
    
    # Evaluate Strategy
    strategy = strategies$Strategy[i]
    payoff.function = strategy.registry[[strategy]]$payoff
    
    if(!(strategy %in% names(strategy.registry))){
      stop(paste("Uknown Strategy:", strategy))
    }
    
    PL = payoff.function(S = S.T, S.0 = S.0, long.contract = long.contract, short.contract = short.contract)
    
    if(any(is.na(PL))){
      stop(paste("NA values produced for", strategy))
    }
    results[[i]] = list(ticker = simulation$ticker, model = simulation$model, strategy = strategy, capital.required = strategies$Capital.Required[i], max.loss = strategies$Max.Loss[i], max.profit = strategies$Max.Profit[i], long.row = strategies$Long_Row[i], short.row = strategies$Short_Row[i], long.contract = long.contract, short.contract = short.contract, PL = PL)
  }
  names(results) = strategies$Strategy
  class(results) = "Strategy Results"
  return(results)
}

Rank_Strategies = function(summary.results){
  rankings = summary.results[order(-summary.results$Expected.Return, -summary.results$Probability.Profit, summary.results$SD),]
  rownames(rankings) = NULL
  return(rankings)
}
