require "epathway_scraper"

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
puts "Getting data in year `" + ENV['MORPH_PERIOD'].to_s + "`, changable via MORPH_PERIOD environment"

scraper = EpathwayScraper::Scraper.new(
  "https://eservices.darebin.vic.gov.au/ePathway/Production"
)

base_url = "https://eservices.darebin.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/"
url = "#{base_url}enquirylists.aspx"

# select Planning Application
page = scraper.agent.get url
form = page.forms.first
form.radiobuttons[0].click
page = form.click_button

i = 1;
error = 0
cont = true
while cont do
  form = page.form
  form.field_with(:name=>'ctl00$MainBodyContent$mGeneralEnquirySearchControl$mTabControl$ctl04$mFormattedNumberTextBox').value = 'D/' + i.to_s + '/' + ENV['MORPH_PERIOD'].to_s
  button = form.button_with(:value => "Search")
  list = form.click_button(button)

  table = list.search("table.ContentPanel")
  unless ( table.empty? )
    error  = 0

    EpathwayScraper::Table.extract_table_data_and_urls(table).each do |row|
      data = EpathwayScraper::Page::Index.extract_index_data(row)

      record = {
        'council_reference' => data[:council_reference],
        'address'           => data[:address],
        'description'       => data[:description].gsub("\n", '. ').squeeze(' '),
        'info_url'          => scraper.base_url,
        'date_scraped'      => Date.today.to_s,
        'date_received'     => data[:date_received],
      }

      EpathwayScraper.save(record)
    end


  else
    error += 1
  end

  # increase i value and scan the next DA
  i += 1
  if error == 10
    cont = false
  end
end
