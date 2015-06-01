#! /usr/local/bin/ruby -w

#########__#########__#########__#########__#########__#########__#########__#########80
#Author: sbp345@nyu.edu (Shubhalakshmi Pai)
#
#Dumps contents of business_Gross.list file in business_Gross table.
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

  class GrossInfo
    attr_accessor :id, :name, :kind, :year, :release_year, :identifier
    attr_accessor :extra_info
    attr_accessor :Gross_currency, :Gross_amount, :Gross_country, :Gross_extra_info, :Gross_day ,:Gross_month, :Gross_year 
    
    def initialize
      @id = -1
      @name = ""
      @year = "?"
      @identifier = ""
      @extra_info = ""
      @release_year = "?"
      @kind = ""
      @Gross_currency = ""
      @Gross_amount = ""
      @Gross_country = ""
      @Gross_extra_info = ""
      @Gross_day = ""
      @Gross_month = ""
      @Gross_year = ""
      #@business_info = ""
    end   
  end


 #Box Office Gross 
  
  class GrossManager
    def initialize
      @inserted_Grossinfo = 0
      @Gross_id = 0 #change to lateset value if table not empty
    end

    def insert_Business_Gross(business_info)
      @Gross_id += 1 # new id
      if @inserted_Grossinfo == 0
        @Grossinfo_insert.puts  "insert into Business_Gross (id, name, `year`, identifier, extra_info, kind, Business_Gross_currency, Business_Gross_amount, Business_Gross_country,Business_Gross_extra_info,Business_Gross_day,Business_Gross_month,Business_Gross_year)\n values"
        @Grossinfo_insert.print "  (#{@db.escape_string(@Gross_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Gross_currency.to_s)}', '#{@db.escape_string(business_info.Gross_amount.to_s)}', '#{@db.escape_string(business_info.Gross_country.to_s)}','#{@db.escape_string(business_info.Gross_extra_info.to_s)}','#{@db.escape_string(business_info.Gross_day.to_s)}','#{@db.escape_string(business_info.Gross_month.to_s)}','#{@db.escape_string(business_info.Gross_year.to_s)}'),\n"
        @inserted_Grossinfo += 1
      elsif @inserted_Grossinfo == 10000
        @inserted_Grossinfo = 0 # reset
        @Grossinfo_insert.puts ";\n" # close previous insert query
        @Grossinfo_insert.puts  "insert into Business_Gross (id, name, `year`, identifier, extra_info, kind, Business_Gross_currency, Business_Gross_amount, Business_Gross_country,Business_Gross_extra_info,Business_Gross_day,Business_Gross_month,Business_Gross_year)\n values"
        @Grossinfo_insert.print "  (#{@db.escape_string(@Gross_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Gross_currency.to_s)}', '#{@db.escape_string(business_info.Gross_amount.to_s)}', '#{@db.escape_string(business_info.Gross_country.to_s)}','#{@db.escape_string(business_info.Gross_extra_info.to_s)}','#{@db.escape_string(business_info.Gross_day.to_s)}','#{@db.escape_string(business_info.Gross_month.to_s)}','#{@db.escape_string(business_info.Gross_year.to_s)}'),\n" 
        puts "{#{@Gross_id}}" #progress indicator
        @inserted_Grossinfo += 1
      else
        @Grossinfo_insert.print "  (#{@db.escape_string(@Gross_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Gross_currency.to_s)}', '#{@db.escape_string(business_info.Gross_amount.to_s)}', '#{@db.escape_string(business_info.Gross_country.to_s)}','#{@db.escape_string(business_info.Gross_extra_info.to_s)}','#{@db.escape_string(business_info.Gross_day.to_s)}','#{@db.escape_string(business_info.Gross_month.to_s)}','#{@db.escape_string(business_info.Gross_year.to_s)}'), \n"
        @inserted_Grossinfo += 1
      end
    end
    
    def parse_file
      reached_data = false 
      @Grossinfo_read = 0
      @Grossinfo_missed = 0
      @missed= File.open("missed_Grossinfo", "w")
      @Grossinfo_insert = File.open("insert_business_Gross.sql", "w")
      #open database
      @db = Mysql.real_connect('localhost', 'root', '', 'imdb_prod')
      current_GrossInfo = GrossInfo.new
      
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
          business1_line = /(?:^GR:) \s+ (.*) \s+ (\$|)([1-9]\d{0,2}(\,\d{3})*|([1-9]\d*))(\.\d{2})? \s+ (?:\((\w+)\)) (.*)/x
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
          current_GrossInfo = GrossInfo.new
          match_data = Regexp.last_match    
            print "-"
            #regular Business_Gross line
          getBusinessDetails(current_GrossInfo, Regexp.last_match)
          @Grossinfo_read += 1
          when business1_line
          getGrossinfoDetails(current_GrossInfo, Regexp.last_match)
          @Grossinfo_read += 1
          insert_Business_Gross(current_GrossInfo)
          else
            @Grossinfo_missed += 1
            @missed.puts line
            next
          end
        end
      end
      @db.close
      @Grossinfo_insert.close
      @missed.puts "Missed: " + @Grossinfo_missed  .to_s
      @missed.puts "Hits: " + @Grossinfo_read.to_s
      @missed.close
    end
  end
