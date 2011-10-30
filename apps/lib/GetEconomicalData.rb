#!/usr/local/bin/ruby
####################################################
#
# get FX-Data From internet
#
# Usage
#   param : 
#
####################################################
require "common"
require "GetNetData"
require "date"

class GetEconomicalData
  
  def initialize(economic,save_dir="/home/koji/tmp")
    @economic = economic
    @save_dir = save_dir

    # get today's Year & Month
    start_month = 1
    start_year = 2011
    @ThisYear = Date::today.to_s.split("-")[0].to_i
    @ThisMonth = Date::today.to_s.split("-")[1].to_i
    @YearList = Array.new
    @MonthList = Array.new
    while start_year < @ThisYear do
      @YearList << start_year
      start_year += 1
    end
    while start_month <= @ThisMonth do
      @MonthList << start_month
      start_month += 1
    end
  end

  def main
    saved_FileName = Array.new
    domain = "www.m2j.co.jp"
    printf "Get Economical Data from M2J(%s)\n",domain
    # From Last Year
    @YearList.each{|year|
      [1,2,3,4,5,6,7,8,9,10,11,12].each{|month|
        month = Common.num_trans(month)
        save = "#{@save_dir}/economic_#{year}-#{month}.html"
        get_HtmlData(domain,save,year,month)
        saved_FileName << save
      }
    }

    # This Year
    @MonthList.each{|month|
      month = Common.num_trans(month)
      save = "#{@save_dir}/economic_#{@ThisYear}-#{month}.html"
      get_HtmlData(domain,save,@ThisYear,month)
      saved_FileName << save
    }
    printf "Success(see %s/*)\n",@save_dir
    return saved_FileName
  end
  
  def get_HtmlData(domain,save,year,month)
    path = "market/calendar.php?yy=#{year}&mm=#{month}"
#    if !File.file?("#{save}")
    f = open("#{save}","w")
    file_data = GetNetData.new("#{domain}","#{path}","off").get_economic
    file_data.each{|line|
      if RUBY_PLATFORM != "i386-mingw32"
        line = line.sub("","")
      end
      f.printf("%s",line)
    }
    f.close
#    end
  end
  
end

if __FILE__ == $0
  get_fx_data = GetEconomicData.new
  get_fx_data.main
end
 
