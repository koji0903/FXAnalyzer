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

class HistoricalViewer

  def initialize(db_dir,db_list)
    @result_dir = "../../result"
    @db_dir = db_dir
    @db_list = db_list
  end

  private
  def getLast10DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 10;")
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

  def generate_TechnicalData
    # get Data
    f = open("#{@result_dir}/Last10DaysData.txt","w")
    @db_list.each{|category,value|
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      data = getLast10DaysData(db,table)
      view(f,category,data)
    }
    f.close
  end

  def generate_CSV
    @db_list.each{|category,value|
      f = open("#{@result_dir}/#{value[0]}","w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      getCSV(f,db,table)
      f.close
    }
    @db_list.each{|category,value|
      f = open("#{@result_dir}/ALL_#{value[0]}","w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      getCSV_all(f,db,table)
      f.close
    }
  end

  public
  def main
    printf "@I:Analyze Historical Data\n"
    printf "@I:Generate Historical Data\n"
    generate_TechnicalData
    printf "@I:Generate Analyzed data to CSV\n"
    generate_CSV
  end
end
