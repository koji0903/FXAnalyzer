# -*- coding: utf-8 -*-
#############################################
#
#  Setting of FXBase
#
#############################################
class FXBase
  attr_accessor :historical_base_url
  attr_accessor :db_dir
  attr_accessor :data_dir
  attr_accessor :result_dir
  attr_accessor :db_list
  attr_accessor :historical_sql
  def initialize
    @historical_base_url = get_HistoricalURL

    @base_path = File.dirname($0)

    if @base_path == "."
      @base_path = "../"
    end
    
    @db_dir = get_DBDir
    @data_dir = get_DataDir
    @result_dir = get_ResultDir


    # Historical Data ["CSVFileName","PHPSelectNumber","DBFileName"]
    @db_list = {
      "USD/JPY" => ["usdjpy.xls",1, "fx_usdjpy.db","USDJPY.csv"],
      "EUR/JPY" => ["eurjpy.xls",2, "fx_eurjpy.db","EURJPY.csv"],
      "EUR/USD" => ["eurusd.xls",3, "fx_eurusd.db","EURUSD.csv"],
      "AUD/JPY" => ["audjpy.xls",4, "fx_audjpy.db","AUDJPY.csv"],
      "AUD/USD" => ["audusd.xls",10,"fx_audusd.db","AUDUSD.csv"],
      "NZD/JPY" => ["nzdjpy.xls",5, "fx_nzdjpy.db","NZDJPY.csv"],
      "NZD/USD" => ["nzdusd.xls",11,"fx_nadusd.db","NZDUSD.csv"],
      "CAD/JPY" => ["cadjpy.xls",9, "fx_cadjpy.db","CADJPY.csv"],
      "GBP/JPY" => ["gbpjpy.xls",6, "fx_gbpjpy.db","GBPJPY.csv"],
      "HKD/JPY" => ["hkdjpy.xls",7, "fx_hkdjpy.db","HKDJPY.csv"],
      "ZAR/JPY" => ["zarjpy.xls",8, "fx_zarjpy.db","ZARJPY.csv"],
    }

    # TurningValue : Trade(Short/Long)が変わる値
    # ResistanceValue : 抵抗値
    # EMA12 : [5]
    # EMA26 : [6]
    # MACD  : [7]
    # SIGNAL : [8]
    @historical_sql = <<SQL
      create table historical (
                               Date TEXT UNIQUE NOT NULL,
                               StartValue REAL NOT NULL,
                               StartValueDiffer REAL,
                               HighestValue REAL NOT NULL,
                               HighestValueDiffer REAL,
                               LowestValue REAL NOT NULL,
                               LowestValueDiffer REAL,
                               EndValue REAL  NOT NULL,
                               EndValueDiffer REAL,
                               ema12 INTEGER,
                               ema12_direction INTEGER,
                               ema26 INTEGER,
                               ema26_direction INTEGER,
                               macd  INTEGER,
                               macd_direction  INTEGER,
                               signal INTEGER,
                               signal_direction INTEGER,
                               judge INTEGER,
                               judge_directoin INTEGER,
                               Trade TEXT,
                               TurningValue REAL,
                               TurningValue_direction INTEGER,
                               Differ REAL,
                               Differ_direction INTEGER,
                               ResistanceValue INTEGER,
                               ChartFlag INTEGER
                               );
SQL
#                               0 Date TEXT UNIQUE NOT NULL,
#                               1 StartValue REAL NOT NULL,
#                               2 StartValueDiffer REAL,
#                               3 HighestValue REAL NOT NULL,
#                               4 HighestValueDiffer REAL,
#                               5 LowestValue REAL NOT NULL,
#                               6 LowestValueDiffer REAL,
#                               7 EndValue REAL  NOT NULL,
#                               8 EndValueDiffer REAL,
#                               9 ema12 INTEGER,
#                               10 ema12_direction INTEGER,
#                               11 ema26 INTEGER,
#                               12 ema26_direction INTEGER,
#                               13 macd  INTEGER,
#                               14 macd_direction  INTEGER,
#                               15 signal INTEGER,
#                               16 signal_direction INTEGER,
#                               17 judge INTEGER,
#                               18 judge_directoin INTEGER,
#                               19 Trade TEXT,
#                               20 TurningValue REAL,
#                               21 TurningValue_direction REAL,
#                               22 Differ REAL,
#                               23 Differ_direction REAL,
#                               24 ResistanceValue INTEGER,
#                               25 ChartFlag INTEGER

  end

  private
  def get_DBDir
    # Initial Setting of DB path
    return get_Dir("#{@base_path}/../db")
  end
  private
  def get_DataDir
    # Initial Setting of DB path
    return get_Dir("#{@base_path}/../data")
  end
  private
  def get_ResultDir
    # Initial Setting of DB path
    return get_Dir("#{@base_path}/../result")
  end

  def get_Dir(path)
    # Initial Setting of DB path
    dir = path
    # Check direcotory
    unless File::directory?(dir)
      Dir::mkdir(dir)
    end
    # Expand Path
    dir = File::expand_path(dir)
    return dir
  end

  def get_HistoricalURL
#    url = "/market/pchistry_dl.php?ccy=#{num}&type=d"
    url = "http://www.m2j.co.jp/market/pchistry_dl.php?"
    # Access Check
    begin
      open(url+"ccy=1&type=d")
    rescue
      printf "@E:Could not access #{url}\n"
      exit 1
    end
    return url
  end
end

if __FILE__ == $0
  fxbase = FXBase.new
  pp fxbase
end
