#!/usr/local/bin/ruby -K
# -*- coding: utf-8 -*-
##########################################
# 
# Chart
#  - Generate Chart from Historical Data
#
##########################################
$:.concat(["#{File.dirname(__FILE__)}/../lib"])
require 'common'
require 'GetHistoricalData'
require 'sqlite3'
require 'csv'
require 'FXBase'

class Chart
  include FXBase
  def initialize(db_dir,db_list,tmp_dir="/home/koji/tmp")
    @db_dir = db_dir
    @chart = db_list
    @tmp_dir = tmp_dir
    @chart_sql = get_ChartSQL
  end
  
  def make_ChartDB
    printf "@I:Make each Chart-DB\n"
    @chart.each{|key,value|
      printf "@I:Making DB for #{key}\n"
      db_name = value[2] # db_name
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      begin
        db.execute(@chart_sql)
      rescue
        # do nothing
      end
      analyze_csv(db,"#{@tmp_dir}/#{value[0]}",value[2])
      db.close
    }
  end

  #
  #
  #
  def analyze_csv(db,csv_file,db_name)
    # chart [StartDate,EndDate,StartValue,EndValue]
    chart = Array.new
    i = 0
    CSV.foreach("#{csv_file}"){|row|
      i += 1
      next if row[0].to_i == 0
      #-----------------------------------
      # make Thechnical table
      #-----------------------------------
      # Get HistoricalData from CSV file
      flag = nil
      date = row[0].to_s.gsub("/","-")
      start_value = row[1].to_f
      highest_value = row[2].to_f
      lowest_value = row[3].to_f
      end_value = row[4].to_f
      end_value = start_value if i == 1
      if chart.size == 0
        # first
        chart = ["#{flag}","#{date}","#{end_value}","#{start_value}","#{end_value}"]
        p chart
      else
        # next
        pre_end_value = chart[4]
        if end_value.to_f > pre_end_value.to_f 
          # UP
          flag = "UP"
          pre_start_value = chart[3]
          chart = ["#{flag}","#{date}","#{end_value}","#{pre_start_value}","#{end_value}"]
          p flag
          p chart
        else
          flag = "DOWN"
          pre_start_value = chart[3]
          chart = ["#{flag}","#{date}","#{end_value}","#{pre_start_value}","#{end_value}"]
          p flag
          p chart
        end
      end
      p chart
      # Save Data to SQL
=begin
      begin
        sql = "insert into chart values ('#{date}',
                                               #{start_value},
                                               #{highest_value},
                                               #{lowest_value},
                                               #{end_value},
                                               #{ema12},
                                               #{ema26},
                                               #{macd},
                                               #{signal},
                                               #{judge},
                                               '#{trade}',
                                               #{turning_value},
                                               0
                                              )"
        db.execute(sql)
        printf("\tAdd Historical data at %s to %s(trade:%s)\n",date,db_name,trade)
      rescue
        # Skip.Already Saved.
      end
=end
    }
    exit
  end


  def main
    make_ChartDB
  end

end

if __FILE__ == $0
  chart = Chart.new
  chart.main
end
