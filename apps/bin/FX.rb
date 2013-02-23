# -*- coding: utf-8 -*-
#############################################
#
#  FX
#
#############################################
$:.unshift(File.dirname(__FILE__) + "/../lib")
$:.unshift(File.dirname(__FILE__) + "/../bin")
require "common"
require "FXBase"
require "Viewer"
require "Graph"
require "Historical"
require 'sqlite3'

class FX
  def initialize
    @CSVFiles = Hash.new
    @fx_base = FXBase.new
    @historical = Historical.new
  end

  #
  # Get Historical Data
  #  - save CSV files
  #
  def get_HistoricalData
    # Get Historical Data
    printf "@I:Get Historical Data from #{@fx_base.historical_base_url}\n"
    @fx_base.db_list.each do |key,value|
      url = @fx_base.historical_base_url + "ccy=" + value[1].to_s + "&type=d"
      file = @fx_base.data_dir + "/" + value[3]
      printf "[#{key}]Get Historical Data from #{url} ... "
      @CSVFiles[key] = file
      f = open(file,"w")
      open(url).each do |line|
        f.printf line
      end
      f.close
      printf "Done\n"
      printf " - #{file} (#{File::stat(file).mtime})\n"
      # Check File Size
      if File::stat(file).size < 10000
        printf "@E:Maybe could not get Historical Data. please check #{file}\n"
        exit 1
      end
    end
  end

  #
  # Make Historical DB
  #
  def make_HistoricalDB
    printf "\n@I:Make Historical DB\n"
    @fx_base.db_list.each do |key,value|
      printf " - Making DB for #{key}\n"
      db_name = value[2]
      db = SQLite3::Database.new("#{@fx_base.db_dir}/#{db_name}")
      begin
        db.execute(@fx_base.historical_sql)
      rescue
      end
      @historical.analyze_csv(key,db,@CSVFiles[key],db_name)
      db.close
    end
    
  end

  def generate
    viewer = Viewer.new(@fx_base.result_dir,@fx_base.db_dir,@fx_base.db_list)
    printf "@I:Generate Historical Data to TXT\n"
    viewer.generate_TechnicalData
    printf "@I:Generate Histrrical Data to Excel\n"
#    viewer.generate_Excel
#    printf "@I:Generate Analyzed Data to CSV\n"
#    viewer.generate_Trade
    printf "@I:Generate Graph\n"
    viewer.generate_Graph
  end

  #
  # Main Operation
  #
  def main
    Common.print_base
    printf "@I:Start FX Analyze\n"
    # Get Historical Data from WEB
    get_HistoricalData
    # Make Historical DataBase
    make_HistoricalDB
    # generate
    generate
    Common.print_summary
  end
end

if __FILE__ == $0
  fx = FX.new
  fx.main
end
