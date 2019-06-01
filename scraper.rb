require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
puts "Getting data in year `" + ENV['MORPH_PERIOD'].to_s + "`, changable via MORPH_PERIOD environment"

scraper = EpathwayScraper::Scraper.new(
  "https://eservices.darebin.vic.gov.au/ePathway/Production"
)

# select Planning Application
page = scraper.agent.get scraper.base_url
form = page.forms.first
form.radiobuttons[0].click
page = form.click_button

i = 1;
error = 0
while error < 10 do
  application_no = "D/#{i}/#{ENV['MORPH_PERIOD']}"

  list = EpathwayScraper::Page::Search.search_for_one_application(page, application_no)

  count = 0
  EpathwayScraper::Page::Index.scrape_index_page(list, scraper.base_url, scraper.agent) do |record|
    count += 1
    EpathwayScraper.save(record)
  end

  if count == 0
    error += 1
  else
    error  = 0
  end

  # increase i value and scan the next DA
  i += 1
end
