#
#
#
require 'csv'
class Historical
  def initialize
  end

  def analyze_csv(category,db,csv_file,db_name)
    pre_HighestValue = 0
    pre_LowestValue = 0
    pre_EndValue = 0
    pre_ema12 = 0
    pre_ema26 = 0
    pre_macd = 0
    pre_signal = 0
    pre_judge = 0
    pre_turningvalue = 0
    pre_differ = 0

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
    open("#{csv_file}").each do |row|
      num += 1
    end
    i = 0
    CSV.foreach("#{csv_file}") do |row|
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
        highest_value_differ = highest_value - pre_HighestValue
        lowest_value_differ = lowest_value - pre_LowestValue
        end_value_differ = end_value - pre_EndValue
        ema12_direction = ema12 - pre_ema12
        ema26_direction = ema26 - pre_ema26
        macd_direction = macd - pre_macd
        signal_direction = signal - pre_signal
        judge_direction = judge - pre_judge
        turningvalue_direction = turning_value - pre_turningvalue
        differ_direction = differ - pre_differ
        sql = "insert into historical values ('#{date}',
                                               #{start_value},
                                               #{highest_value},
                                               #{highest_value_differ},
                                               #{lowest_value},
                                               #{lowest_value_differ},
                                               #{end_value},
                                               #{end_value_differ},
                                               #{ema12},
                                               #{ema12_direction},
                                               #{ema26},
                                               #{ema26_direction},
                                               #{macd},
                                               #{macd_direction},
                                               #{signal},
                                               #{signal_direction},
                                               #{judge},
                                               #{judge_direction},
                                               '#{trade}',
                                               #{turning_value},
                                               #{turningvalue_direction},
                                               #{differ},
                                               #{differ_direction},
                                               #{resistance_value},
                                               0
                                              )"
        db.execute(sql)
        printf("\tAdd Historical data at %s to %s(trade:%s)\n",date,db_name,trade)
      rescue
#        printf "Already saved\n"
      end

      pre_HighestValue = highest_value
      pre_LowestValue = lowest_value
      pre_EndValue = end_value
      pre_ema12 = ema12
      pre_ema26 = ema26
      pre_macd = macd
      pre_signal = signal
      pre_turningvalue = turning_value
      pre_differ = differ

    end
  end

  def direction(a,b)
    if a == b
      return "save"
    elsif a > b
      return "up"
    else
      return "down"
    end
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

end
