#! /usr/local/bin/ruby -w

#########__#########__#########__#########__#########__#########__#########__#########80
#Author: sbp345@nyu.edu (Shubhalakshmi Pai)
#
#Dumps contents of business_Budget.list file in business_Budget table.
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

  class BudgetInfo
    attr_accessor :id, :name, :kind, :year, :release_year, :identifier
    attr_accessor :extra_info
    attr_accessor :Budget_currency, :Budget_amount, :Budget_country, :Budget_extra_info 
    
    def initialize
      @id = -1
      @name = ""
      @year = "?"
      @identifier = ""
      @extra_info = ""
      @release_year = "?"
      @kind = ""
      @Budget_currency = ""
      @Budget_amount = ""
      @Budget_country = ""
      @Budget_extra_info = ""
      #@business_info = ""
    end   
  end


 #Box Office Budget 
  
  class BudgetManager
    def initialize
      @inserted_Budgetinfo = 0
      @Budget_id = 0 #change to lateset value if table not empty
    end

    def insert_Business_Budget(business_info)
      @Budget_id += 1 # new id
      if @inserted_Budgetinfo == 0
        @Budgetinfo_insert.puts  "insert into Business_Budget (id, name, `year`, identifier, extra_info, kind, Business_Budget_currency, Business_Budget_amount, Business_Budget_country,Business_Budget_extra_info)\n values"
        @Budgetinfo_insert.print "  (#{@db.escape_string(@Budget_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Budget_currency.to_s)}', '#{@db.escape_string(business_info.Budget_amount.to_s)}', '#{@db.escape_string(business_info.Budget_country.to_s)}','#{@db.escape_string(business_info.Budget_extra_info.to_s)}'),\n"
        @inserted_Budgetinfo += 1
      elsif @inserted_Budgetinfo == 10000
        @inserted_Budgetinfo = 0 # reset
        @Budgetinfo_insert.puts ";\n" # close previous insert query
        @Budgetinfo_insert.puts  "insert into Business_Budget (id, name, `year`, identifier, extra_info, kind, Business_Budget_currency, Business_Budget_amount, Business_Budget_country,Business_Budget_extra_info,Business_Budget_day,Business_Budget_month,Business_Budget_year)\n values"
        @Budgetinfo_insert.print "  (#{@db.escape_string(@Budget_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Budget_currency.to_s)}', '#{@db.escape_string(business_info.Budget_amount.to_s)}', '#{@db.escape_string(business_info.Budget_country.to_s)}','#{@db.escape_string(business_info.Budget_extra_info.to_s)}'),\n" 
        puts "{#{@Budget_id}}" #progress indicator
        @inserted_Budgetinfo += 1
      else
        @Budgetinfo_insert.print "  (#{@db.escape_string(@Budget_id.to_s)}, '#{@db.escape_string(business_info.name.to_s)}', '#{@db.escape_string(business_info.year.to_s)}', '#{@db.escape_string(business_info.identifier.to_s)}', '#{@db.escape_string(business_info.extra_info.to_s)}', '#{@db.escape_string(business_info.kind.to_s)}', '#{@db.escape_string(business_info.Budget_currency.to_s)}', '#{@db.escape_string(business_info.Budget_amount.to_s)}', '#{@db.escape_string(business_info.Budget_country.to_s)}','#{@db.escape_string(business_info.Budget_extra_info.to_s)}'), \n"
        @inserted_Budgetinfo += 1
      end
    end
    
    def parse_file
      reached_data = false 
      @Budgetinfo_read = 0
      @Budgetinfo_missed = 0
      @missed= File.open("missed_Budgetinfo", "w")
      @Budgetinfo_insert = File.open("insert_business_Budget.sql", "w")
      #open database
      @db = Mysql.real_connect('localhost', 'root', '', 'imdb_prod')
      current_BudgetInfo = BudgetInfo.new
      
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
          business1_line = /(?:^BT:) \s+ (.*) \s+ (\$|)([1-9]\d{0,2}(\,\d{3})*|([1-9]\d*))(\.\d{2})? (.*)/x
         #1.identifier 2.currency 3.amount 4.country 5.extra_info 6.day 7.month 8.year
          business2_line = /(?:\((\d{1,2})\s(\w+)\s(\d{4})\)) (.*)/x
          ## Date validation 
          @title_line = /(?:\((\w+)\)) (.*)/x
          #1. Name 2. Year 3. Identifier 4. ???? 5. Extra_info 
          case line
          when empty_line
           print "|" 
            next  
          when business_line
          current_BudgetInfo = BudgetInfo.new
          match_data = Regexp.last_match    
            print "-"
            #is_tv_series = false
            #regular Business_Budget line
          getBusinessDetails(current_BudgetInfo, Regexp.last_match)
          @Budgetinfo_read += 1
          when business1_line
          getBudgetinfoDetails(current_BudgetInfo, Regexp.last_match)
          @Budgetinfo_read += 1
          insert_Business_Budget(current_BudgetInfo)
          else
            @Budgetinfo_missed += 1
            @missed.puts line
            next
          end
        end
      end
      @db.close
      @Budgetinfo_insert.close
      @missed.puts "Missed: " + @Budgetinfo_missed  .to_s
      @missed.puts "Hits: " + @Budgetinfo_read.to_s
      @missed.close
    end
  end
end

def getBudgetinfoDetails(current_BudgetInfo, match_data)
  unless match_data.nil?  
    unless match_data[1].nil? then current_BudgetInfo.Budget_currency = match_data[1].strip end
    unless match_data[3].nil? then current_BudgetInfo.Budget_amount = match_data[3].strip end
    unless match_data[7].nil? then current_BudgetInfo.Budget_extra_info = match_data[7].strip end  
    getTitleDetails(current_BudgetInfo, match_data[7].match(@title_line))

    #puts match_data[8]
    print "|"
  
  end  
end

def getTitleDetails(current_BudgetInfo, match_data)
  unless match_data.nil?  
    unless match_data[1].nil? then current_BudgetInfo.Budget_country = match_data[1].strip end            
    print "*"
  
  end  
end

def getBusinessDetails(current_BudgetInfo, match_data)
  unless match_data.nil?
      unless match_data[1].nil? then
      name = match_data[1].strip
        if name =~ /"(.*)"/
                
          print "["
          is_tv_series = true
          current_BudgetInfo.kind = "tv_series"
          current_BudgetInfo.name = $~[1]
        else
          current_BudgetInfo.name = name
          current_BudgetInfo.kind = "unknown"
        end
      end
              
          unless match_data[2].nil?
             current_BudgetInfo.year = match_data[2].strip #year
          else
             unless match_data[4].nil? then current_BudgetInfo.year = match_data[4].strip end# question marks as year
          end
          unless match_data[3].nil? then current_BudgetInfo.identifier = match_data[3].strip end
          unless match_data[5].nil? then current_BudgetInfo.extra_info = match_data[5].strip end      
          unless is_tv_series
            case current_BudgetInfo.extra_info
            when /(\(V\))/
                  current_BudgetInfo.kind = "video_movie"
            when /(\(TV\))/
                  current_BudgetInfo.kind = "tv_movie"
            when /(\(VG\))/
                  current_BudgetInfo.kind = "video_game"
            else
                  current_BudgetInfo.kind = "movie"
            end
          else
                print "]" 
          end
  end
end



if $0 == __FILE__
  Budget_manager = DATA_PARSER::BudgetManager.new
  Budget_manager.parse_file
  puts "Finished...........!"
end

