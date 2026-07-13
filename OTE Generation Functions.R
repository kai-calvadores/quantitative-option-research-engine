# This code is for generating the strategies for my option research engine.

LC_Generation = function(asset.data){
  option.chain = asset.data$option.chain
  strategies = list()
  k = 1
  
  for(i in seq_len(nrow(option.chain))){
    contract = option.chain[i,]
    
    if(contract$Type != "Call")
      next
      
    strategies[[k]] = data.frame(Strategy = "Long_Call", Long_Row = i, Short_Row = NA, Capital.Required = contract$Premium*100, Max.Loss = contract$Premium*100, Max.Profit = Inf, stringsAsFactors = FALSE)
    k = k+1
  }
  if(length(strategies) == 0)
    return(data.frame())
  do.call(rbind, strategies)
}

LP_Generation = function(asset.data){
  option.chain = asset.data$option.chain
  strategies = list()
  k = 1
  
  for(i in seq_len(nrow(option.chain))){
    contract = option.chain[i,]
    
    if(contract$Type != "Put")
      next
    
    strategies[[k]] = data.frame(Strategy = "Long_Put", Long_Row = i, Short_Row = NA, Capital.Required = contract$Premium*100, Max.Loss = contract$Premium*100, Max.Profit = contract$Strike*100 - contract$Premium*100, stringsAsFactors = FALSE)
    k = k+1
  }
  if(length(strategies) == 0)
    return(data.frame())
  do.call(rbind, strategies)
}

CC_Generation = function(asset.data){
  option.chain = asset.data$option.chain
  current.price = asset.data$current.price
  strategies = list()
  k = 1
  
  for(i in seq_len(nrow(option.chain))){
    contract = option.chain[i,]
    
    if(contract$Type != "Call")
      next
    
    if(contract$Strike < current.price)
      next
    
    strategies[[k]] = data.frame(Strategy = "Covered_Call", Long_Row = NA, Short_Row = i, Capital.Required = current.price*100, Max.Loss = current.price*100, Max.Profit = NA, stringsAsFactors = FALSE)
    
    k = k+1
  }
  if(length(strategies) == 0)
    return(data.frame())
  
  do.call(rbind, strategies)
}

CSP_Generation = function(asset.data){
  option.chain = asset.data$option.chain
  current.price = asset.data$current.price
  strategies = list()
  k = 1
  
  for(i in seq_len(nrow(option.chain))){
    contract = option.chain[i,]
    
    if(contract$Type != "Put")
      next
    
    if(contract$Strike > current.price)
      next
    
    strategies[[k]] = data.frame(Strategy = "Cash_Secured_Put", Long_Row = NA, Short_Row = i, Capital.Required = contract$Strike*100, Max.Loss = contract$Strike*100 - contract$Premium*100, Max.Profit = contract$Premium*100, stringsAsFactors = FALSE)
    
    k = k+1
  }
  if(length(strategies) == 0)
    return(data.frame())
  
  do.call(rbind, strategies)
}

BCS_Generation = function(asset.data){
  option.chain = asset.data$option.chain
  call.rows = which(option.chain$Type == "Call")
  if(length(call.rows) < 2)
    return(data.frame())
  strategies = list()
  k = 1
  
  for(a in 1:(length(call.rows)-1)){
    for(b in (a+1):length(call.rows)){
      i = call.rows[a]
      j = call.rows[b]
      
      long = option.chain[i,]
      short = option.chain[j,]
      
      width = short$Strike - long$Strike
      
      if(width <= 0)
        next
      
      debit = long$Premium - short$Premium
      
      if(debit <= 0)
        next
      
      max.profit = (width - debit)*100
      
      if(max.profit <= 0)
        next
      
      strategies[[k]] = data.frame(Strategy = "Bull_Call_Spread", Long_Row = i, Short_Row = j, Capital.Required = debit*100, Max.Loss = debit*100, Max.Profit = max.profit, stringsAsFactors = FALSE)
      
      k = k+1
    }
  }
  if(length(strategies) == 0)
    return(data.frame())
  
  do.call(rbind, strategies)
}

BPS_Generation = function(asset.data){
  option.chain = asset.data$option.chain
  put.rows = which(option.chain$Type == "Put")
  if(length(put.rows) < 2)
    return(data.frame())
  strategies = list()
  k = 1
  
  for(a in 1:(length(put.rows)-1)){
    for(b in (a+1):length(put.rows)){
      i = put.rows[a]
      j = put.rows[b]
      
      long = option.chain[i,]
      short = option.chain[j,]
      
      width = short$Strike - long$Strike
      
      if(width <= 0)
        next
      
      debit = long$Premium - short$Premium
      
      if(debit <= 0)
        next
      
      max.profit = (width - debit)*100
      
      if(max.profit <= 0)
        next
      
      strategies[[k]] = data.frame(Strategy = "Bear_Put_Spread", Long_Row = i, Short_Row = j, Capital.Required = debit*100, Max.Loss = debit*100, Max.Profit = max.profit, stringsAsFactors = FALSE)
      
      k = k+1
    }
  }
  if(length(strategies) == 0)
    return(data.frame())
  
  do.call(rbind, strategies)
}

Generate_Strategies = function(asset.data, strategy.registry){
  strategies = list()
  
  for(strategy in names(strategy.registry)){
    generator = strategy.registry[[strategy]]$generator
    strategies[[strategy]] = generator(asset.data)
  }
  
  strategies = Filter(function(x) nrow(x) > 0, strategies)
  if(length(strategies) == 0)
    return(data.frame())
  strategies = do.call(rbind, strategies)
  rownames(strategies) = NULL
  return(strategies)
}
