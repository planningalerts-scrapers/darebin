require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
year = ENV['MORPH_PERIOD'].to_i
puts "Getting data in year `#{year}`, changable via MORPH_PERIOD environment"

scraper = EpathwayScraper::Scraper.new(
  "https://eservices.darebin.vic.gov.au/ePathway/Production"
)

scraper.scrape(list_type: :all_year, year: year) do |record|
  EpathwayScraper.save(record)
end
