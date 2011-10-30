#!/usr/local/bin/ruby
# -*- coding: utf-8 -*-
##########################################
# 
# Historical
#  - Get Historical CSV Data from Internet
#  - Make Historical Database
#
##########################################
$:.concat(["#{File.dirname(__FILE__)}/../lib"])
$:.concat(["#{File.dirname(__FILE__)}/../bin"])
require 'common'
require 'FXBase'
require 'Historical'
require 'Economic'
#require 'Chart'

class FXAnalyzer
  include FXBase
  def initialize
    @db_dir , @db_list = get_FXBase
    if RUBY_PLATFORM == "i386-mingw32"
      @tmp_dir = "../../../../tmp"
    else
      @tmp_dir = "/home/koji/FX/tmp"
    end
    Dir::mkdir("#{@tmp_dir}") if !File.exist?("#{@tmp_dir}")
  end
  
  def get_historical
    historical = Historical.new(@db_dir,@db_list,@tmp_dir)
    historical.main
  end

  def get_economic
    economic = Economic.new(@db_dir,@db_list,@tmp_dir)
    economic.main
  end

  def make_chart
    chart = Chart.new(@db_dir,@db_list,@tmp_dir)
    chart.main
  end

  def main
    # Get Data
    get_historical
    get_economic
    # Analyze & Display
#    make_chart
  end
end

if __FILE__ == $0
  fx = FXAnalyzer.new
  fx.main
end
