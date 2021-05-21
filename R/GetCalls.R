setwd("~/git/callrail_voice_to_text")

if (!require("pacman")) install.packages("pacman")
pacman::p_load(
  httr,jsonlite,curl,RCurl,stringr,feather,writexl,readxl,
  stringr,fs,dplyr,readr,googleLanguageR
)
# or use openxlsx or writexl

callRailKeyRdsPath <- fs::path(getwd(),"Credentials","CallRailApi.RDS")

if (file.exists(callRailKeyRdsPath)){
    credentials <- readRDS(callRailKeyRdsPath)
} else {
    source(fs::path(getwd(),"R","LoadApiKey.R"))
    credentials <- get.access.token()
    saveRDS(credentials,callRailKeyRdsPath)
}

# Using Curl to query the api
h <- curl::new_handle()
curl::handle_setopt(h,customrequest = "GET")
curl::handle_setheaders(
  h,
  Authorization=paste0(
    "Token token=",
    credentials['Secret']
  )
)
getApiReturn <- function(requestedUrl,h){
  urlReturn <- curl::curl_fetch_memory(
    url=requestedUrl,
    handle=h
  )
  strMessage <- paste0("getApiReturn::Querying:",requestedUrl)
  message(strMessage)
  readr::write_lines(strMessage,file = "log.txt")
  while (!is.null(fromJSON(rawToChar(urlReturn$content))$error)){
    strMessage <- paste0(Sys.time()," Sleeping for five  minutes and then try again...",":",requestedUrl)
    message(strMessage)
    readr::write_lines(strMessage,file = "log.txt")
    Sys.sleep(300) 
    urlReturn <- curl::curl_fetch_memory(
      url=requestedUrl,
      handle=h
    )
  }
  return(urlReturn)
}
assetUrl <- paste0(
  "https://api.callrail.com/v3/a/",
  credentials['ID'],
  "/calls.json?",
  "&date_range=all_time"
)
#Alternate date range would be 'all_time'

phoneCallsJson <- getApiReturn(assetUrl,h)
phoneCallsDf <- fromJSON(rawToChar(phoneCallsJson$content))
totalPages <- phoneCallsDf$total_pages
# build a list of all the pages that need to be called:
getphoneCallPage <- function(
  PageNumber
){
  
  if(
    fs::file_exists(  
      fs::path(
        getwd(),
        "Data",
        "phoneCallResults.feather"
      )
    )
  ){
    # Currently we are getting everything everytime
    # Should load previous data and use a filter  
    # dateFilter <- "date_range=last_year"
    # or set to start and end to only get the missing data to append.
    # [todo] still need to load previous data set 
    # then do start_date and end_date for last date in data set and append
    # until this is done leaving query the same, 
    # not implementing the best practice results in roughly 75 wasted api 
    # calls of the 1000 allowed per hour
  }
  dateFilter <- "date_range=all_time"
  urlQuery <- paste0(
    "https://api.callrail.com/v3/a/",
    credentials['ID'],
    "/calls.json?",
    "page=", 
    PageNumber,
    "&",dateFilter,
    "&fields=",
    "customer_name,",
    "customer_phone_number,",
    "duration,",
    "id,",
    "recording,",
    "recording_duration,",
    "recording_player,",
    "start_time,",
    "tracking_phone_number,",
    "voicemail,",
    "source,",
    "company_id,",
    "company_name,",
    "company_time_zone,",
    "created_at,",
    "customer_city,",
    "customer_country,",
    "landing_page_url,",
    "device_type,",
    "answered,",
    "first_call,",
    "prior_calls,",
    "total_calls,",
    "source_name,",
    "lead_status,",
    "waveforms,", 
    "speaker_percent,",
    "keywords_spotted,",
    "call_highlights"
  )
  h <- curl::new_handle()
  curl::handle_setopt(h,customrequest = "GET")
  curl::handle_setheaders(
    h,
    Authorization=paste0(
      "Token token=",
      credentials['Secret']
    )
  )
  phoneCallsGet <- get("getApiReturn")(urlQuery,h)
  phoneCallsGet <- fromJSON(rawToChar(phoneCallsGet$content))
  return(phoneCallsGet$calls)
}
phoneCallPage <- lapply(1:totalPages,FUN = getphoneCallPage)
# Format data frame for export to excel
phoneCallResults <- phoneCallPage[[1]]
bindCallPages <- function(pageNumber) {
  if(! pageNumber ==  1){
    phoneCallResults <<- bind_rows(phoneCallResults, phoneCallPage[[pageNumber]])
  }
  return(NULL)
}
NullResults <- lapply(FUN=bindCallPages,1:totalPages)
phoneCallResults$call_highlights <- str_c(unlist(phoneCallResults$call_highlights),collapse=',')
phoneCallResults$speaker_percent_agent <- str_c(unlist(phoneCallResults$speaker_percent$agent),collapse=',')
phoneCallResults$speaker_percent_customer <- str_c(unlist(phoneCallResults$speaker_percent$customer),collapse=',')
# call_highlight not needed, if needed must build as a function like waveforms...
# phoneCallResults$call_highlight <- str_c(unlist(phoneCallResults$call_highlights),collapse=',')
phoneCallResults$speaker_percent <- NULL
phoneCallResults$call_highlights <- NULL
waveFormSubList <- function (listElement){
  if(is.null(phoneCallResults$waveforms[[listElement]][[1]])){
    return(NA)
  } else {
    return(phoneCallResults$waveforms[[listElement]][[1]])  
  }
}
waveFormSubListSecondary <- function (listElement){
  if(is.null(phoneCallResults$waveforms[[listElement]][[2]])){
    return(NA)
  } else {
    return(phoneCallResults$waveforms[[listElement]][[2]])  
  }
}
phoneCallResults$waveformPrimary <-
  unlist(lapply(1:length(phoneCallResults$id),FUN=waveFormSubList))
