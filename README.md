# Famous vs Hidden Gems: When Should You Travel?

An interactive travel-weather planner that compares 8 famous destinations with a less-crowded alternative nearby, and shows the best months to visit each one based on five years of weather data.

**[View the interactive dashboard on Tableau Public](https://public.tableau.com/app/profile/sandeepa.patra/viz/FamousvsHiddenGems-WhenShouldYouTravel/Dashboard1)**

<img width="1853" height="861" alt="image" src="https://github.com/user-attachments/assets/cff96511-610f-4b20-a202-3dd793343be8" />

## Why this project

Famous destinations get crowded, while nearby places with similar scenery see far fewer visitors. This project asks a simple question: **if you skip the famous place and go to the hidden gem instead, do you give up good weather?**

## Destinations

| Pair | Famous | Hidden gem | Country |
|---|---|---|---|
| 1 | Goa | Gokarna | India |
| 2 | Manali | Tirthan Valley | India |
| 3 | Jaipur | Bundi | India |
| 4 | Bali | Lombok | Indonesia |
| 5 | Phuket | Koh Lanta | Thailand |
| 6 | Santorini | Milos | Greece |
| 7 | Dubai | Muscat | UAE / Oman |
| 8 | Kyoto | Kanazawa | Japan |

## Tools and workflow

| Step | Tool | What happened |
|---|---|---|
| Collect and clean | Python (Jupyter, pandas, requests) | Downloaded daily weather for 2021-2025 for all 16 places from the [Open-Meteo Historical Weather API](https://open-meteo.com/en/docs/historical-weather-api) (29,216 daily rows). Converted sunshine from seconds to hours and added year and month. |
| Analyse | PostgreSQL | Built monthly climate averages, a comfort score, best-month rankings and a famous-vs-hidden comparison using views, `CASE`, window functions (`RANK`, `MAX OVER`), a CTE, `JOIN` and `FILTER`. |
| Visualise | Tableau Public | Map with a month slider (bubble size = comfort score) and a heatmap of every destination by month. |

## The comfort score (0-100)

Each destination and month gets a score based on its five-year average weather:

| Part | Points | Rule |
|---|---|---|
| Temperature | 35 | Full points if the average daily maximum is 20-30°C, minus 3.5 points per degree outside that range |
| Rain | 40 | 40 x share of days with less than 1 mm of rain |
| Sunshine | 25 | Full points for 10+ hours of sunshine, scaled down below that |

These weights are a design choice, not a universal rule. Rain gets the most weight because it disrupts sightseeing the most. The full SQL is in [`analysis.sql`](analysis.sql).

## Key findings

**1. The score matches well-known travel seasons.** Goa scores 91-93 in December-February and drops to 46 in July (99% of July days have rain). Jaipur, Bundi, Dubai and Muscat are best in winter, Santorini and Milos in summer, and Bali and Lombok in July, during their dry season south of the equator.

**2. Most hidden gems offer similar weather to their famous counterparts.**

| Famous | Hidden gem | Months within 5 points or better | Average difference |
|---|---|---|---|
| Jaipur | Bundi | 12 / 12 | -1.9 |
| Santorini | Milos | 12 / 12 | +0.2 |
| Phuket | Koh Lanta | 12 / 12 | +0.3 |
| Bali | Lombok | 11 / 12 | +0.8 |
| Dubai | Muscat | 10 / 12 | +1.8 |
| Goa | Gokarna | 10 / 12 | -3.4 |
| Manali | Tirthan Valley | 5 / 12 | -3.7 |
| Kyoto | Kanazawa | 5 / 12 | -9.0 |

For 6 of the 8 pairs, travellers can choose the hidden gem for most of the year without giving up good weather. Kanazawa is the clear exception: it is much rainier than Kyoto, especially in winter.

**3. How you define "as good" changes the answer.** A strict comparison (hidden gem scores equal or higher) said Gokarna was never as good as Goa (0 of 12 months). But in January the scores were 93 vs 92. Treating differences of up to 5 points as "similar" gives 10 of 12 months. Small score differences should not be over-interpreted.

**4. A single "best month" can be misleading.** Kanazawa scores 80, 82 and 80 in May, June and July. The dashboard therefore also marks "good months": any month within 5 points of a destination's best score.

## Limitations

- **Weather only:** the score does not include crowds, prices, humidity or local events.
- **Rain intensity is ignored:** a day counts as rainy at 1 mm or more, whether it drizzled or poured.
- **Humidity is missing:** for example, Japan's June-August is humid, which the score does not capture.
- **Subjective weights:** the comfort score reflects one set of preferences; a skier or a surfer would weigh things differently.
- **Approximate locations:** each place is represented by a single coordinate.

## Project files

| File | What it contains |
|---|---|
| `01_collect_data.ipynb` | Python notebook: downloads and cleans the weather data |
| `analysis.sql` | All PostgreSQL tables, views and queries |
| `destinations.csv` | The 16 destinations, their pairs and coordinates |
| `weather_raw.csv` | Raw daily weather for all destinations (2021-2025) |
| `weather_clean.csv` | Cleaned weather data loaded into PostgreSQL |
| `tableau_comfort.csv` | Final monthly comfort scores exported for Tableau |
| `dashboard.png` | Screenshot of the Tableau dashboard |
| `requirements.txt` | Python libraries used |

## How to run

1. Install the Python libraries: `pip install -r requirements.txt`
2. Run `01_collect_data.ipynb` to download and clean the weather data.
3. In PostgreSQL, create a database called `travel_planner`, run the table section of `analysis.sql`, and import `destinations.csv` and `weather_clean.csv`.
4. Run the rest of `analysis.sql`, and export the final query as `tableau_comfort.csv`.
5. Open the CSV in Tableau Public, or view the published dashboard linked above.

## Author

Sandeepa Patra
