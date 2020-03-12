# Infection Alert
## Executive Summary 

Early detection is crucial in stopping the spread of infection. We should use all the tools at our disposal. 

Infections elevate your resting heart rate, sometimes even before you can feel the sysmtoms or the temperature is elevated. [1](https://www.thelancet.com/journals/landig/article/PIIS2589-7500(19)30222-5/fulltext)

Weareables provide an accurate way to measure sleeping resting heart rate by wearing the watch durring the night.

We first create a personal baseline over a couple of nights, then every morning compare the recording with the previous baseline.  

Elevation of the resting heart rate over the baseline could indicate an infection. 

We display a green/✅ (not elevated) red/❗ (elevated) symbol on the apple watch face and anonymously collect the data into a public database.

There are other factors that could evelevate the resting heart rate, such as: 
 - high stress
 - Alcohol 
 - lack of sleep.
 - ... 
 But the user is usualy aware of them.

I expect this to have a fairly low false negative rate (high sensitivity) but prety high false positive rate (low specificity). 

## Method of collection

Apple watch collects heart rate data continuously. The users would idealy wear the watch durring the night.

Data is extracted from the Apple HealtKit API in the morning, and resting heart rate elevation calculated.

### Collecting with a phone (without apple watch)

Resting Heart Rate can be measureed with a smartphone app (Instant Heart Rate was clinicaly validated) and anonymously transfered to the Infection Alert app using the Azumio Connect SDK.[2](https://github.com/azumio/instantheartrate-connect-ios)

Care must be taked that all restiong heart rate measurements are done at approximetly the same time daoly and in sitting resting state. 

## Creating a global map of resting heart rate elevations

Let's anonymously collect all resting heart rate data from users who want to participate. With enough covererage, we can create an infection spread map. 

What to collect (per user per day):
 - daily heart rate measurements (close to raw data for tracking back and recalculation with a better algorithm)
   - heart rate
   - timestamp
   - activity level
 - daily resting heart rate and elevation above the resting heart rate
 - location of the user (could randomly blur the exact location to protect privacy)
 - unique id of the user (randomly generated on the device at install time)

## Data availability
All annonimized data is stored in a publicaly accesable repository, so any researcher can have free access to it. 

Dashboards can be built...

## Technical implementation
### Backend for storing 
Google BigQuery for storing, heart rate and location data.

HeartRate:
 - userid
 - location
 - timestamp
 - day 
 - baseline
 - heart rate 
 - raw data records
    - timestamp
    - heart rate
    - motion 


## About Author 

I'm Peter Kuhar, I've developed the most successfull heart rate measurement app for iOS and Android. With more than 50M Downloads. 

I've also participated in research regarding heart pulse signal, wearables... and lead internal research efforts. 

This is a personal project outside my work at Azumio Inc.

## References
[1] Harnessing wearable device data to improve state-level real-time surveillance of influenza-like illness in the USA: a population-based study - https://www.thelancet.com/journals/landig/article/PIIS2589-7500(19)30222-5/fulltext

[2] https://github.com/azumio/instantheartrate-connect-ios
