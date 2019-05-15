require 'scraperwiki'
require 'mechanize'

def is_valid_year(date_str, min=2009, max=DateTime.now.year)
  if ( date_str.scan(/^(\d)+$/) )
    if ( (min..max).include?(date_str.to_i) )
      return true
    end
  end
  return false
end

unless ( is_valid_year(ENV['MORPH_PERIOD'].to_s) )
  ENV['MORPH_PERIOD'] = DateTime.now.year.to_s
end
puts "Getting data in year `" + ENV['MORPH_PERIOD'].to_s + "`, changable via MORPH_PERIOD environment"

base_url = "https://eservices.darebin.vic.gov.au/ePathway/Production/Web/GeneralEnquiry/"
url = "#{base_url}enquirylists.aspx"

agent = Mechanize.new
agent.user_agent_alias = 'Mac Safari'
# This is a heavy-handed way to change the ciphers so we can connect to this
# really badly configured web server. The magic for this was discovered in:
# https://stackoverflow.com/questions/33572956/ruby-ssl-connect-syscall-returned-5-errno-0-state-unknown-state-opensslssl
# This allows it to work with Mechanize. You'll see a warning because we're
# redefining a constant.
params = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
params[:ssl_version] = :TLSv1
params[:ciphers] = ['DES-CBC3-SHA']
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS = params

# select Planning Application
page = agent.get url
form = page.forms.first
form.radiobuttons[0].click
page = form.click_button

# local DB lookup if DB exist and find out what is the maxDA number
i = 1;
sql = "select * from data where `council_reference` like '%/#{ENV['MORPH_PERIOD']}'"
results = ScraperWiki.sqliteexecute(sql) rescue false
if ( results )
  results.each do |result|
    maxDA = result['council_reference'].gsub!('D/', '').gsub!("/#{ENV['MORPH_PERIOD']}", '')
    if maxDA.to_i > i
      i = maxDA.to_i
    end
  end
end

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
