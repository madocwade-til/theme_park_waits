# Historical and contextual data options

Checked 10 November 2026. This is a research shortlist; none of these sources has been backfilled into the starter database. Coverage and access need checking for your chosen parks before adopting a source.

## 1. TouringPlans: Animal Kingdom CSV archive — strongest free starting point

Source and downloadable files: https://github.com/TouringPlans/DisneyAnimalKingdomWaitTimes

The provider's own repository advertises 2012 through February 2019, with 12 attraction-specific CSV files. This is archive-wide coverage; individual attractions have different histories. The file listing and one CSV download page were verified, rather than downloading every file.

Fields: `date`, `datetime`, `SPOSTMIN` (posted minutes), `SACTMIN` (actual guest wait). Actual waits can be on separate rows from posted waits. The README defines -999 as an unexpectedly offline attraction and gives timestamps in US Eastern time. The licence permits use subject to prominent TouringPlans credit on publications/redistributions and carrying its terms with redistributed data.

Use: weekday/hour/season patterns and posted-versus-actual comparisons. Preserve separate measurement types. Map attraction ids explicitly, interpret offline sentinels, and convert local timestamps with daylight-saving handling before any comparison with UTC live observations. A historical row is not automatically the same grain as one of our snapshots.

Licence: https://github.com/TouringPlans/DisneyAnimalKingdomWaitTimes/blob/master/LICENSE.md

## 2. TouringPlans-derived R package — convenient small analytical dataset

https://lucymcgowan.github.io/touringplans/

https://lucymcgowan.github.io/touringplans/reference/touringplans_2018.html

The maintainer documents a 2018 dataset with 66,492 rows, 17 variables and hourly averages for 14 attractions. It includes posted/actual averages and context such as opening/closing times, Extra Magic Hours, ticket season and temperature. Full reference pages also list individual attraction datasets. It is an R package rather than a ready-made Python database; export to CSV in R or inspect the repository's source data before Python ingestion. Credit the original TouringPlans data as well as the package and check their applicable data terms.

Use: a manageable exploratory analysis, particularly suitable if you want to work in R initially. Historical policies such as Extra Magic Hours need interpretation when comparing them with current operations.

## 3. ParkQueueTimes.com — recent history across multiple parks, paid depth

https://parkqueuetimes.com/developers

This is a separate service from Queue-Times.com, with its own keys, identifiers and terms. Its documentation offers hourly, daily and monthly park/ride history back to January 2024 for some parks. The free key covers the last 48 hours; Developer covers a rolling 90 days and Archive offers full available history. The provider says roughly 29 parks reach back into 2024, with others starting later. Check the coverage endpoint for the parks you choose; no key was created or authenticated coverage verified here.

Use: a candidate for recent multi-park or non-Disney historical comparisons. The published terms distinguish internal/product analysis from redistribution and research/client deliverables, and direct research/publication enquiries to Enterprise licensing. Confirm the intended use and coverage with the provider before paying. No subscription or purchase was made.

## 4. Open-Meteo — hourly historical weather

https://open-meteo.com/en/docs/historical-weather-api

The historical API provides location-based weather reanalysis, with ERA5 history from 1940. Useful variables include temperature, precipitation and wind. Join park coordinates to weather and match timestamps at hourly grain. Reanalysis is a modeled estimate, not an on-site measurement. The free API is for noncommercial use; attribution and current usage terms apply.

Use: assess whether rain, heat or wind coincide with wait patterns, while accounting for season, hour and operating schedules. For future forecasting, archived forecasts are a separate product: do not give a predictive model future realized weather it would not have known.

## 5. TEA Global Experience Index — annual attendance context

https://www.teaconnect.org/tea-global-experience-indextm

TEA provides free calendar-year attendance reports and links to past editions. The official page currently links a 2025 edition and earlier reports including 2024, 2023, 2022 and 2021. Reports give park-level annual context, rather than ride-level intraday queue observations. Downloading a report is free; that does not by itself grant unrestricted redistribution rights.

Use: compare long-term wait trends with annual attendance estimates. Join by manually reconciled park identity and year, not inferred visitor counts from waits. Annual attendance cannot explain each day's crowd fluctuations.

## 6. US federal holidays — calendar controls

https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/

OPM publishes federal holiday calendars with historical schedules. Convert relevant dates into calendar flags, preserving the distinction between the holiday itself and the observed weekday. These are federal employee calendars, not school vacation calendars or complete tourist demand measures. School vacations should be collected separately for relevant visitor markets.

Use: test holiday and holiday-weekend effects for US parks. Parks elsewhere require their own local holiday calendars.

## Queue-Times' own older history

https://queue-times.com/pages/api

The provider says its database extends back to 2014, but the public documentation describes the park directory and live queue endpoints, with no documented historical bulk-download endpoint. Do not assume the live API can backfill its older archive. A provider enquiry could establish whether historical extracts are available and on what terms. No scraping or contact has been undertaken.

## Suggested next decision

For a free first analysis, the Animal Kingdom CSV archive is the clearest source. For a compact exercise with explanatory fields already attached, consider the R package's 2018 data. For newer multi-park history, evaluate ParkQueueTimes coverage and licensing. Weather is the most direct additional covariate to add once you choose parks and dates.

Keep backfilled data in separate source-specific staging tables with provenance and measurement type. Build an explicit park/ride crosswalk and comparable analytical view later, rather than appending incompatible aggregates or actual guest waits to the live posted-wait table.
