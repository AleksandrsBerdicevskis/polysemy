# The script will generate a single file for all the parts of speech, not separate files like the ones provided in the repo
# The script assumes you have direct access to oed.com (i.e. you are running it from a computer at your institution, and the institution has a subscription). It will not work as it is if you are using proxies or have to log in to get access.

require 'rubygems'
require 'nokogiri'
require 'open-uri'

PREFIX = "http://www.oed.com/browsedictionary?browseType=sortAlpha&page="
#page number will be inserted after PREFIX, before INFIX
INFIX = "&pageSize=100&pos="
POSS = ["verb","adjective","noun"] #to be put into the address line
POSTFIX = "&scope=ENTRY&sort=entry&type=dictionarybrowse"

def checkifdigit(string) #check if a string contains only digits
  digit = true
  string.each_char do |char|
    if !@digits.include?(char)
      digit = false
      break
    end
  end
  return digit
end

def checkmeanings(string) #given a string of subentry headers (I, 1, a, b, etc., calculate how many are numbers = how many meanings a word has)
  array = string.split(".")
  nmeanings = 0
  array.each do |meaning|
    if checkifdigit(meaning)
      nmeanings += 1
    #else 
      #break
    end
  end
  return nmeanings
end

@digits = "0123456789"
all = File.open("all.csv","w:utf-8")
all.puts "word\tpos\tyear\tfreq\ttotal_nmeanings\tncrosses\tnmeanings"

lastpage = {"verb"=>325, "adjective" => 857, "noun" => 1673, "preposition" => 5, "pronoun" => 3, "conjunction" => 2, "adverb" => 117}

POSS.each do |currentpos|
  for pageno in 1..lastpage[currentpos] do
    STDERR.puts pageno
    page = Nokogiri::HTML(open("#{PREFIX}#{pageno}#{INFIX}#{currentpos}#{POSTFIX}",{ssl_verify_mode: 0})) #open the nth page of a given POS
    page.css('h2').each do |h2| #from the page we are scraping the main properties of words
      word = h2.css(".hw").text.strip #the headword
      if word!="" #filtering out trash
        obs = h2.css(".obs").text.strip #is the whole word marked as obsolete? 
        if !obs.include?("†")
          posinfo = h2.css(".ps").text.strip #pos ("v.", "v. and n.")
          if !posinfo.include?("and") and (posinfo.count(".") < 2) #ignoring such cases for now, in principle they can be dealt with (different poss seem to be marked A and B within the entry)
            posarray = posinfo.split(".")
            pos = posarray[0]
            if !posarray[1].nil?
              word = "#{word}#{posarray[1]}" #index homonyms
            end
            year = h2.css(".year").text.strip
            if @digits.include?(year[0].to_s) and year != "" #excluding c, a, ?, OE, ME, empty years etc. 
              if year.include?("–")
                year = year.split("–")[0] #for years like 1461–2 we take the first one
              end
              band = h2.css(".frequencyBand a")
              if band.to_s != "" #if frequency band is provided
                STDERR.puts word
                freq = band.to_s.split(" ")[1].split("=")[1].gsub("\"","")
                link = "http:\/\/www.oed.com#{h2.css(".word a").to_s.split("\"")[1]}" #link to the full entry
                wordpage = Nokogiri::HTML(open(link,{ssl_verify_mode: 0})) #we go there to count meanings
                meanings = wordpage.css(".numbering").text.strip
                if meanings == "" #if there are no numbered meanings, there is only one
                  nmeanings = 1
                else
                  nmeanings = checkmeanings(meanings)   
                end
                if nmeanings == 0
                  nmeanings = 1 #to solve problems like "bedim" (no number, only a, b, c)
                end 
                subentries = wordpage.css('h3').text #for meanings, we collect only their numbering. Here, we collect the whole text
                ncrosses = subentries.scan(/†[0-9]/).length #some are marked as "obsolete", but not by a cross. we ignore them for now
                all.puts "#{word}\t#{pos}\t#{year}\t#{freq}\t#{nmeanings}\t#{ncrosses}\t#{nmeanings - ncrosses}"
                #exclude words with <1 meanings? So far, I haven't seen any
              end #end of IF frequency band
            end #end of IF year
          end #end of IF pos
        end #end of IF obsolete
      end #end of IF word non-empty
    end #end of looping through h2s of the current page (=words)
  end #end of looping through pages
end #end of looping through POS

#NOT IMPLEMENTED:
#solve problems like "bedead" (everything obsolete)
#solve problems like "to argue (a thing) away, off": an expression/construction as a separate meaning
#find obsolete meanings not marked with a cross