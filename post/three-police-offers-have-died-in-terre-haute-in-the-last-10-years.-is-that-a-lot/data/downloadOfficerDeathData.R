library(tidyverse)
library(rvest)

firstYear <- 1980
lastYear <- 2021

years <- seq(firstYear,lastYear)

totalRecords <- 7588 # this is just hard coded because I couldn't think of a clever way to do it programmatically
records <- tibble()



#while(recordsDownloaded <= totalRecords) {
for(year in years) {
  
  print(str_c("Year: ", year))
  offset = 0
  
  # Read in the total number of records
  odmpURL <- str_c("https://www.odmp.org/search?from=",
                   year,
                   "&to=",
                   year,
                   "&filter=nok9&o=",
                   offset)
  header <- read_html(odmpURL) %>%
    html_elements("header") %>%
    html_text2() %>%
    str_split("\n\n")
  results <- str_split(header[[2]][2], " ")
  nRecords <- as.numeric(results[[1]][7])
  print(str_c("Number of deaths found: ", nRecords))
  
  # Loop through result pages while there are still records at this year
  
  while(offset < nRecords) {
    
    odmpURL <- str_c("https://www.odmp.org/search?from=",
                     year,
                     "&to=",
                     year,
                     "&filter=nok9&o=",
                     offset)
    pageRecords <- read_html(odmpURL) %>%
      html_elements(".officer-details") %>%
      html_text2()
    pageRecords <- as_tibble(pageRecords)
    
    # If no records were found, continue to the next year
    # if(nrow(pageRecords) < 1) {
    #   break
    # }
    
    pageRecords <- pageRecords %>%
      separate(value, into = c("name", "department", "EOW", "cause", "location"), sep = "\n\n") %>%
      mutate(EOW = str_remove(EOW, "^EOW: ")) %>%
      mutate(EOW = str_remove(EOW, 
                              "^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday), ")) %>%
      mutate(EOW = parse_date(EOW, "%B %d, %Y")) %>%
      separate(department, into = c("dept_name", "state"), sep = ", ", remove = FALSE) %>%
      mutate(year = year)
    
    records <- records %>% bind_rows(pageRecords)
    
    # if (recordsDownloaded %% 100 == 0) {
    #   print(str_c("Record ", recordsDownloaded))
    # }
    #recordsDownloaded <- recordsDownloaded + nrow(pageRecords)
    
    offset <- offset + nrow(pageRecords)
    
    Sys.sleep(0.1)
  }
  
}

#write_csv(records, "data/officerDeathData_80-21.csv", append = TRUE)