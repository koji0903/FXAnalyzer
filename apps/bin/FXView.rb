#!/usr/local/bin/ruby -K
# -*- coding: utf-8 -*-
##########################################
# 
# FX Viewer
#
##########################################
$:.concat(["#{File.dirname(__FILE__)}/../lib"])
$:.concat(["#{File.dirname(__FILE__)}/../bin"])
require 'common'
require 'FXBase'
require 'HistoricalViewer'

class FXView
  include FXBase
  def initialize
    @db_dir , @db_list = get_FXBase
  end

  def historical
    historical = HistoricalViewer.new(@db_dir,@db_list)
    historical.main
  end

  def main
    historical
  end
end

if __FILE__ == $0
  view = FXView.new
  view.main
end
