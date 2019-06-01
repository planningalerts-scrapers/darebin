require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
year = ENV['MORPH_PERIOD'].to_i
puts "Getting data in year `#{year}`, changable via MORPH_PERIOD environment"

scraper = EpathwayScraper.scrape_and_save(
  "https://eservices.darebin.vic.gov.au/ePathway/Production",
  list_type: :all_year, year: year
)
