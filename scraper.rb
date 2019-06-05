require "epathway_scraper"

scraper = EpathwayScraper.scrape_and_save(
  "https://eservices.darebin.vic.gov.au/ePathway/Production",
  list_type: :all_this_year, state: "VIC"
)
