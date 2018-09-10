library(dplyr)

tidy <- function(catch, drifts, verbose = FALSE){
  
  # initialize variables
  # max and min depth
  min_depth <- min(c(catch$start_depth, catch$end_depth))
  max_depth <- max(c(catch$start_depth, catch$end_depth))
  # max and min size
  max_size <- max(catch$size)
  min_size <- min(catch$size)
  # three letter site names
  sites <- unique(x = substr(drifts$IDCell.per.Trip, 0, 3))
  
  # initialize marticies
  # total CPUE
  total_CPUE <- matrix(0L, nrow = (max_depth - min_depth + 1), ncol = (max_size - min_size + 1))
  colnames(total_CPUE) <- c(dQuote(min_size:max_size))
  rownames(total_CPUE) <- c(dQuote(min_depth:max_depth))
  # site-specific CPUE
  CPUEperSite <- matrix(0L, nrow = (length(sites)), ncol = (max_size - min_size + 2))
  colnames(CPUEperSite) <- c("Site", dQuote(min_size:max_size))
  CPUEperSite[,1] <- sites
  # construct total effort for each depth
  # effort <- effort_function()
  
  # tidy dataframe (site, size, depth, CPUE)
  tidy_data <- data.frame(row.names = c("site", "size", "depth", "catch"))
  
  
  #loops
    # calculate CPUE per site
  tmp = vector("list", nrow(catch))
  for(x in 1:nrow(catch)){ #this will run through every row in the BLU_only_depths matrix
    # x counts the row of the BLU_only_depths matrix that is being currently worked on
    # determine if the start or end depth is deeper and save the deeper value
    # pmax stands for parallel maximum, which compares two columns and finds the maximum value
    deeper <- pmax(catch$start_depth[x], catch$end_depth[x])
    # determine if the start or end depth is shallower and save the shallower depth
    shallower <-pmin(catch$start_depth[x], catch$end_depth[x])
    # new dataframe to collect all the data in this iteration of the loop
    this_fish <- data.frame(site = c(rep(substr(catch$IDCell.per.Trip[x], 0, 3), times = (deeper - shallower +1))), size = c(rep(catch$size[x], times = (deeper - shallower +1))), depth = c(shallower:deeper), catch = c(rep(1, times = (deeper - shallower +1))))
    # Add 1 to the column associated with the fish's length and all the rows in the range of depths fished for that drift
      # tidy_data <- rbind(tidy_data, this_fish)
    tmp[[x]] = this_fish
    # time keeper
    if(verbose) print(x)
  }

    tidy_data = do.call(rbind, tmp)

return(tidy_data)    
    
  # tallies the number of columns that match the 'group_by' call and collapses them down to one row
  tidy_data <- tidy_data %>%
    group_by(site, size, depth) %>%
    tally()
  # matches the depth column in 'effort' to the depth column in 'tidy_data' and inputs the associated effort value as a new column in tidy-data
  tidy_data$effort <- effort[match(tidy_data$depth, effort$depth), 2]
  
  
  # Trying to control for the posibility that one site contributed the majority of the CPUE to the grand total, thereby masking the data from the other sites.
  # The way that it is being calculated here makes the assumption that, since they fished the same number of tansects, they fished for the same amount of time at each location
  # An ANOVA confirms that total drift times are not significantly different across sites
  # After calculating CPUE, total CPUE for each site is added up.
  # Then CPUE is divide by the site total
  
  # add a row that calculates CPUE based on total effort
  tidy_data <- mutate(tidy_data, CPUE = n/effort)
  # new variable that calculates the total CPUE per site
  CPUE_by_site <- tidy_data %>%
    group_by(site) %>%
    summarize(site_total_CPUE = sum(CPUE))
  # merge CPUE_by_site with tidy_data by matching the name 'site'
  tidy_data <- merge(tidy_data, CPUE_by_site, by='site')
  tidy_data <- mutate(tidy_data, normalized_CPUE = CPUE/site_total_CPUE)
  
  
  return(tidy_data)
}