phoneCallResults$waveformSecondary <- 
  unlist(lapply(1:length(phoneCallResults$id),FUN=waveFormSubListSecondary))
phoneCallResults$waveforms <- NULL

# save information 
feather::write_feather(
  phoneCallResults,
  fs::path(
    getwd(),
    "Data",
    "phoneCallResults.feather"
  )
)

writexl::write_xlsx(
  phoneCallResults,
  fs::path(
    getwd(),
    "Reports",
    paste0(
      "LastYear-phoneList.xlsx"
    )
  )
)

# Cleanup variables no longer needed, 
# Keeping variables 'phoneCallResults, credentials, and h'
rm(
  phoneCallPage,phoneCallsDf,
  phoneCallsJson,NullResults,
  callRailKeyRdsPath,
  totalPages
)
# Cleanup functions no longer needed
rm(
  bindCallPages,
  getphoneCallPage,
  waveFormSubList,
  waveFormSubListSecondary
)

getSoundAsset <- function(callElement){
  callId <- phoneCallResults$id[callElement]
  if (!is.na(phoneCallResults$recording[callElement])){
    destfileTemp <- fs::path(getwd(),"Data","SoundAssets",paste0(callId,".mp3"))
    if (!fs::file_exists(destfileTemp)){
      # only query and download if file is not in the soundAssets folder
      assetUrl <- phoneCallResults$recording[callElement]
      soundAssetUrlReturn <- get("getApiReturn")(assetUrl,h)
      downloadAttempt <- try(
        curl_download(
          url=fromJSON(rawToChar(soundAssetUrlReturn$content))$url,
          destfile = destfileTemp
        )
      )
    }
  }
  return(NULL)    
}
nullReturn <- lapply(1:length(phoneCallResults[,1]),FUN = getSoundAsset)

getSoundWavePrimaryImage <- function(callElement){
  callId <- phoneCallResults$id[callElement]
  if (!is.na(phoneCallResults$waveformPrimary[callElement])){
    destfileTemp <- fs::path(getwd(),"Data","SoundWaveImages-CallRail","Primary",paste0(callId,".png"))
    if (!fs::file_exists(destfileTemp)){
      # only query and download if file is not in the soundAssets folder
      assetUrl <- phoneCallResults$waveformPrimary[callElement]
      downloadAttempt <- try(
        curl_download(
          url=phoneCallResults$waveformPrimary[callElement],
          destfile = destfileTemp
        )
      )
    }
  }
  return(NULL)    
}
nullReturn <- lapply(1:length(phoneCallResults[,1]),FUN = getSoundWavePrimaryImage)

getSoundWaveSecondaryImage <- function(callElement){
  callId <- phoneCallResults$id[callElement]
  if (!is.na(phoneCallResults$waveformSecondary[callElement])){
    destfileTemp <- fs::path(getwd(),"Data","SoundWaveImages-CallRail","Secondary",paste0(callId,".png"))
    if (!fs::file_exists(destfileTemp)){
      # only query and download if file is not in the soundAssets folder
      assetUrl <- phoneCallResults$waveformSecondary[callElement]
      downloadAttempt <- try(
        curl_download(
          url=phoneCallResults$waveformSecondary[callElement],
          destfile = destfileTemp
        )
      )
    }
  }
  return(NULL)    
}
nullReturn <- lapply(1:length(phoneCallResults[,1]),FUN = getSoundWaveSecondaryImage)

# str(soundAssetUrl)
# str(destfiles)
rm(nullReturn)

if (!exists("phoneCallResults")){
  phoneCallResults <- readxl::read_xlsx( 
    path =   fs::path(
      getwd(),
      "Reports",
      paste0(
        "AllTime-phoneList.xlsx"
      )
    )
  )
}