end

def getGrossinfoDetails(current_GrossInfo, match_data)
  unless match_data.nil?  
    unless match_data[1].nil? then current_GrossInfo.Gross_currency = match_data[1].strip end
    unless match_data[3].nil? then current_GrossInfo.Gross_amount = match_data[3].strip end
    unless match_data[7].nil? then current_GrossInfo.Gross_country = match_data[7].strip end
    unless match_data[8].nil? then current_GrossInfo.Gross_extra_info = match_data[8].strip end  
    unless current_GrossInfo.Gross_extra_info.nil?  
    getTitleDetails(current_GrossInfo, match_data[8].match(@title_line))     
    end 

    puts match_data[8]
    print "|"
  
  end  
end

def getTitleDetails(current_GrossInfo, match_data)
  unless match_data.nil?  
    unless match_data[1].nil? then current_GrossInfo.Gross_day = match_data[1].strip end
    unless match_data[2].nil? then current_GrossInfo.Gross_month = match_data[2].strip end
    unless match_data[3].nil? then current_GrossInfo.Gross_year = match_data[3].strip end           
    print "*"
  
  end  
end

def getBusinessDetails(current_GrossInfo, match_data)
  unless match_data.nil?
      unless match_data[1].nil? then
      name = match_data[1].strip
        if name =~ /"(.*)"/
                
          print "["
          is_tv_series = true
          current_GrossInfo.kind = "tv_series"
          current_GrossInfo.name = $~[1]
        else
          current_GrossInfo.name = name
          current_GrossInfo.kind = "unknown"
        end
      end
              
          unless match_data[2].nil?
             current_GrossInfo.year = match_data[2].strip #year
          else
             unless match_data[4].nil? then current_GrossInfo.year = match_data[4].strip end# question marks as year
          end
          unless match_data[3].nil? then current_GrossInfo.identifier = match_data[3].strip end
          unless match_data[5].nil? then current_GrossInfo.extra_info = match_data[5].strip end      
          unless is_tv_series
            case current_GrossInfo.extra_info
            when /(\(V\))/
                  current_GrossInfo.kind = "video_movie"
            when /(\(TV\))/
                  current_GrossInfo.kind = "tv_movie"
            when /(\(VG\))/
                  current_GrossInfo.kind = "video_game"
            else
                  current_GrossInfo.kind = "movie"
            end
          else
                print "]" 
          end
  end
end



if $0 == __FILE__
  Gross_manager = DATA_PARSER::GrossManager.new
  Gross_manager.parse_file
  puts "Finished...........!"
end

