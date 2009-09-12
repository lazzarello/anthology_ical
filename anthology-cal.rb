#!/usr/bin/ruby
# Sun Jan 18 23:54:25 EST 200 9anthology film archives ical generator by Lee Azzarello <lee@rockingtiger.com>
# fetch a month of events from anthology film archive's web site and output the events to a ical file to be imported
# into google calendar, apple ical, etc, etc. outputs ical string to stdout.
require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'icalendar'
require 'date'
hostname = "http://www.anthologyfilmarchives.org/"
# PLEASE CHANGE ME TO THE MONTH YOU WANT
month = "2009-09-01"
doc = Hpricot(open("#{hostname}/schedule/?current_date=#{month}"))
events = []
length_query = Regexp.new(/[0-9]+ minutes/)
time_query = Regexp.new(/[0-9]+:[0-9]+/)
event_container = (doc/"div.day_link")
unless (event_container.at("a").nil?) 
  event_container.each do |date_container|
    (date_container/"a.thickbox").each do |event|
      link_location = "#{event.get_attribute('href')}"
      showtime = time_query.match(event.at('span.showtime').inner_text)
      detail_doc = Hpricot(open("#{hostname}#{link_location}"))
      details = (detail_doc/"div.film_detail")
      length = length_query.match(details.at('div.info').inner_text)
      #let's assume that if there is no length the show will last for one hour
      length.nil? ? length = 60 : length
      events << { 
	:link => link_location,
	:title => "#{event.inner_text}",
	:showtime => showtime[0],
	:date => "#{date_container.at('a').get_attribute('name').sub('day','')}",
	:director => "#{details.at('div.director').inner_text}",
	:info => "#{details.at('div.info').inner_text}",
	:description => "#{details.at('div.description').inner_text}",
	:length => length[0].to_i
	}
    end
  end
end
cal = Icalendar::Calendar.new
events.each do |event|
  date = event[:date].split("-")
  time = event[:showtime].split(":")
  year = date[0].to_i
  month = date[1].to_i
  day = date[2].to_i
  # time is full of suck. we will assume that all times are in the afternoon. this script can't handle an AM show
  # right now because it doesn't look like they program anything for the AM. perhaps this is what "test driven
  # development is used for" or perhaps the regex chops just ain't that good.
  s_hour = time[0].to_i + 12
  s_minute = time[1].to_i
  # length is in minutes. we need hours
  e_hour = (event[:length] / 60) + s_hour
  #length is in minutes, let's strip off the hours
  e_minute = event[:length] % 60
  # oh shit! an event that goes into the next day
  e_hour > 23 ? e_hour %= 24 : e_hour  
  cal.event do
    dtstart DateTime.civil(year,month,day,s_hour,s_minute)
    dtend   DateTime.civil(year,month,day,e_hour, e_minute)
    summary event[:title]
    description	event[:description]
    klass "PUBLIC"
  end
end
puts cal.to_ical
