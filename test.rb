#!/usr/bin/env ruby

require 'pry'
require 'wikidata'

hugos = Wikidata::Item.find_by_title 'Hugo Award'
hugos.properties('P527').each do |award|
  puts award.title
  award.properties('P1346').each do |winner|
    puts winner
    binding.pry
  end
end

