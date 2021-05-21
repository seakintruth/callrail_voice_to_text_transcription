if (!require("pacman")) install.packages("pacman")
pacman::p_load(httr,jsonlite,getPass,tcltk,curl,RCurl,stringr)
#
# If a file path is not passed we prompt for a file or the secrets
# The secrets file is a R file that wil be sourced that contains a named character vector like:
#apiClient <- c(
#	ID = "some...",
#	Secret = "value..."
#)
# or an .RDS file containing just that vector created with
# saveRDS(apiClient,apiClientIdSecretPath)  
#
# If you use a secrets file or include the apiKeyRdsPath a API Key file will be added to the 
# parent folder for later re-use of the valid API key by this function
get.access.token <- function(
  apiClientIdSecretPath="",
  apiKeyRdsPath=""
){
  .getApiKeyIfValid <- function(apiKeyRdsPath){
    if(
      file.exists(apiKeyRdsPath) && 
      tolower(tools::file_ext(apiKeyRdsPath)) == "rds"
    ){
      token <- readRDS(apiKeyRdsPath)
      #Determin if the token has expired or will within a day
      if (
        as.numeric(unname(token["expiresIn"]))>
        (as.numeric(Sys.time())+(60*60*24))
      ){
        return(token)
      } else {
        return(NULL)
      }
    } else {
      return(NULL)
    }  
  }
  potentialToken <- .getApiKeyIfValid(apiKeyRdsPath)
  if(is.null(potentialToken)){
    #internal helper function to manage the secrets file
    .readSecretsFile <- function(
      apiClientIdSecretPath="",
      defaultFilename=basename(apiClientIdSecretPath)
    ){
      selectKeyMethodOne <- " By entering values in a prompt "
      selectKeyMethodTwo <- paste0(" By selecting the secrets file (.R or .RDS) ")
      apiClient <- NULL
      if(!file.exists(apiClientIdSecretPath)){
        Filters <- matrix(
          c(
            "RDS file", ".RDS",
            "RDS file", ".rds", 
            "R code", ".R",
            "R code", ".r",
            "R code", ".s",
            "All files", "*"
          ),
          6, 2, byrow = TRUE
        )
        apiClientIdSecretPath <- tcltk::tk_choose.files(
          default=defaultFilename,
          caption=paste0("Select ",selectKeyMethodTwo),
          multi = FALSE, filters=Filters
        )
      }
      pathExt <- tolower(tools::file_ext(apiClientIdSecretPath))
      if(pathExt == "r") {
        source(apiClientIdSecretPath)	
        apiClient <- CallRail_APIV3Key
      } else if(pathExt == "rds"){
        apiClient <- readRDS(apiClientIdSecretPath)
      }
      return(apiClient)
      rm("apiClient")
    }
    # set some default values
    if(curl::has_internet()){
      fCancel <- FALSE
      strCancelMsg <- ""
    } else {
      fCancel <- TRUE
      strCancelMsg <- "no internet connection;"
    }	
    selectKeyMethodOne <- " By entering values in a prompt "
    selectKeyMethodTwo <- paste0(" By selecting the secrets file (.R or .RDS) ")
    if((!fCancel) && (!file.exists(apiClientIdSecretPath))){
      selectedKeyMethod <- NULL
      selectedKeyMethod <- tcltk::tk_select.list(
        c(
          selectKeyMethodOne,
          selectKeyMethodTwo,
          "","",""
        ), 
        title = paste0(
          "\n\tSelect one of the following methods to \t\n",
          "\tsupply the application ID and Secret \t\n"
        )
      )
      if(selectedKeyMethod == selectKeyMethodOne){
        strApiClientID <- getPass::getPass(
          "Enter the API Client ID", 
          noblank = TRUE, 
          forcemask = TRUE
        )			
        strApiClientSecret <- getPass::getPass(
          "Enter the API Client Secret", 
          noblank = TRUE, 
          forcemask = TRUE
        )
        return(
          c(
            strApiClientID,
            strApiClientSecret
          )
        )  
      } else if(selectedKeyMethod == selectKeyMethodTwo){
        apiClient <- .readSecretsFile(apiClientIdSecretPath)

        return(apiClient)
      } else {
        fCancel <- TRUE
        strCancelMsg <- paste0(strCancelMsg,"user aborted secret selection method;")
        return(NULL)
      }
    } else if(!fCancel){
      apiClient <- .readSecretsFile(apiClientIdSecretPath)
      strApiClientID <- unname(apiClient["ID"])
      strApiClientSecret <- unname(apiClient["Secret"])
      return(apiClient)
    }		
    if (fCancel){
      tcltk::tkmessageBox(
        message=paste0("\nError: ",strCancelMsg ,"\n "),
        title="Get API Access Token"
      )
      return(NULL)
    }
  } else { 
    # potentialToken is not expired so let's use it
    # if we get an error on first use that the token is invalid then
    # we should delete the apiToken file and call this function again
    return(potentialToken["accessToken"])
  }
}

test <- get.access.token()