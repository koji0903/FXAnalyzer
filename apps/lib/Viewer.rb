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
require 'spreadsheet'
#require 'Graph'

class Viewer

  def initialize(result_dir,db_dir,db_list)
    @result_dir = result_dir
    @db_dir = db_dir
    @db_list = db_list
  end

  private
  def getLast30DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 30;")
  end

  private
  def getLast100DaysData(db,table)
    return db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 300;")
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
  def getCSV(f,db,table,num)
    f.printf "Date,Start Value,diff,Highest Value,diff,Lowest Value,diff,End Value,diff,EMA12,diff,EMA26,diff,MACD,diff,Signal,diff,Judge,diff,Trade,Turning Value,Resistance Value,Chart Flag,\n"
    db.execute("SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT 100;").sort_by{|row|
      row[0]
    }.each{|row|
      row.each{|column|
        if column.class == Float
          f.printf "%.#{num}f,",column
        else
          f.printf "#{column},"
        end
      }
      f.printf "\n"
    }
  end

  private
  def make_excel(file,db,table,num,length)
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet( :name => table )

    # Color Gray
    cell_green = set_cell(sheet,:green,:thin)
    cell_magenta = set_cell(sheet,:magenta,:thin)
    cell_cyan = set_cell(sheet,:cyan,:thin)
    cell_white = set_cell(sheet,:white,:thin)
    cell_pure_white = set_cell(sheet,:white)

    # Header
    sheet[0,0] = "Date"
    sheet[0,1] = "Start Value"
    sheet[0,2] = "Highest Value"
    sheet[0,3] = "Lowest Value"
    sheet[0,4] = "End Value"
    sheet[0,5] = "EMA12"
    sheet[0,6] = "EMA26"
    sheet[0,7] = "MACD"
    sheet[0,8] = "Signal"
    sheet[0,9] = "Judge"
    sheet[0,10] = "Trade"
    sheet[0,11] = "Turning Value"
    sheet[0,12] = "Differ"
    sheet[0,13] = "Registance"
    for i in 0..13
      sheet.row(0).set_format(i, cell_green)
      sheet.column(i).width = sheet[0,i].to_s.size
    end

    if length.nil?
      sql = "SELECT * FROM #{table};"
    else
      sql = "SELECT * FROM #{table} ORDER BY ROWID DESC LIMIT #{length};"
    end
    db.execute("#{sql}").sort_by{|row|
      row[0]
    }.each_with_index{|row,j|
      row.each_with_index{|column,i|
        if column.class == Float
          column = column.round(num)
        end
        case i          
        when 0 # Date
          row_index = j+1
          column_index = i
          sheet[j+1,column_index] = column
          set_data_width(sheet,row_index,column_index,column,cell_white)
        when 1,3,5,7,9,11,13,15,17,20,22
          # Start Value
          # Highest Value
          # Lowest Value
          row_index = j+1
          column_index = i/2+1
          sheet[j+1,column_index] = column
          if row[i+1] > 0
            set_data_width(sheet,row_index,column_index,column,cell_cyan)
          else
            set_data_width(sheet,row_index,column_index,column,cell_magenta)
          end
        when 19
          row_index = j+1
          column_index = i/2+1
          sheet[j+1,column_index] = column
          if column == "Long"
            set_data_width(sheet,row_index,column_index,column,cell_cyan)
          else
            set_data_width(sheet,row_index,column_index,column,cell_magenta)
          end
        when 24
          # Registance Value
          row_index = j+1
          column_index = i/2+1
          sheet[j+1,column_index] = column
          if column.to_i == 0
            set_data_width(sheet,row_index,column_index,column,cell_white)
          else
            set_data_width(sheet,row_index,column_index,column,cell_green)
          end
        else
        end
      }
    }
    book.write(file)
  end

  def set_data_width(sheet,row_index,column_index,column,collor)
    sheet.row(row_index).set_format(column_index, collor)
    if sheet.column(column_index).width < column.to_s.size
      sheet.column(column_index).width = column.to_s.size
    end
  end

  def getCSV_all(f,db,table,num)
    f.printf "Date,Start Value,diff,Highest Value,diff,Lowest Value,diff,End Value,diff,EMA12,diff,EMA26,diff,MACD,diff,Signal,diff,Judge,diff,Trade,Turning Value,Resistance Value,Chart Flag,\n"
    db.execute("SELECT * FROM #{table}").sort_by{|row|
      row[0]
    }.each{|row|
      row.each{|column|
        if column.class == Float
          f.printf "%.#{num}f,",column
        else
          f.printf "#{column},"
        end
      }
      f.printf "\n"
    }
  end

  
  def view(f,category,data)
    f.printf("====[%s]====\n",category)
    data.sort_by{|each_data|
      each_data[0]
    }.each{|each_data|
      case each_data[18]
      when "Long"
        judge = "買"
      when "Short"
        judge = "売"
      end
      case category
      when "EUR/USD", "AUD/USD", "NZD/USD"
        f.printf("[%s]判定:%s[終値:%.4f%s(高値:%.4f%s,安値:%.4f%s), EMA12:%.4f%s,EMA26:%.4f%s,MACD:%.4f%s,SIGNAL:%.4f%s,分析値:%.2f%s, 変化値:%.4f%s(差:%.4f%s)]\n",
                 each_data[0], # category
                 judge,          
                 each_data[7], # end value
                 direction(each_data[8]),
                 each_data[3], # Highest Value
                 direction(each_data[4]),
                 each_data[5], # Lowest value
                 direction(each_data[6]),
                 each_data[9], # ema12
                 direction(each_data[10]),
                 each_data[11], # ema26
                 direction(each_data[12]),
                 each_data[13], # macd
                 direction(each_data[14]),
                 each_data[15], # signal
                 direction(each_data[16]),
                 each_data[17]*100, # judge
                 direction(each_data[18]),
                 each_data[20],
                 direction(each_data[21]),
                 (each_data[7]-each_data[20]).abs,
                 direction(each_data[23])
                 )
      else
        f.printf("[%s]判定:%s[終値:%.2f%s(高値:%.4f%s,安値:%.4f%s), EMA12:%.4f%s,EMA26:%.4f%s,MACD:%.4f%s,SIGNAL:%.4f%s,分析値:%.2f%s, 変化値:%.2f%s(差:%.2f%s)]\n",
                 each_data[0], # category
                 judge,          
                 each_data[7], # end value
                 direction(each_data[8]),
                 each_data[3], # Highest Value
                 direction(each_data[4]),
                 each_data[5], # Lowest value
                 direction(each_data[6]),
                 each_data[9], # ema12
                 direction(each_data[10]),
                 each_data[11], # ema26
                 direction(each_data[12]),
                 each_data[13], # macd
                 direction(each_data[14]),
                 each_data[15], # signal
                 direction(each_data[16]),
                 each_data[17],
                 direction(each_data[18]),
                 each_data[20],
                 direction(each_data[21]),
                 (each_data[7]-each_data[20]).abs,
                 direction(each_data[23])
                 )
      end
    }
    f.printf "\n"
  end

  #
  public
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
  # Genrete Excel File (Last 100days and All days)
  #
  def generate_Excel
    @db_list.each{|category,value|
#      f = open(file,"w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      case db_name
      when /eurusd/, /audusd/,/nzdusd/
        num = 6
      else
        num = 4
      end
#      getCSV(f,db,table,num)
      file = "#{@result_dir}/#{value[0]}"
      printf("@I:generate %s\n",file)
      make_excel(file,db,table,num,100)
      file = "#{@result_dir}/ALL_#{value[0]}"
      printf("@I:generate %s\n",file)
      make_excel(file,db,table,num,nil)
      
#      f.close
    }
