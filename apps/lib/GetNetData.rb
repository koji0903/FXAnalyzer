#!/usr/local/bin/ruby
####################################################
#
# get FX-Data From internet
#
# Usage
#   param  : base_url    - Base HTTP URL
#            path        - Page path
#            message=on  - Print Message select
#   return : Network data
#
####################################################
require 'nkf'

require 'net/http'
require 'open-uri'
Net::HTTP.version_1_2

class GetNetData
  def initialize(domain,path,message="on")
    @domain = domain
    @path = path
    @message = message
  end
  # get file from Internet
=begin
  def get_historical
    Net::HTTP.start(@domain) do |http|
      response = http.post(@path,@php_path)
      if @message == "on"
        printf " get HtmlData from #{@domain}/#{@path}\n"
        printf " - net-respone:#{response.message}\n"
      end
      p response.body
      exit
      return  response.body      
    end
  end
=end
  def get_historical
    print "get HtmlData from #{@domain}/#{@path}\n"
    file_data = Array.new
    begin
      open("http://#{@domain}/#{@path}").each{|f|
        file_data << f
      }
    rescue
      printf "@E:Cannot Get Historical Data.Please check following URL to access.\n"
      printf " http://#{@domain}/#{@path}\n"
      exit 1
    end
    file_data
  end

  def get_economic
    print "get HtmlData from #{@domain}/#{@path}\n"
    file_data = Array.new
    open("http://#{@domain}/#{@path}").each{|f|
#      file_data << NKF.nkf('-w',f) # change-code to "UTF-8"
      file_data << f
    }
    file_data
  end
end

if __FILE__ == $0 
  a = GetNetData.new("www.m2j.co.jp","/market/histry_dl.php?ccy=1","../data/usdjpy.csv")
  a.main
end
