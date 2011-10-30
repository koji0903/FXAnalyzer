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

class GetHistoricalData
  
  def initialize(historical,save_dir="/home/koji/tmp")
    @historical = historical
    @save_dir = save_dir
#    Common.make_dir_with_delete(@save_dir)
  end

  def main
    domain = "www.m2j.co.jp"
    printf "Get Historycal Data from M2J(%s)\n",domain
    @historical.each_value{|value|
#      path = "/market/histry_dl.php?ccy=#{value[1]}"
      path = "market/#{value[3]}"
      save = "#{@save_dir}/#{value[0]}"
      
      f = open("#{save}","w")
      data = Array.new
      data = GetNetData.new("#{domain}","#{path}","on").get_historical
      data.each do |line|
        f.printf line
      end      
      f.close
    }
    printf "Success(see %s/*.csv)\n",@save_dir
  end
end

if __FILE__ == $0
  get_fx_data = GetHistoricalData.new
  get_fx_data.main
end
 
