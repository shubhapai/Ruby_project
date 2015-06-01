#! /usr/local/bin/ruby -w

#########__#########__#########__#########__#########__#########__#########__#########80
#Author: sbp345@nyu.edu (Shubhalakshmi Pai)
#
#Dumps contents of business_Openweek.list file in business_Openweek table.
#
#####
# The script goes through keywords file.
# - generates an sql file with inserts
#
## WARNING
#AFTER SCRIPT IS  RUN, please run the sql dump file to fill up the countries_dump table
#
##In case of premature stopping
# look in the process_log file
# look up the last entry in the sql file for insert. 
# take down the last id and movie id
# search that line in original file.
# remove other records from original file
# start script again from where it stopped
########
require 'rubygems'
require 'mysql'


module DATA_PARSER

  class OpenweekInfo
    attr_accessor :id, :name, :kind, :year, :release_year, :identifier
    attr_accessor :extra_info
    attr_accessor :Openweek_currency, :Openweek_amount, :Openweek_country, :Openweek_extra_info, :Openweek_day ,:Openweek_month, :Openweek_year, :Openweek_screens 
    
    def initialize
      @id = -1
      @name = ""
      @year = "?"
      @identifier = ""
      @extra_info = ""
      @release_year = "?"
      @kind = ""
      @Openweek_currency = ""
      @Openweek_amount = ""
      @Openweek_country = ""
      @Openweek_extra_info = ""
      @Openweek_day = ""
      @Openweek_month = ""
      @Openweek_year = ""
      @Openweek_screens = ""
      #@business_info = ""
    end   
  end


 #Box Office Openweek 
  
  class OpenweekManager
    def initialize
      @inserted_Openweekinfo = 0
      @Openweek_id = 0 #change to lateset value if table not empty
    end

    def insert_Business_Openweek(business_info)
      @Openweek_id += 1 # new id
      if @inserted_Openweekinfo == 0
        @Openweekinfo_insert.puts  "insert into Business_Openweek (id, name, `year`, identifier, extra_info, kind, Business_Openweek_currency, Business_Openweek_amount, Business_Openweek_country,Business_Openweek_extra_info,Business_Openweek_day,Business_Openweek_month,Business_Openweek_year,Business_Openweek_screens)\n values"
        @Openweekinfo_insert.print "  (#{@db.escape_string(@Openweek_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Openweek_currency.to_s)}', '#{@db.escape_string(business_info.Openweek_amount.to_s)}', '#{@db.escape_string(business_info.Openweek_country.to_s)}','#{@db.escape_string(business_info.Openweek_extra_info.to_s)}','#{@db.escape_string(business_info.Openweek_day.to_s)}','#{@db.escape_string(business_info.Openweek_month.to_s)}','#{@db.escape_string(business_info.Openweek_year.to_s)}','#{@db.escape_string(business_info.Openweek_screens.to_s)}'),\n"
        @inserted_Openweekinfo += 1
      elsif @inserted_Openweekinfo == 10000
        @inserted_Openweekinfo = 0 # reset
        @Openweekinfo_insert.puts ";\n" # close previous insert query
        @Openweekinfo_insert.puts  "insert into Business_Openweek (id, name, `year`, identifier, extra_info, kind, Business_Openweek_currency, Business_Openweek_amount, Business_Openweek_country,Business_Openweek_extra_info,Business_Openweek_day,Business_Openweek_month,Business_Openweek_year,Business_Openweek_screens)\n values"
        @Openweekinfo_insert.print "  (#{@db.escape_string(@Openweek_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Openweek_currency.to_s)}', '#{@db.escape_string(business_info.Openweek_amount.to_s)}', '#{@db.escape_string(business_info.Openweek_country.to_s)}','#{@db.escape_string(business_info.Openweek_extra_info.to_s)}','#{@db.escape_string(business_info.Openweek_day.to_s)}','#{@db.escape_string(business_info.Openweek_month.to_s)}','#{@db.escape_string(business_info.Openweek_year.to_s)}','#{@db.escape_string(business_info.Openweek_screens.to_s)}'),\n" 
        puts "{#{@Openweek_id}}" #progress indicator
        @inserted_Openweekinfo += 1
      else
        @Openweekinfo_insert.print "  (#{@db.escape_string(@Openweek_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Openweek_currency.to_s)}', '#{@db.escape_string(business_info.Openweek_amount.to_s)}', '#{@db.escape_string(business_info.Openweek_country.to_s)}','#{@db.escape_string(business_info.Openweek_extra_info.to_s)}','#{@db.escape_string(business_info.Openweek_day.to_s)}','#{@db.escape_string(business_info.Openweek_month.to_s)}','#{@db.escape_string(business_info.Openweek_year.to_s)}','#{@db.escape_string(business_info.Openweek_screens.to_s)}'), \n"
        @inserted_Openweekinfo += 1
      end
    end
    
    def parse_file
      reached_data = false 
      @Openweekinfo_read = 0
      @Openweekinfo_missed = 0
      @missed= File.open("missed_Openweekinfo", "w")
      @Openweekinfo_insert = File.open("insert_business_Openweek.sql", "w")
      #open database
      @db = Mysql.real_connect('localhost', 'root', '', 'imdb_prod')
      current_OpenweekInfo = OpenweekInfo.new
      
      #read lines
      File.open("business.list", "r") do |file|
        while line = file.gets
          print "." #indicator of reading a line
          
          line = line.chomp #trim newlines and carriage returns "/r/n"
          
          #--------------Skip to data--------------------
          if line =~ /BUSINESS LIST/i then reached_data = 1; next end
          if line =~ /^={3,}/ and reached_data == 1 then reached_data = true; next end
          #-------------skip to data--------------------
          
          ##REGEXPs for lines
          empty_line = /^(\s)*$/ 
          business_line = /(?:^MV:) \s+ (.*)  \s+ (?: \( ( \d{4} )  (?: \/(.*?) )?  \) | \((\?{4})\) ) (.*)/x
          #1.name 2.date 3.identifier 4.question_marks 5.extra_info 
          business1_line = /(?:^OW:) \s+ (.*) \s+ (\$|)([1-9]\d{0,2}(\,\d{3})*|([1-9]\d*))(\.\d{2})? \s+ (?:\((\w+)\)) (.*)/x
          #1.identifier 2.currency 3.amount 4.country 5.extra_info 6.day 7.month 8.year
          business2_line = /(?:\((\d{1,2})\s(\w+)\s(\d{4})\)) (.*)/x
          ## Date validation 
          @title_line = /(?:\((\d{1,2})\s(\w+)\s(\d{4})\)) (.*)/x
          #1. Name 2. Year 3. Identifier 4. ???? 5. Extra_info 
          case line
          when empty_line
           print "|" 
            next  
          when business_line
          current_OpenweekInfo = OpenweekInfo.new
          match_data = Regexp.last_match    
            print "-"
            #is_tv_series = false
            #regular Business_Openweek line
          getBusinessDetails(current_OpenweekInfo, Regexp.last_match)
          @Openweekinfo_read += 1
          when business1_line
          getOpenweekinfoDetails(current_OpenweekInfo, Regexp.last_match)
          @Openweekinfo_read += 1
          insert_Business_Openweek(current_OpenweekInfo)
          else
            @Openweekinfo_missed += 1
            @missed.puts line
            next
          end
        end
      end
      @db.close
      @Openweekinfo_insert.close
      @missed.puts "Missed: " + @Openweekinfo_missed  .to_s
      @missed.puts "Hits: " + @Openweekinfo_read.to_s
      @missed.close
    end
  end
