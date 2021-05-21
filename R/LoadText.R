setwd("~/git/callrail_voice_to_text")
if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  jsonlite, stringr,
  feather,writexl,dplyr,
  readxl, fs, readr, lubridate
)
phoneCallResults <- feather::read_feather(
  fs::path(
    getwd(),
    "Data",
    "phoneCallResults.feather"
  )
)
phoneCallResults$WavTextPath <- paste(
  fs::path(
    getwd(),"Data","WavToTextResults",phoneCallResults$id
  ),
  "txt",
  sep="."
)
phoneCallResults$WavFileExists <- file.exists(phoneCallResults$WavTextPath)

textFilesToImport <- phoneCallResults %>% 
  select("WavTextPath","WavFileExists","id") %>%
  filter(WavFileExists==TRUE) 

getJsonResults <- function(strFilePath){
  jsonResults <- jsonlite::read_json(as.character(strFilePath))
  getText <- function(element){
    jsonResults[[element]]$text
  }
  textResults <- lapply(1:length(jsonResults),FUN = getText)
  textResults <- replace(unlist(textResults),NULL,"")
  textResults <- paste(textResults,collapse = ", ")
  return(textResults)
}

textFilesToImport$readWavText <- unlist(lapply(textFilesToImport$WavTextPath,FUN=getJsonResults))
str(textFilesToImport)
results <- left_join(phoneCallResults,textFilesToImport,by = "id")

results <- results %>% 
  dplyr::select(
    created_at,
    id,
    answered,
    voicemail,
    recording_duration,
    recording_player,
    readWavText,
    company_name,
    business_phone_number,
    tracking_phone_number,
    customer_phone_number,
    customer_city,
    customer_country,
    customer_name,
    customer_state,
    duration,
    start_time,
    source,
    company_time_zone,
    first_call,
    prior_calls,
    total_calls,
    source_name,
    lead_status,
    WavTextPath.x,
    WavFileExists.x
  ) %>%
  dplyr::mutate(
    recording_player = xl_hyperlink(recording_player, name = id)
  )

results <- results %>% 
  dplyr::mutate(
    created_at = na.omit(
      lubridate::ymd_hms(results$created_at,"%Y/%m/%dT%H:%M:%S")
    )
  )

writexl::write_xlsx(
  results,
  fs::path(
    getwd(),
    "Reports",
    "AllTime-Transcribed.xlsx"
  )
)

monthlyReport <- results %>%
  filter(
    ( 
      created_at > (Sys.time()-(60*60*12*35)) 
    ) & (
      voicemail == 1 | WavFileExists.x == 1
    )    
  )


 writexl::write_xlsx(
  monthlyReport,
  fs::path(
    getwd(),
    "Reports",
    "PreviousMonth-Transcribed.xlsx"
  )
)
 
