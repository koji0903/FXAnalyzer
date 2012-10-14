# -*- coding: utf-8 -*-
#############################################
#
#  FXBase
#
#############################################
module FXBase
  def get_FXBase
    # DB path
    if RUBY_PLATFORM == "i386-mingw32"
      db_dir = "../../../../FX_DB"
    else
#      db_dir = "/home/koji/FX/FX_DB"
      db_dir = "/home/koji/workspace/FXAnalyzer/db"
    end

    # Historical Data ["CSVFileName","PHPSelectNumber","DBFileName"]
    db_list = {
      "USD/JPY" => ["usdjpy.csv",1, "fx_usdjpy.db","USDJPY.csv"],
      "EUR/JPY" => ["eurjpy.csv",2, "fx_eurjpy.db","EURJPY.csv"],
      "EUR/USD" => ["eurusd.csv",3, "fx_eurusd.db","EURUSD.csv"],
      "AUD/JPY" => ["audjpy.csv",4, "fx_audjpy.db","AUDJPY.csv"],
      "AUD/USD" => ["audusd.csv",10,"fx_audusd.db","AUDUSD.csv"],
      "NZD/JPY" => ["nzdjpy.csv",5, "fx_nzdjpy.db","NZDJPY.csv"],
      "NZD/USD" => ["nzdusd.csv",11,"fx_nadusd.db","NZDUSD.csv"],
      "CAD/JPY" => ["cadjpy.csv",9, "fx_cadjpy.db","CADJPY.csv"],
      "GBP/JPY" => ["gbpjpy.csv",6, "fx_gbpjpy.db","GBPJPY.csv"],
      "HKD/JPY" => ["hkdjpy.csv",7, "fx_hkdjpy.db","HKDJPY.csv"],
      "ZAR/JPY" => ["zarjpy.csv",8, "fx_zarjpy.db","ZARJPY.csv"],
    }
    return db_dir,db_list

  end

  # TurningValue : Trade(Short/Long)が変わる値
  # ResistanceValue : 抵抗値
  # EMA12 : [5]
  # EMA26 : [6]
  # MACD  : [7]
  # SIGNAL : [8]
  def get_HistoricalSQL
    historical_sql = <<SQL
      create table historical (
                               Date TEXT UNIQUE NOT NULL,
                               StartValue REAL NOT NULL,
                               HighestValue RRAL  NOT NULL,
                               LowestValue REAL NOT NULL ,
                               EndValue REAL  NOT NULL,
                               ema12 INTEGER,
                               ema26 INTEGER,
                               macd  INTEGER,
                               signal INTEGER,
                               judge INTEGER,
                               Trade TEXT,
                               TurningValue REAL,
                               Differ REAL,
                               ResistanceValue INTEGER,
                               ChartFlag INTEGER
                               );
SQL
    return historical_sql 
  end

  def get_ChartSQL
    chart_sql = <<SQL
      create table chart (
                               Date TEXT UNIQUE NOT NULL,
                               StartValue REAL NOT NULL,
                               HighestValue RRAL  NOT NULL,
                               LowestValue REAL NOT NULL ,
                               EndValue REAL  NOT NULL,
                               );
SQL
    return chart_sql 
  end

  module_function :get_FXBase
  module_function :get_HistoricalSQL
  module_function :get_ChartSQL
end
