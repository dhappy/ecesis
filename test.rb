#!/usr/bin/env ruby

require 'pry'
require 'wikidata'
require 'net/http'
require 'json'

query = """SELECT DISTINCT ?item ?itemLabel ?awardLabel ?time
{
    ?item wdt:P106/wdt:P279* wd:Q3455803 ;
          p:P166 ?awardStat .             
    ?awardStat pq:P805 ?award ;           
               ps:P166 wd:Q103360 .       
    ?award wdt:P585 ?time .               
    SERVICE wikibase:label {              
        bd:serviceParam wikibase:language 'en'
    }
}
ORDER BY DESC(?time)"""

url = URI.parse("https://query.wikidata.org/sparql?format=json&query=#{query}")
awards = JSON.parse(Net::HTTP.get(url), symbolize_names: true)

binding.pry

return

hugos = Wikidata::Item.find_by_title 'Hugo Award'
hugos.properties('P527').each do |award|
  puts award.title
  award.properties('P1346').each do |winner|
    puts winner
  end
end

