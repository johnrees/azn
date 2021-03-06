#!/usr/bin/ruby

require "bundler/setup"
require 'sinatra'
require 'nokogiri'
require 'open-uri'

def check a, zones

  # fails = websites that don't exist
  fails = []
  wins = []

  if match = a[1]
    zones.each do |tld, zone, tag|
      # ?tag=#{tag}
      url = "http://www.amazon.#{tld}/dp/#{match}"
      url += "?tag=#{tag}" if tag
      code = `curl -w %{http_code} -s --output /dev/null '#{url}'`
      code.to_i == 404 ? fails.push(url) : wins.push(url)
    end
  end

  return {fails: fails, wins: wins}

end

get '/' do
  erb :home
end

post '/' do

  # user agent is required when scraping amazon urls
  user_agent = 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.13) Gecko/20080311 Firefox/2.0.0.13'
  url = params[:url]#"http://www.amazon.com/Halo-Master-Chief-Collection-Xbox-One/dp/B00KSQHX1K/ref=sr_1_1?ie=UTF8&qid=1431599972&sr=8-1&keywords=halo"
  get = open(url, "User-Agent" => user_agent)
  noko = Nokogiri::HTML(get)

  page = open(url, "User-Agent" => user_agent).read

  name = noko.css("td#fbt_x_img > img")[0]['alt']

  # Find the ASIN

  # asin = page.match(/;asin=([A-Z0-9]{10})/)
  asin = page.match(/"ASIN"\s?:\s?"([A-Z0-9]{10})/)


  # Find Kindle / Alternative ASINs
  alt_asin = page.match(/data-tmm-see-more-editions-click.+([A-Z0-9]{10})\//)

  zones = [
    # [tld, country name, associate ID]
    ["com.au", "Australia"],
    ["com.br", "Brazil", "squirrul0b-20"],
    ["ca", "Canada", "squirrul05-20"],
    ["cn", "China"],
    ["fr", "France", "squirrul0d8-21"],
    ["de", "Germany", "squirrul-21"],
    ["in", "India"], # Payee Country: Invalid data. Only Indian Residents are eligible
    ["it", "Italy", "squirrul0e-21"],
    ["co.jp", "Japan"],
    ["com.mx", "Mexico"],
    ["nl", "Netherlands"],
    ["es", "Spain", "squirrul01-21"],
    ["com", "United States", "squirrul-20"],
    ["co.uk", "United Kingdom", "squirrul08-21"]
  ]

  @result = {}
  @result['name'] = name
  @result['asin'] = check(asin, zones) if asin
  @result['alt_asin'] = check(alt_asin, zones) if alt_asin

  erb :home

end
