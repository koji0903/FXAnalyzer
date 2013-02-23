require 'rubygems'
require 'gruff'

class MyGraph
  def initialize(inf)
    # Output PNG file name
    @out_file = inf[:result_dir] + "/img/" + inf[:file]
    # The title of Graph
    @Title = inf[:title]
    
    @Data = inf[:data] # Expect Hash data (category => data(array))
    @Label = inf[:label]

    @g = Gruff::Line.new('1280x960')
#    @g = Gruff::Line.new
    @g.title = "#{@Title}" 
    
     # Graph Setting
    case @Title
    when "AUD/USD","EUR/USD","NZD/USD"
 #     @g.y_axis_increment = 0.1
    else
#      @g.y_axis_increment = 1
    end
    @g.x_axis_label = "Date"
    @g.y_axis_label = "Value"
#    @g.theme_37signals

#  --- Change Max / Min Value
#  @g.maximum_value = 100
#  @g.minimum_value = 50
@g.marker_count = 2
  @g.hide_legend = false
  @g.marker_font_size = 10
  @g.legend_font_size = 8
  @g.title_font_size = 12
  @g.hide_dots = true
 
  end
  
  def add_data
    @Data.each do |category,each_data|
      @g.data("#{category}",each_data)
    end
  end
  
  def add_title
    @g.labels = @Label
  end
  
  def generate
    printf("@I:generate %s\n",@out_file)
    begin
#      @g.write(@out_file)
#      p @out_file
      @g.write(@out_file)
#      p "Success\n"
     rescue => ex
       p ex.message
       p @out_file
 #      p @g
       p "@internal error."
       exit
     end
  end
end


