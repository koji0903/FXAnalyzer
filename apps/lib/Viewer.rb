# -*- coding: utf-8 -*-
####################################################
#
# Analyze FX-Data From DB
#
# Usage
#   param : 
#
####################################################
require "common"
require 'sqlite3'
require 'Graph'

class Viewer

  def initialize(result_dir,db_dir,db_list)
    @result_dir = result_dir
    @db_dir = db_dir
    @db_list = db_list
  end

  private
  def getLast30DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 30;")
  end

  private
  def getLast100DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 300;")
  end

  private
  def getLast10DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 10;")
  end

  private
  def getLast1DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 1;")
  end

  private
  def getCSV(f,db,table,num)
    f.printf "Date,Start Value,Highest Value,diff,Lowest Value,diff,End Value,diff,EMA12,diff,EMA26,diff,MACD,diff,Signal,diff,Judge,diff,Trade,Turning Value,Resistance Value,Chart Flag,\n"
    db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 100;").sort_by{|row|
      row[0]
    }.each{|row|
      row.each{|column|
        if column.class == Float
          f.printf "%.#{num}f,",column
        else
          f.printf "#{column},"
        end
      }
      f.printf "\n"
    }
  end

  def getCSV_all(f,db,table,num)
    f.printf "Date,Start Value,Highest Value,Lowest Value,End Value,EMA12,EMA26,MACD,Signal,Judge,Trade,Turning Value,Differ,Resistance Value,Chart Flag,\n"
    db.execute("SELECT * FROM #{table}").sort_by{|row|
      row[0]
    }.each{|row|
      row.each{|column|
        if column.class == Float
          f.printf "%.#{num}f,",column
        else
          f.printf "#{column},"
        end
      }
      f.printf "\n"
    }
  end

  
  def view(f,category,data)
    f.printf("====[%s]====\n",category)
    data.sort_by{|each_data|
      each_data[0]
    }.each{|each_data|
      case each_data[18]
      when "Long"
        judge = "買"
      when "Short"
        judge = "売"
      end
      case category
      when "EUR/USD", "AUD/USD", "NZD/USD"
        f.printf("[%s]判定:%s[終値:%.4f%s(高値:%.4f%s,安値:%.4f%s), EMA12:%.4f%s,EMA26:%.4f%s,MACD:%.4f%s,SIGNAL:%.4f%s,分析値:%.2f%s, 変化値:%.4f%s(差:%.4f%s)]\n",
                 each_data[0], # category
                 judge,          
                 each_data[6], # end value
                 direction(each_data[7]),
                 each_data[2], # Highest Value
                 direction(each_data[3]),
                 each_data[4], # Lowest value
                 direction(each_data[5]),
                 each_data[8], # ema12
                 direction(each_data[9]),
                 each_data[10], # ema26
                 direction(each_data[11]),
                 each_data[12], # macd
                 direction(each_data[13]),
                 each_data[14], # signal
                 direction(each_data[15]),
                 each_data[16]*100, # judge
                 direction(each_data[17]),
                 each_data[19],
                 direction(each_data[20]),
                 (each_data[6]-each_data[19]).abs,
                 direction(each_data[6]-each_data[19])
                 )
      else
        f.printf("[%s]判定:%s[終値:%.2f%s(高値:%.4f%s,安値:%.4f%s), EMA12:%.4f%s,EMA26:%.4f%s,MACD:%.4f%s,SIGNAL:%.4f%s,分析値:%.2f%s, 変化値:%.2f%s(差:%.2f%s)]\n",
                 each_data[0], # category
                 judge,          
                 each_data[6], # end value
                 direction(each_data[7]),
                 each_data[2], # Highest Value
                 direction(each_data[3]),
                 each_data[4], # Lowest value
                 direction(each_data[5]),
                 each_data[8], # ema12
                 direction(each_data[9]),
                 each_data[10], # ema26
                 direction(each_data[11]),
                 each_data[12], # macd
                 direction(each_data[13]),
                 each_data[14], # signal
                 direction(each_data[15]),
                 each_data[16],
                 direction(each_data[17]),
                 each_data[19],
                 direction(each_data[20]),
                 (each_data[6]-each_data[19]).abs,
                 direction(each_data[6]-each_data[19])
                 )
      end
    }
    f.printf "\n"
  end

  #
  public
  def generate_TechnicalData
    # get 10 days Data
    file = "#{@result_dir}/00Last10DaysData.txt"
    printf("@I:generate %s\n",file)
    f = open(file,"w")
    @db_list.each{|category,value|
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      data = getLast10DaysData(db,table)
      view(f,category,data)
    }
    f.close

    # get 1 day Data
    file = "#{@result_dir}/01Last1DaysData.txt"
    printf("@I:generate %s\n",file)
    f = open(file,"w")
    @db_list.each{|category,value|
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      data = getLast1DaysData(db,table)
      view(f,category,data)
    }
   f.close

  end

  #
  # Genrete CSV Data (Last 100days and All data )
  #
  def generate_CSV
    # 100days CSV
    @db_list.each{|category,value|
      file = "#{@result_dir}/#{value[0]}"
      printf("@I:generate %s\n",file)
      f = open(file,"w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      case db_name
      when /eurusd/, /audusd/,/nzdusd/
        num = 6
      else
        num = 4
      end
      getCSV(f,db,table,num)
      f.close
    }
    # All days CSV
    @db_list.each{|category,value|
      file = "#{@result_dir}/ALL_#{value[0]}"
      printf("@I:generate %s\n",file)
      f = open(file,"w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      case db_name
      when /eurusd/, /audusd/,/nzdusd/
        num = 6
      else
        num = 4
      end
      getCSV_all(f,db,table,num)
      f.close
    }
  end

  def generate_Graph
    @db_list.each do |category,value|
      db_name = value[2]
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      data = getLast30DaysData(db,"historical")
#        f.printf("[%s]判定:%s[終値:%.4f(高値:%.4f,安値:%.4f), EMA12:%.4f,EMA26:%.4f,MACD:%.4f,SIGNAL:%.4f,分析値:%.2f, 変化値:%.4f(差:%.4f)]\n",
#Date:each_data[0]
#Judge:judge
#EndValue:each_data[4]
#HighValue:each_data[2]
#LowValue:each_data[3]
#EMA12:each_data[5]
#EMA26:each_data[6]
#MACD:each_data[7]
#SIGNAL:each_data[8]
#AnalyzeData:each_data[9]*100
#ChangeVlalue:each_data[11]
#Differ:(each_data[4]-each_data[11]).abs
#       make_Value(data,category,value)
       make_EMA(data,category,value)
#       make_Judge(data,category,value)
      data = getLast100DaysData(db,"historical")
       make_EMA_long(data,category,value)

    end
  end
  
  def direction(num)
    if num >= 0
      return "↑"
    else
      return "↓"
    end
  end

  def make_Value(data,category,value)
      data_value = Hash.new
      end_value = Array.new
      high_value = Array.new
      low_value = Array.new
      change_value =  Array.new
      ema12_value = Array.new
      ema26_value = Array.new
      

      i = 0
      data.sort_by do |each_data|
        each_data[0]
      end.each do |each_data|
        end_value << ('%.4f' % each_data[6]).to_f
        high_value << ('%.4f' % each_data[2]).to_f
        low_value << ('%.4f' % each_data[4]).to_f
        ema12_value << ('%.4f' % each_data[8]).to_f
        ema26_value << ('%.4f' % each_data[10]).to_f
#p  each_data[11]
#p '%.4f' % each_data[11]
#exit
        change_value << ('%.4f' % each_data[19]).to_f
        if i%5 == 4
           data_value[i] = each_data[0] 
        end
        i += 1
      end
      
      out_file = value[0].sub(".csv","_value.png")
      gruff_data = Hash.new
      gruff_data["End Value"] = end_value
      gruff_data["High Value"] = high_value
      gruff_data["Low Value"] = low_value
      gruff_data["Change Value"] = change_value
#      gruff_data["EMA12"] = ema12_value
#      gruff_data["EMA26"] = ema26_value
       # Make Graph
      graph = MyGraph.new( :result_dir => @reuslt_dir,
                           :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value
                              )
      graph.add_data
      graph.add_title
      graph.generate
  end
  
  def make_EMA(data,category,value)
      data_value = Hash.new
      end_value = Array.new
      high_value = Array.new
      low_value = Array.new
      ema12_value = Array.new
      ema26_value = Array.new
      

      i = 0
      data.sort_by do |each_data|
        each_data[0]
      end.each do |each_data|
        end_value << ('%.4f' % each_data[6]).to_f
        high_value << ('%.4f' % each_data[2]).to_f
        low_value << ('%.4f' % each_data[4]).to_f
        ema12_value << ('%.4f' % each_data[8]).to_f
        ema26_value << ('%.4f' % each_data[10]).to_f
        if i%5 == 4
           data_value[i] = each_data[0] 
        end
        i += 1
      end
      
      out_file = value[0].sub(".csv","_EMA.png")
      gruff_data = Hash.new
      gruff_data["End Value"] = end_value
      gruff_data["High Value"] = high_value
      gruff_data["Low Value"] = low_value
      gruff_data["EMA12"] = ema12_value
      gruff_data["EMA26"] = ema26_value

       # Make Graph
      graph = MyGraph.new( :result_dir => @result_dir,
                           :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value
                              )
    
      graph.add_data
      graph.add_title
      graph.generate
  end

  def make_EMA_long(data,category,value)
      data_value = Hash.new
      end_value = Array.new
      high_value = Array.new
      low_value = Array.new
      ema12_value = Array.new
      ema26_value = Array.new
      

      i = 0
      data.sort_by do |each_data|
        each_data[0]
      end.each do |each_data|
        end_value << ('%.4f' % each_data[6]).to_f
        high_value << ('%.4f' % each_data[2]).to_f
        low_value << ('%.4f' % each_data[4]).to_f
        ema12_value << ('%.4f' % each_data[8]).to_f
        ema26_value << ('%.4f' % each_data[10]).to_f
        if i%5 == 4
           data_value[i] = each_data[0] 
        end
        i += 1
      end
      
      out_file = value[0].sub(".csv","_EMA_long.png")
      gruff_data = Hash.new
      gruff_data["End Value"] = end_value
      gruff_data["High Value"] = high_value
      gruff_data["Low Value"] = low_value
      gruff_data["EMA12"] = ema12_value
      gruff_data["EMA26"] = ema26_value

       # Make Graph
      graph = MyGraph.new( :result_dir => @result_dir, 
                           :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value
                              )
      graph.add_data
      graph.add_title
      graph.generate
  end


  def make_Judge(data,category,value)
#MACD:each_data[7]
#SIGNAL:each_data[8]
#AnalyzeData:each_data[9]*100

      data_value = Hash.new
      macd_value = Array.new
      signal_value = Array.new
      analyze_value = Array.new
      

      i = 0
      data.sort_by do |each_data|
        each_data[0]
      end.each do |each_data|
        macd_value << ('%.4f' % each_data[12]).to_f
        signal_value << ('%.4f' % each_data[14]).to_f
        analyze_value << ('%.4f' % each_data[16]*100).to_f
        if i%5 == 4
           data_value[i] = each_data[0] 
        end
        i += 1
      end
      
      out_file = value[0].sub(".csv","_Judge.png")
      gruff_data = Hash.new
      gruff_data["MACD"] = macd_value
      gruff_data["Signal"] = signal_value
      gruff_data["Analyze"] = analyze_value

       # Make Graph
    graph = MyGraph.new( :result_dir => @result_dir,
                           :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value,
                              )
      graph.add_data
      graph.add_title
      graph.generate
  end


  public
  def main
    printf "@I:Analyze Historical Data\n"
    printf "@I:Generate Historical Data to TXT\n"
    generate_TechnicalData
    printf "@I:Generate Histrrical Data to CSV\n"
    generate_CSV
    printf "@I:Generate Analyzed Data to CSC\n"
    generate_Trade
    printf "@I:Generate Graph\n"
    generate_Graph
  end
end
