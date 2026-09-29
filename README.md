# Delhi Air Quality Forecaster

Forecasting Delhi's next-day PM2.5 using weather data and satellite-detected crop fires in Punjab and Haryana.

Every winter, Delhi's air becomes some of the most polluted in the world. Crop-residue (stubble) burning in Punjab and Haryana is often blamed, but weather also plays a big role. This project combines air quality, weather and fire data to explore what drives Delhi's pollution, and tests whether machine learning can forecast tomorrow's PM2.5 better than a simple rule.

![Delhi PM2.5 vs crop fires](reports/pm25_vs_fires.png)

## Data

| Data | Source | Details |
|---|---|---|
| Air quality (PM2.5, PM10) | [Open-Meteo Air Quality API](https://open-meteo.com/en/docs/air-quality-api) | Hourly, averaged to daily. Model-based estimates (CAMS), available from August 2022. |
| Weather | [Open-Meteo Historical Weather API](https://open-meteo.com/en/docs/historical-weather-api) | Daily mean temperature, rainfall, max wind speed, dominant wind direction for Delhi. |
| Crop fires | [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/country/) | MODIS active fire detections for India (yearly files), filtered to a Punjab-Haryana bounding box and vegetation fires only. |

**Study period:** 4 August 2022 to 31 December 2024 (881 days), the period where all three datasets overlap.

## Method

1. **Collect** weather and air quality data via APIs, and download yearly fire data from NASA FIRMS.
2. **Clean and combine** into one daily table: hourly air quality averaged to daily, fires counted per day, all three joined on date.
3. **Fix data errors:** two days (14-15 Dec 2022) showed PM2.5 of about 0.6 µg/m³ with no rain or unusual wind, which is unrealistic for a Delhi winter. These were treated as missing and filled by linear interpolation.
4. **Explore** patterns with charts and correlations.
5. **Engineer features:** yesterday's PM2.5, total fires over the last 3 days, wind direction and month converted to sin/cos (so that 359° and 1°, or December and January, are treated as close).
6. **Model** next-day PM2.5 with a time-based split: train on 2022-2023, test on 2024 (365 unseen days). Models are compared using Mean Absolute Error (MAE).

## Results

Models were tested on two separate periods the model had never seen, to check whether results are consistent.

**Test 1: train on Aug 2022 to Dec 2023, test on 2024**

| Model | MAE full 2024 | MAE Oct-Dec 2024 |
|---|---|---|
| Baseline (tomorrow = today) | 12.1 | 18.7 |
| Linear Regression | 13.2 | 18.5 |
| Random Forest | **12.0** | **17.3** |

**Test 2: train on Aug 2022 to Jun 2023, test on Jul-Dec 2023**

| Model | MAE Jul-Dec 2023 | MAE Oct-Dec 2023 |
|---|---|---|
| Baseline (tomorrow = today) | 11.7 | 14.3 |
| Linear Regression | **11.5** | **13.8** |
| Random Forest | 14.2 | 15.2 |

**What this means:**

- The simple baseline ("tomorrow's PM2.5 = today's") is hard to beat, because pollution changes slowly from day to day.
- **No model beat the baseline consistently.** Random Forest was best in the 2024 test (about 7% lower winter error), but worst in the 2023 test. Linear Regression was slightly better than the baseline in 2023, but worse in 2024.
- Random Forest likely struggled in Test 2 because it had only about 11 months of training data with a single stubble-burning season. Tree-based models need more examples to learn reliable patterns.
- **Conclusion:** with about two and a half years of data, adding weather and fire information gives, at best, small and inconsistent improvements over a simple persistence forecast. More years of data, measured station data and weather forecasts would be needed for a reliable improvement.

![Forecast vs actual, Oct-Dec 2024](reports/forecast_vs_actual.png)

![Feature importance](reports/feature_importance.png)

## Key findings from the data

1. **Two fire seasons.** Fires peak in October-November (paddy residue, about 218 fires/day on average in November) and again in May (wheat residue, about 104 fires/day).
2. **More fires does not always mean more pollution.** May has many fires but low PM2.5 (about 54 µg/m³), while January has very few fires but the highest PM2.5 (about 120 µg/m³). Winter weather traps pollution near the ground.
3. **Fires dropped sharply from 2022 to 2024** (peak days of roughly 1,400 fires in 2022, 1,150 in 2023 and 500 in 2024), yet winter PM2.5 in 2024 still reached around 180 µg/m³.
4. **Days with many fires (over 200) had higher PM2.5** in October-November, by roughly 20-27 µg/m³ on average.
5. **A surprise:** on days when the surface wind came from the Punjab-Haryana side, PM2.5 was *lower*, not higher. Possible reasons: those winds are slightly stronger and disperse local pollution, smoke travels at higher altitudes where wind direction can differ, and smoke takes time to arrive.
6. **Fires from 2-3 days earlier correlate slightly more with today's PM2.5** (0.32) than same-day fires (0.28), consistent with smoke taking time to reach Delhi.

## Limitations

- **Air quality data is model-based,** not direct station measurements. It comes from CAMS atmospheric model estimates at about 45 km resolution.
- **Small training set:** at most two stubble-burning seasons (2022 and 2023) were available for training, and only one in Test 2.
- **Short test periods:** the two test periods (Jul-Dec 2023 and 2024) gave different winners, so small differences between models should not be over-interpreted.
- **Approximate region:** fires are selected with a rectangular box that roughly covers Punjab and Haryana, including small parts of neighbouring states.
- **Surface wind only:** smoke transport happens higher up, which daily surface wind direction does not fully capture.
- **No weather forecasts used:** the model only uses today's observed conditions, not forecasts for tomorrow.

## Possible next steps

- Use measured station data (for example CPCB data via OpenAQ).
- Test the model on the 2025 stubble season.
- Count only fires upwind of Delhi, using wind direction at higher altitudes.
- Add tomorrow's weather forecast as a feature.
- Build a small dashboard that shows the latest forecast.

## Project structure

```
delhi-aqi-forecaster/
├── data/
│   ├── raw/            # original downloaded data (not edited)
│   └── processed/      # cleaned and combined data
├── notebook/
│   ├── 01_collect_data.ipynb
│   └── 02_clean_combine.ipynb
├── reports/            # charts and model results
├── requirements.txt
└── README.md
```

## How to run

1. Install the libraries: `pip install -r requirements.txt`
2. Download the MODIS yearly country files for India (2022, 2023, 2024) from [NASA FIRMS](https://firms.modaps.eosdis.nasa.gov/country/) and place them in `data/raw/`.
3. Run the notebooks in order: `01_collect_data.ipynb`, then `02_clean_combine.ipynb`.

## Author

Sandeepa Patra
