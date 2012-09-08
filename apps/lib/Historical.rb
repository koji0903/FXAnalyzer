#!/usr/local/bin/ruby -K
# -*- coding: utf-8 -*-
##########################################
# 
# Historical
#  - Get Historical CSV Data from Internet
#  - Make Historical Database
#
##########################################
$:.concat(["#{File.dirname(__FILE__)}/../lib"])
require 'common'
require 'GetHistoricalData'
require 'sqlite3'
require 'csv'
require 'FXBase'

class Historical
  include FXBase
  def initialize(db_dir,db_list,tmp_dir="./tmp")
    @db_dir = db_dir
    @historical = db_list
    @tmp_dir = tmp_dir
    @historical_sql = get_HistoricalSQL
  end
  
  def make_HistoricalDB
    printf "@I:Make each DB\n"
    @historical.each{|category,value|
      printf "@I:Making DB for #{category}\n"
      db_name = value[2] # db_name
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      begin
        db.execute(@historical_sql)
      rescue
        # do nothing
      end
      analyze_csv(category,db,"#{@tmp_dir}/#{value[0]}",value[2])
      db.close
    }
  end

  #
  #
  #
  def analyze_csv(category,db,csv_file,db_name)
    ema12_a = Array.new(12,0)
    ema12 = 0
    ema26_a = Array.new(26,0)
    ema26 = 0
    macd = 0
    resistance_value = 0
    signal_a = Array.new(9,0)
    signal = 0
    judge = 0
    trade = nil
    end_value = 0
    turning_value = 0
    differ = 0
    num = 0
    open("#{csv_file}").each{|row|
      num += 1
    }
    i = 0
    CSV.foreach("#{csv_file}"){|row|
      i += 1
      next if row[0].to_i == 0
      #-----------------------------------
      # make Thechnical table
      #-----------------------------------
      # Get HistoricalData from CSV file
      date = row[0].to_s.gsub("/","-")
      start_value = row[1].to_f
      highest_value = row[2].to_f
      lowest_value = row[3].to_f
      end_value = row[4].to_f

      # NEXT if already saved at Date
#      next if search_saved_data(db,date)
      
      target = csv_file.split("/").last.sub(".csv","")

      # Analyze Hisotorical Data(EMA12,EMA26,MACD,SIGNAL,JUDGE)
      ema12,ema12_a = cal_ema12(ema12,ema12_a,"#{end_value}") 
      ema26,ema26_a = cal_ema26(ema26,ema26_a,"#{end_value}") 
      macd = ema12 - ema26 if ema12 != 0 && ema26 != 0
      resistance_value = cal_resistance(target,ema12, ema26)if (ema12 != 0 && ema26 != 0)
      signal,signal_a = cal_signal(signal,signal_a,macd) if macd != 0
      judge = macd - signal if macd != 0 && signal != 0
      if judge > 0; trade = "Long"; else trade = "Short"; end

      # Calucurate Next Turning Value
      if num - 10 < i
        turning_value = cal_NextTurningValue(target,
                                             end_value,
                                             ema12_a,
                                             ema12,
                                             ema26_a,
                                             ema26,
                                             macd,
                                             signal_a,
                                             signal,
                                             judge,
                                             trade,
                                             trade,
                                             end_value)
        differ = (end_value-turning_value).abs
     end

      # Save Data to SQL
      begin
        sql = "insert into historical values ('#{date}',
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
                                               #{differ},
                                               #{resistance_value},
                                               0
                                              )"
        db.execute(sql)
        printf("\tAdd Historical data at %s to %s(trade:%s)\n",date,db_name,trade)
      rescue
        # Skip.Already Saved.
      end
    }
  end

  #
  # cal_NextTurningValue
  #
  def cal_NextTurningValue(target,end_value,ema12_a,ema12,ema26_a,ema26,macd,signal_a,signal,judge,trade,next_trade,org=nil)
    next_trade = nil
    change_value = 0.0
    case target
    when "eurusd", "audusd", "nzdusd"
      change_value = 0.0001
    else
      change_value = 0.01
    end
    
    case trade
    when "Long"
      end_value = end_value - change_value
      next_trade = cal_eachValue(end_value,ema12_a,ema12,ema26_a,ema26,macd,signal_a,signal,judge,trade)
    when "Short"
      end_value = end_value + change_value
      next_trade = cal_eachValue(end_value,ema12_a,ema12,ema26_a,ema26,macd,signal_a,signal,judge,trade)
    else
    end
    if trade != next_trade
      return end_value
    end
    cal_NextTurningValue(target,end_value,ema12_a,ema12,ema26_a,ema26,macd,signal_a,signal,judge,trade,next_trade)
  end

  def cal_eachValue(end_value,ema12_a,ema12,ema26_a,ema26,macd,signal_a,signal,judge,trade)      
    ema12,ema12_a = cal_ema12(ema12,ema12_a,"#{end_value}") 
    ema26,ema26_a = cal_ema26(ema26,ema26_a,"#{end_value}") 
    macd = ema12 - ema26 if ema12 != 0 && ema26 != 0
    signal,signal_a = cal_signal(signal,signal_a,macd) if macd != 0
    judge = macd - signal if macd != 0 && signal != 0
    next_trade = nil
    if judge > 0; next_trade = "Long"; else next_trade = "Short"; end
    return next_trade
  end
  
  #
  # Calucurate Resistance Value
  #  - ema12 and ema26 is very near
  def cal_resistance(target,ema12,ema26)
    case target
    when "eurusd", "audusd", "nzdusd"
      if (ema12 - ema26).abs < 0.001
        return (ema12 + ema26)/2
      else
        return 0
      end
    else
      if (ema12 - ema26).abs < 0.1
        return (ema12 + ema26)/2
      else
        return 0
      end
    end
  end

  #
  # Search matching Date
  # 
  def search_saved_data(db,date)
    sql = "SELECT Date FROM historical WHERE Date = '#{date}';"
    if db.execute(sql).size != 0
      true
    else 
      false
    end
  end

  #
  # Calucurate EMA12
  #
  def cal_ema12(ema12,ema12_a,end_value)
    if ema12 == 0
      # first time
      ema12_a.delete_at(0)
      ema12_a.push("#{end_value}")
      sum = 0
      ema12_a.size.times{|i|
        sum += ema12_a[i].to_f
      }
      if ema12_a[0] != 0
        ema12 = (sum/12).to_f 
      else
        ema12 = 0
      end
      return ema12,ema12_a
    else
      ema12_a.delete_at(0)
      ema12_a.push("#{end_value}")
      return (end_value.to_f * 2 + ema12.to_f * 11)/13, ema12_a
    end
  end



  #
  # Calucurate EMA26
  #
  def cal_ema26(ema26,ema26_a,end_value)
    if ema26 == 0
      # first time
      ema26_a.delete_at(0)
      ema26_a.push("#{end_value}")
      sum = 0
      ema26_a.size.times{|i|
        sum += ema26_a[i].to_f
      }
      if ema26_a[0] != 0
        ema26 = (sum/26).to_f 
      else
        ema26 = 0
      end
      return ema26,ema26_a
    else
      ema26_a.delete_at(0)
      ema26_a.push("#{end_value}")
      return (end_value.to_f * 2 + ema26.to_f * 25)/27, ema26_a
    end
  end

  #
  # Calucurate Signal
  #
  def cal_signal(signal,signal_a,macd)
    if signal == 0
      # first time
      signal_a.delete_at(0)
      signal_a.push("#{macd}")
      sum = 0
      signal_a.size.times{|i|
        sum += signal_a[i].to_f
      }
      if signal_a[0] != 0
        signal = (sum/9).to_f 
      else
        signal = 0
      end
      return signal,signal_a
    else
      signal_a.delete_at(0)
      signal_a.push("#{macd}")
      return (macd.to_f * 2 + signal.to_f * 8)/10, signal_a
    end
  end

  def main
    # Get Historiclal CSV Data from Internet
    printf "@I:Get Historical Data and save #{@tmp_dir}\n"
    GetHistoricalData.new(@historical,@tmp_dir).main
    # Make DataBase and Save
    make_HistoricalDB
  end

end

if __FILE__ == $0
  historical = Historical.new
  historical.main
end