=begin
    # All days CSV
    @db_list.each{|category,value|
      file = "#{@result_dir}/ALL_#{value[0]}"
      printf("@I:generate %s\n",file)
      f = open(file,"w")
      db_name = value[2]
      table = "historical"
      db = SQLite3::Database.new("#{@db_dir}/#{db_name}")
      case db_name
      when /eurusd/, /audusd/,/nzdusd/
        num = 6
      else
        num = 4
      end
      getCSV_all(f,db,table,num)
      make_excel(file,db,table,num,nil)
      f.close
    }
=end
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
      data = getLast100DaysData(db,"historical")
       make_EMA_long(data,category,value)

    end
  end
  
  def direction(num)
    if num >= 0
      return "↑"
    else
      return "↓"
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
        end_value << ('%.4f' % each_data[7]).to_f
        high_value << ('%.4f' % each_data[3]).to_f
        low_value << ('%.4f' % each_data[5]).to_f
        ema12_value << ('%.4f' % each_data[9]).to_f
        ema26_value << ('%.4f' % each_data[11]).to_f
#p  each_data[11]
#p '%.4f' % each_data[11]
#exit
        change_value << ('%.4f' % each_data[20]).to_f
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
      graph = MyGraph.new( :result_dir => @reuslt_dir,
                           :file => out_file,
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
        end_value << ('%.4f' % each_data[7]).to_f
        high_value << ('%.4f' % each_data[3]).to_f
        low_value << ('%.4f' % each_data[5]).to_f
        ema12_value << ('%.4f' % each_data[9]).to_f
        ema26_value << ('%.4f' % each_data[11]).to_f
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
      graph = MyGraph.new( :result_dir => @result_dir,
                           :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value
                              )
    
      graph.add_data
      graph.add_title
      graph.generate
  end

  def make_EMA_long(data,category,value)
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
        end_value << ('%.4f' % each_data[7]).to_f
        high_value << ('%.4f' % each_data[3]).to_f
        low_value << ('%.4f' % each_data[5]).to_f
        ema12_value << ('%.4f' % each_data[9]).to_f
        ema26_value << ('%.4f' % each_data[11]).to_f
        if i%5 == 4
           data_value[i] = each_data[0] 
        end
        i += 1
      end
      
      out_file = value[0].sub(".csv","_EMA_long.png")
      gruff_data = Hash.new
      gruff_data["End Value"] = end_value
      gruff_data["High Value"] = high_value
      gruff_data["Low Value"] = low_value
      gruff_data["EMA12"] = ema12_value
      gruff_data["EMA26"] = ema26_value

       # Make Graph
      graph = MyGraph.new( :result_dir => @result_dir, 
                           :file => out_file,
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
        macd_value << ('%.4f' % each_data[13]).to_f
        signal_value << ('%.4f' % each_data[15]).to_f
        analyze_value << ('%.4f' % each_data[17]*100).to_f
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
    graph = MyGraph.new( :result_dir => @result_dir,
                           :file => out_file,
                           :title => category,
                           :data => gruff_data,
                           :label => data_value,
                              )
      graph.add_data
      graph.add_title
      graph.generate
  end

  def set_cell(sheet,color,border=nil)
    default_format = sheet.default_format
    cell = default_format.clone
    cell.pattern = 1
    cell.pattern_fg_color = color
    cell.border_color = :black
    cell.border = border unless border.nil?
    return cell
  end

  public
  def main
    printf "@I:Analyze Historical Data\n"
    printf "@I:Generate Historical Data to TXT\n"
    generate_TechnicalData
    printf "@I:Generate Histrrical Data to CSV\n"
    generate_CSV
    printf "@I:Generate Analyzed Data to CSV\n"
    generate_Trade
    printf "@I:Generate Graph\n"
    generate_Graph
  end
end