end

def getOpenweekinfoDetails(current_OpenweekInfo, match_data)
  unless match_data.nil?  
    unless match_data[1].nil? then current_OpenweekInfo.Openweek_currency = match_data[1].strip end
    unless match_data[3].nil? then current_OpenweekInfo.Openweek_amount = match_data[3].strip end
    unless match_data[7].nil? then current_OpenweekInfo.Openweek_country = match_data[7].strip end
    unless match_data[8].nil? then current_OpenweekInfo.Openweek_extra_info = match_data[8].strip end  
    unless current_OpenweekInfo.Openweek_extra_info.nil?  
    getTitleDetails(current_OpenweekInfo, match_data[8].match(@title_line))     
    end 

    puts match_data[8]
    print "|"
  
  end  
end

def getTitleDetails(current_OpenweekInfo, match_data)
  unless match_data.nil?  
    unless match_data[1].nil? then current_OpenweekInfo.Openweek_day = match_data[1].strip end
    unless match_data[2].nil? then current_OpenweekInfo.Openweek_month = match_data[2].strip end
    unless match_data[3].nil? then current_OpenweekInfo.Openweek_year = match_data[3].strip end
    unless match_data[4].nil? then current_OpenweekInfo.Openweek_screens = match_data[4].strip end
    print "*"
  
  end  
end

def getBusinessDetails(current_OpenweekInfo, match_data)
  unless match_data.nil?
      unless match_data[1].nil? then
      name = match_data[1].strip
        if name =~ /"(.*)"/
                
          print "["
          is_tv_series = true
          current_OpenweekInfo.kind = "tv_series"
          current_OpenweekInfo.name = $~[1]
        else
          current_OpenweekInfo.name = name
          current_OpenweekInfo.kind = "unknown"
        end
      end
              
          unless match_data[2].nil?
             current_OpenweekInfo.year = match_data[2].strip #year
          else
             unless match_data[4].nil? then current_OpenweekInfo.year = match_data[4].strip end# question marks as year
          end
          unless match_data[3].nil? then current_OpenweekInfo.identifier = match_data[3].strip end
          unless match_data[5].nil? then current_OpenweekInfo.extra_info = match_data[5].strip end      
          unless is_tv_series
            case current_OpenweekInfo.extra_info
            when /(\(V\))/
                  current_OpenweekInfo.kind = "video_movie"
            when /(\(TV\))/
                  current_OpenweekInfo.kind = "tv_movie"
            when /(\(VG\))/
                  current_OpenweekInfo.kind = "video_game"
            else
                  current_OpenweekInfo.kind = "movie"
            end
          else
                print "]" 
          end
  end
end



if $0 == __FILE__
  Openweek_manager = DATA_PARSER::OpenweekManager.new
  Openweek_manager.parse_file
  puts "Finished...........!"
end

