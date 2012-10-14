#!/usr/local/bin/ruby
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

class HistoricalViewer

  def initialize(db_dir,db_list)
    @result_dir = "/home/koji/workspace/FXAnalyzer/result"
    @db_dir = db_dir
    @db_list = db_list
  end

  private
  def getLast30DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 30;")
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
  def getCSV(f,db,table)
    f.printf "Date,Start Value,Highest Value,Lowest Value,End Value,EMA12,EMA26,MACD,Signal,Judge,Trade,Turning Value,Resistance Value,Chart Flag,\n"
    db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 100;").sort_by{|row|
      row[0]
    }.each{|row|
      row.each{|column|
        f.printf "#{column},"
      }
      f.printf "\n"
    }
  end

  def getCSV_all(f,db,table)
    f.printf "Date,Start Value,Highest Value,Lowest Value,End Value,EMA12,EMA26,MACD,Signal,Judge,Trade,Turning Value,Differ,Resistance Value,Chart Flag,\n"
    db.execute("SELECT * FROM #{table}").sort_by{|row|
      row[0]
    }.each{|row|
      row.each{|column|
        f.printf "#{column},"
      }
      f.printf "\n"
    }
  end

  def getTrade_all(f,db,table)
    str = ""
    data = Array.new
    # 3: End Value
    # 4: EMA12,
    # 5: EMA26,
    # 6: MACD,
    # 7: Signal,
    # 8: Judge,
    # 9: Trade,
    # 10: Turning Value,
    # 11: Differ,
    # 12: Resistance Value,
    # 13: Chart 
    # 14: Flag,
    f.printf "EMA12,EMA26,MACD,Signal,Judge,Next Date Value\n"
    prev = [nil,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    size = db.execute("SELECT * FROM #{table}").size
    db.execute("SELECT * FROM #{table}").sort_by{|row|
      row[0]
    }.each_with_index{|row,j|
      next if j < 10 || j == size
      row.each_with_index{|column,i|
        case i
        when 0
#          f.printf "#{column},"
        when 4
          if j != 10
            value = column.to_f - prev[i].to_f
            f.printf ",#{value}\n"
            data << [str,value]
            str = ""
          end
#        when 5,6,7,8,9,11,12
        when 5,6,7,8,9
          if column.to_f-prev[i].to_f > 0
            f.printf "1"
            str += "1"
          else
            f.printf "0"
            str += "0"
          end
#          f.printf "#{column.to_f-prev[i].to_f},"
        else
          # do nothing
        end
      }
      prev = row
#      f.printf "\n"
    }
    return data
  end
  
  def view(f,category,data)
    f.printf("====[%s]====\n",category)
    data.sort_by{|each_data|
      each_data[0]
    }.each{|each_data|
      case each_data[10]
      when "Long"
        judge = "買"
      when "Short"
        judge = "売"
      end
      case category
      when "EUR/USD", "AUD/USD", "NZD/USD"
        f.printf("[%s]判定:%s[終値:%.4f(高値:%.4f,安値:%.4f), EMA12:%.4f,EMA26:%.4f,MACD:%.4f,SIGNAL:%.4f,分析値:%.2f, 変化値:%.4f(差:%.4f)]\n",each_data[0],judge,each_data[4],each_data[2],each_data[3],each_data[5],each_data[6],each_data[7],each_data[8],each_data[9]*100,each_data[11],(each_data[4]-each_data[11]).abs)
      else
        f.printf("[%s]判定:%s[終値:%.2f(高値:%.4f,安値:%.4f), EMA12:%.4f,EMA26:%.4f,MACD:%.4f,SIGNAL:%.4f,分析値:%.2f, 変化値:%.2f(差:%.2f)]\n",each_data[0],judge,each_data[4],each_data[2],each_data[3],each_data[5],each_data[6],each_data[7],each_data[8],each_data[9],each_data[11],(each_data[4]-each_data[11]).abs)
      end
    }
    f.printf "\n"
  end

  #
  private
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
      getCSV(f,db,table)
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
      getCSV_all(f,db,table)
      f.close
    }
  end

  def generate_Trade
    # All days CSV
    @db_list.each{|category,value|
      file = "#{@result_dir}/Trade_#{value[0]}"
      printf("@I:generate %s\n",file)
      f = open(file,"w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      trade_data = getTrade_all(f,db,table)
      f.close



      #
      # Analyze Trade Data
      #
      trade_data.each do |data_e|
        case data_e[0]
        when "00000"
        when "00001"
        when "00010"
        when "00011"
        when "00100"
        when "00101"
        when "00110"
        when "00111"
        when "01000"
        when "01001"
        when "01010"
        when "01011"
        when "01100"
        when "01101"
        when "01110"
        when "01111"
        when "10000"
        when "10001"
        when "10010"
        when "10011"
        when "10100"
        when "10101"
        when "10110"
        when "10111"
        when "11000"
        when "11001"
        when "11010"
        when "11011"
        when "11100"
        when "11101"
        when "11110"
        when "11111" 
        end
      end      

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
        end_value << ('%.4f' % each_data[4]).to_f
        high_value << ('%.4f' % each_data[2]).to_f
        low_value << ('%.4f' % each_data[3]).to_f
        ema12_value << ('%.4f' % each_data[5]).to_f
        ema26_value << ('%.4f' % each_data[6]).to_f
#p  each_data[11]
#p '%.4f' % each_data[11]
#exit
        change_value << ('%.4f' % each_data[11]).to_f
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
      graph = MyGraph.new( :file => out_file,
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
        end_value << ('%.4f' % each_data[4]).to_f
        high_value << ('%.4f' % each_data[2]).to_f
        low_value << ('%.4f' % each_data[3]).to_f
        ema12_value << ('%.4f' % each_data[5]).to_f
        ema26_value << ('%.4f' % each_data[6]).to_f
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
      graph = MyGraph.new( :file => out_file,
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
        macd_value << ('%.4f' % each_data[7]).to_f
        signal_value << ('%.4f' % each_data[8]).to_f
        analyze_value << ('%.4f' % each_data[9]*100).to_f
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
      graph = MyGraph.new( :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value
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
