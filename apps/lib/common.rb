require "find"
require "fileutils"
require 'nkf'
require 'pp'
require 'net/http'
require 'open-uri'
Net::HTTP.version_1_2

$TOOL            = "FXAnalyzer"
$VERSION         = "1.0.0"
$VERBOSE         = false   # Verbose Mode
$ERROR_CNT       = 0       # Error Count for tool summary
$WARNING_CNT     = 0       # Warning Count for tool summary
$NOTE_CNT        = 0       # Note Count for tool summary
$INTERNAL_ERROR_CNT = 0

module Common

  #
  # initialize
  #
  def initialize
  end

  def Common.print_base
    printf("%s ver:%s",$TOOL,$VERSION)
=begin
    revision,branch = get_revision($0)
    if /trunk/ =~ $VERSION && revision != nil
      printf(" [ %s -  Commit Hash : %s ]\n",branch,revision)
    else
      printf("\n")
    end
=end
    printf("Copyright (c) 2013 KHSoft. All rights reserved.\n")
    # Get Start Time
    $StartTime = Time.now 
    printf("  - Started Time : %s\n\n",$StartTime)
  end


  def Common.print_summary
    printf("\n")
    printf("Execution Result\n")
    printf("   Note     : %4d\n", $NOTE_CNT)
    printf("   Warning  : %4d\n", $WARNING_CNT)
    printf("   Error    : %4d\n", $ERROR_CNT)
    printf("\n")
    printf("   Internal Error    : %4d\n", $INTERNAL_ERROR_CNT)
    printf("\n")
    if $ERROR_CNT == 0 && $INTERNAL_ERROR_CNT == 0
      printf("%s has successfully finished.\n\n\n",$TOOL)
    else
      printf("%s finished with Errors. please check error message.\n\n\n",$TOOL)
    end
    # Get End Time
    $EndTime = Time.now
    if $StartTime != nil && $EndTime != nil
      days = ($EndTime - $StartTime).divmod(24*60*60)
      hours = days[1].divmod(60*60) 
      mins = hours[1].divmod(60)
      

      print <<EOB
Process took #{hours[0].to_i} hours #{mins[0].to_i} minutes #{mins[1].to_i} seconds
 ( Start Time : #{$StartTime}, End Time : #{$EndTime} )


EOB

    end
  end
end
