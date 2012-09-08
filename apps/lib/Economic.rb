# -*- coding: utf-8 -*-
##########################################
# 
# Historical
#  - Get Economical HTML Data from Internet
#  - Make Economic Database
#
##########################################
$:.concat(["#{File.dirname(__FILE__)}/../lib"])
require 'common'
require 'GetEconomicalData'
require 'sqlite3'
require 'rubygems'

class EcoData
  attr_accessor :Date
  attr_accessor :Time
  attr_accessor :Sentence
  attr_accessor :Country
  attr_accessor :Item           # 発表項目
  attr_accessor :Attr           # 補足内容(ex:前月比)
  attr_accessor :PreviousValue  # 前回数値
  attr_accessor :Compare        # 比較値
  attr_accessor :Expectation    # 期待値
  attr_accessor :Result         # 結果
  attr_accessor :Point          # 結果/期待値
  attr_accessor :Type           # タイプ(ex:Rate/People)
  def initialize
    @Date = nil
    @Time = nil
    @Sentence = nil
    @Country = nil
    @Item = nil
    @Attr = nil
    @PreviousValue = nil
    @Compare = nil
    @Expectation = nil
    @Result = nil
    @Point = nil
    @Type = nil
  end
  def clear
    @Time = nil
    @Sentence = nil
    @Country = nil
    @Item = nil
    @Attr = nil
    @PreviousValue = nil
    @Compare = nil
    @Expectation = nil
    @Result = nil
    @Point = nil
    @Type = nil
  end
end

class Economic
  def initialize(db_dir,db_list,tmp_dir="/home/koji/tmp")
    @db_dir = db_dir
    @economic = db_list
    @tmp_dir = tmp_dir
    @eco_data = EcoData.new
    @sentence = nil
    @economic_sql = <<SQL
