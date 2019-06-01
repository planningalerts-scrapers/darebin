require 'scraperwiki'
require 'mechanize'

ENV['MORPH_PERIOD'] ||= DateTime.now.year.to_s
puts "Getting data in year `" + ENV['MORPH_PERIOD'].to_s + "`, changable via MORPH_PERIOD environment"

base_url = "https://eservices.darebin.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/"
url = "#{base_url}enquirylists.aspx"

agent = Mechanize.new

# select Planning Application
page = agent.get url
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
    tr     = table.search("tr.ContentPanel")

    record = {
      'council_reference' => tr.search('a').inner_text,
      'address'           => tr.search('span')[2].inner_text,
      'description'       => tr.search('span')[3].inner_text.gsub("\n", '. ').squeeze(' '),
      'info_url'          => base_url + tr.search('a')[0]['href'],
      'date_scraped'      => Date.today.to_s,
      'date_received'     => Date.parse(tr.search('span')[1].inner_text).to_s,
    }

    puts "Saving record " + record['council_reference'] + ", " + record['address']
#       puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    error += 1
  end

  # increase i value and scan the next DA
  i += 1
  if error == 10
    cont = false
  end
end
