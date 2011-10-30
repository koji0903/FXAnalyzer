# -*- coding: utf-8 -*-
module Common
  def Common.make_dir_with_delete(dir)
    Common.delete_dir(dir)
    Dir::mkdir("#{dir}")
  end

  def Common.delete_dir(delete_dir)
    # サブディレクトリを階層が深い順にソートした配列を作成
    dirlist = Dir::glob(delete_dir + "**/").sort {
      |a,b| b.split('/').size <=> a.split('/').size
    }
    
    # サブディレクトリ配下の全ファイルを削除後、サブディレクトリを削除
    dirlist.each {|d|
      Dir::foreach(d) {|f|
        File::delete(d+f) if ! (/\.+$/ =~ f)
      }
      Dir::rmdir(d)
    }    
  end

  #
  # Change month charactor to 2-charctor month(String)
  #
  def Common.num_trans(num)
    case num.to_i
    when 1; return "01"
    when 2; return "02"
    when 3; return "03"
    when 4; return "04"
    when 5; return "05"
    when 6; return "06"
    when 7; return "07"
    when 8; return "08"
    when 9; return "09"
    else return "#{num}"
    end
  end

end
