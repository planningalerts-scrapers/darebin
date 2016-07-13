require 'scraperwiki'
require 'mechanize'
require 'date'

base_url = "https://eservices.darebin.vic.gov.au/ePathway/Production/Web/generalenquiry/"
url = "#{base_url}enquirylists.aspx"

agent = Mechanize.new

# This is a heavy-handed way to change the ciphers so we can connect to this
# really badly configured web server. The magic for this was discovered in:
# https://stackoverflow.com/questions/33572956/ruby-ssl-connect-syscall-returned-5-errno-0-state-unknown-state-opensslssl
# This allows it to work with Mechanize. You'll see a warning because we're
# redefining a constant.
params = OpenSSL::SSL::SSLContext::DEFAULT_PARAMS
params[:ssl_version] = :TLSv1
params[:ciphers] = ['DES-CBC3-SHA']
OpenSSL::SSL::SSLContext::DEFAULT_PARAMS = params

first_page = agent.get url
p first_page.title.strip
first_page_form = first_page.forms.first
first_page_form.radiobuttons[1].click
summary_page = first_page_form.click_button

page_number = 2 # The next page number to move onto (we've already got page 1)

das_data = []
while summary_page
  p summary_page.title.strip
  table = summary_page.root.at_css('.ContentPanel')
  headers = table.css('th').collect { |th| th.inner_text.strip }

  das_data = das_data + table.css('.ContentPanel, .AlternateContentPanel').collect do |tr|
    tr.css('td').collect { |td| td.inner_text.strip }
  end

  if summary_page.at('#ctl00_MainBodyContent_mPagingControl_nextPageHyperLink')
    p "Found another page - #{page_number}"
    summary_page.forms.first.action = "EnquirySummaryView.aspx?PageNumber=#{page_number}"
    summary_page = summary_page.forms.first.submit
    page_number += 1
  else
    summary_page = nil
  end
end

comment_url = 'mailto:mailbox@darebin.vic.gov.au'

das = das_data.collect do |da_item|
  page_info = {}
  page_info['council_reference'] = da_item[headers.index('Application Number')]
  # There is a direct link but you need a session to access it :(
  page_info['info_url'] = url
  page_info['description'] = da_item[headers.index('Description')]
  page_info['date_received'] = Date.strptime(da_item[headers.index('Application Date')], '%d/%m/%Y').to_s
  page_info['address'] = da_item[headers.index('Location')]
  page_info['date_scraped'] = Date.today.to_s
  page_info['comment_url'] = comment_url
  
  page_info
end

das.each do |record|

  if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
    ScraperWiki.save_sqlite(['council_reference'], record)
  else
    puts "Skipping already saved record " + record['council_reference']
  end
end

