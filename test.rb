#!/usr/bin/env ruby

require 'pry'
require 'net/http'
require 'json'

query = """
SELECT DISTINCT ?item ?itemLabel ?authorLabel ?year WHERE {  
  ?item wdt:P166 wd:Q255032.
  ?item wdt:P50 ?author.  
  ?item wdt:P577 ?year.
  SERVICE wikibase:label { bd:serviceParam wikibase:language 'en' }    
}
"""

url = URI.parse("https://query.wikidata.org/sparql?format=json&query=#{query}")
awards = JSON.parse(Net::HTTP.get(url), symbolize_names: true)

awards[:results][:bindings].each do |award|
  year = award[:year][:value].match(/([^-]+)-/)[1]
  puts ".../award/Hugo/year/#{year} -> .../book/by/#{award[:authorLabel][:value]}/#{award[:itemLabel][:value]}"
end

#binding.pry