create table economic (
  Date TEXT,
  Time TEXT,
  Sentence TEXT UNIQUE NOT NULL,
  Country TEXT,
  Item TEXT,
  Attr TEXT,
  PreviousValue REAL,
  Compare REAL,
  Expectation REAL,
  Result REAL NOT NULL,
  Point REAL,
  Type TEXT
);
SQL
    
  end
  
  def make_EconomicDB(saved_FileName)
    db_name = "fx_economic.db" # db_name
    printf "Open DataBase #{@db_dir}/#{db_name}\n"
    db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
    begin
      db.execute(@economic_sql)
    rescue
      printf "#{@db_dir}/#{db_name} is already exist.\n"
    end

    # read each Economic
    saved_FileName.each{|html|
      enable_flag = false
      date = nil
      calender = html.split("/").last.sub(".html","").split("_").last # "Year-Month"
      i = 0 # 0:"Time", 1:"発表/前回数値", 2:"予想", 3:"結果"
#      printf "analyze #{html}\n"
      open("#{html}").each{|line|
        line = NKF.nkf('-w',line).strip # change char-code to "UTF-8"
        line = line.sub("確定","")
        #-- ignore line
        if /<\/tr>/ =~ line; enable_flag = false; end
        #-- enable line 
        if enable_flag 
          if /^<th.*a>(.*)\(.*\)<\/th>/ =~ line # date line
            date = $1.to_i
            i = 0
          elsif /^<td\s*>(.*)<\/td>/ =~ line 
            i = get_eachItem($1,calender,date,i,db)
          end
        end
        #-- set enable folowing line
        if /<tr><!-- key / =~ line; enable_flag = true; end
      }
    }

    db.close
  end

  def get_eachItem(str,calender,date,i,db)
    @eco_data.Date = calender + "-" + Common.num_trans(date)
    case i
    when 0
      @eco_data.Time = str.strip
      i += 1
    when 1
      @sentence = str if str != "" 
      str = str.sub("速報値","").gsub("速報","").gsub("暫定","").gsub("確報値","").gsub("確定値","").gsub("値","")
      str, previous_value = get_PreviousValue(str)
      str, compare = get_Compare(str)
      str, country = get_Country(str)
      item, attr    = get_Item(str)
      @eco_data.Country = country.strip unless country.nil?
      @eco_data.Item = item.strip unless item.nil?
      @eco_data.Attr = attr.strip unless attr.nil?
      @eco_data.PreviousValue = get_value(previous_value)[0].to_i
      @eco_data.Compare = get_month(compare,calender,attr).to_i
      i += 1
    when 2
      @eco_data.Expectation = get_value(str)[0].to_f
      i += 1
    when 3
      if get_value(str)[0] == ""
        @eco_data.Result = nil
      else
        @eco_data.Result = get_value(str)[0].to_f
      end
      @eco_data.Point  = get_Point(@eco_data)
      @eco_data.Type   = get_value(str)[1].strip unless get_value(str)[1].nil?
      i = 0
      # save data to DB
      @eco_data.Sentence = @eco_data.Date + ":" + @sentence + " -- " + @eco_data.Result.to_s
      save_data(db,@eco_data)
      @eco_data.clear
      @sentence = nil
    end
    return i
  end

  #
  # save data to DB
  #
  def save_data(db,eco_data)
    return if eco_data.Result.nil? || eco_data.Result == ""
    case eco_data.Country
    when "日","豪","米","EU","英","独","NZ","加","香港","南ア","中"
    else
      return nil
    end
    begin
      sql = "insert into economic values ('#{eco_data.Date}',
                                          '#{eco_data.Time}',
                                          '#{eco_data.Sentence}',
                                          '#{eco_data.Country}',
                                          '#{eco_data.Item}',
                                          '#{eco_data.Attr}',
                                           #{eco_data.PreviousValue},
                                           #{eco_data.Compare},
                                           #{eco_data.Expectation},
                                           #{eco_data.Result},
                                           #{eco_data.Point},
                                          '#{eco_data.Type}'
                                           )"
      db.execute(sql)
      printf("\tAdd Economic data at (%s)\n",eco_data.Sentence)
    rescue
      # Skip.Already Saved.
    end
  end

  #
  # get Point
  #
  def get_Point(eco_data)
    exp = eco_data.Expectation
    result = eco_data.Result
    point = 0
    if !exp.nil? && !result.nil?
      if  exp == 0 || result == 0
        point = 0
      elsif exp < 0 && result < 0
        point = exp.to_f/result.to_f
      elsif exp > 0 && result < 0
        tmp = exp - result
        point = exp.to_f/tmp.to_f
      elsif exp < 0 && result > 0
        tmp = result - exp
        exp = 0 - exp
        point = tmp.to_f/exp.to_f
      else          
        point = result.to_f/exp.to_f 
      end
    end
    return point
  end

  #
  # Get Country
  #
  def get_Country(str)
    return "","" if str.nil?
    country = str.split[0]
    str = str.sub("#{str.split[0]}","")
    return str, country
  end

  #
  # Get Month
  #
  def get_month(str,calender,attr)
    return "" if str.nil?
    year = calender.split("-")[0].to_i
    month  = calender.split("-")[1].to_i
    if month > str.strip.sub("月","").to_i
      if attr == "前年比"
        return (year-1).to_s + "-" + Common.num_trans(str.to_s.strip.sub("月",""))
      else
        return year.to_s + "-" + Common.num_trans(str.to_s.strip.sub("月",""))
      end
    else
      if attr == "前年比"
        return (year-2).to_s + "-" + Common.num_trans(str.to_s.strip.sub("月",""))
      else
        return (year-1).to_s + "-" + Common.num_trans(str.to_s.strip.sub("月",""))
      end
    end
  end

  #
  # Get Previsou Value if Exist
  #   ret : Other string, previous_value
  #
  def get_PreviousValue(str)
    if /\[(\S*)\]$/ =~ str
      return $`, $1.to_s
    elsif /［(\S*)\]$/ =~ str
      return $`, $1.to_s
    elsif /\[(\S*)］$/ =~ str
      return $`, $1.to_s
    elsif /［(\S*)］$/ =~ str
      return $`, $1.to_s
    end
    return str
  end

  #
  # Get Compare-Point
  #   ret : Other strings, Compare point
  #
  def get_Compare(str)
    if /\((\d*\S*)\)$/ =~ str
      return $`, $1.to_s
    elsif /（(\S*)）（(\d*\S*)）$/ =~ str
      return $`, $2.to_s
    elsif /（(\d*\S*)\)$/ =~ str
      return $`, $1.to_s
    elsif /\((\d*\S*)）$/ =~ str
      return $`, $1.to_s
    elsif /（(\d*\S*)）$/ =~ str
      return $`, $1.to_s
    end
    if /(第.*半期)/ =~ str
      tmp = $1
      return str.gsub("#{tmp}",""), tmp.to_s
    end
    return str
  end

  #
  # Get Item
  #  ret : item, attr
  def get_Item(str)
    item = ""
    attr = ""
    if !str.nil?
      tmp = str.split
      item = tmp[0]
      if tmp.size >= 2
        attr = tmp.last
      else
        if /.*前年比/ =~ str
          attr = "前年比"
        elsif /.*前月比/ =~ str
          attr = "前月比"
        elsif /.*前期比/ =~ str
          attr = "前期比"
        end
        item = str
      end
    end
    item = item.gsub("前年比","")
    item = item.gsub("前月比","")
    item = item.gsub("前期比","")
    item = item.strip
    return item,attr
  end

  def get_value(str)
    if str.nil?
      return nil,nil
    end
    str = str.to_s.strip
    str = str.sub(/\(.*/,"")
    type = ""
    minus = ""
    if /^.*赤字/ =~ str
      minus = "-"
    elsif /^-.*/ =~ str
      minus = "-"
      str = str.sub("-","")
    end

    if /^(.*)%/ =~ str
      str = $1.to_s
      type = "rate"
    elsif /^(.*)万件/ =~ str
      num = $1.to_i * 10000
      str = num.to_s
      type = "particular"
    elsif /^(.*)万(.*)人/ =~ str
      num1 = $1.to_i * 10000
      num2 = $2.to_i unless $2.to_s.nil?
      str = (num1.to_i + num2.to_i).to_s
      type = "people"
    elsif /^(.*)万(.*)件/ =~ str
      num1 = $1.to_i * 10000
      num2 = $2.to_i unless $2.to_s.nil?
      str = (num1.to_i + num2.to_i).to_s
      type = "particular"
    elsif /^(.*)億(.*)万/ =~ str
      num1 = $1.to_i * 100000000
      num2 = $2.to_i * 10000 unless $2.to_s.nil?
      str = (num1.to_i + num2.to_i).to_s
      type = "value"
    elsif /^(.*)億/ =~ str
      num1 = $1.to_i * 100000000
      str = num1.to_i.to_s
      type = "value"
    elsif /^(.*)万(.*)戸/ =~ str
      num1 = $1.to_i * 10000
      num2 = $2.to_i unless $2.to_s.nil?
      str = (num1.to_i + num2.to_i).to_s
      type = "particular"
    elsif /^(.*)万/ =~ str
      num1 = $1.to_i * 10000
      str = (num1.to_i + num2.to_i).to_s
      type = "particular"
    else
      type = "direct"
    end
    if str == "---"
      return nil,type
    else
      return minus + str,type
    end
  end

  def main
    # Get Economic HTML Data from Internet
    printf "@I:Get Economic Data and save #{@tmp_dir}\n"
    saved_FileName =GetEconomicalData.new(@economic,@tmp_dir).main
    # Make DataBase and Save
    make_EconomicDB(saved_FileName)
  end

end
