require 'json'
require 'typhoeus'


def determine_ok_nok(ok,nok,corridor = 0)
  return (ok - nok).abs() <= corridor ? 0 : ((ok > nok) ? 1 : -1)
end

ninety_deg_usage_1 = [5,3,6,4,4,1,0,2,9,10,10,0,0,1,1,3,1]
ninety_deg_usage_2 = [9,7,7,10,7,3,8,5,9,9,10,2,7,0,1,1,2]
shortest_distance_usage_1 = [8,3,3,3,3,1,1,1,3,1,5,9,0,0,1,2,0,4]
shortest_distance_usage_2 = [8,7,7,7,8,2,1,5,5,8,9,9,4,6,0,0,2,0]
same_timestamp_usage_1 = [7,8,9,10,5,8,9,8,10,9,9,8,4,1,2,0,1]
same_timestamp_usage_2 = [10,9,9,9,8,8,8,7,10,7,8,8,7,5,1,0,0]

ninety_deg_usage = nil 
shortest_distance_usage = nil
same_timestamp_usage = nil
if(ARGV[0] == '1') then
  ninety_deg_usage = ninety_deg_usage_1
  shortest_distance_usage = shortest_distance_usage_1
  same_timestamp_usage = same_timestamp_usage_1
elsif(ARGV[0] == '2')
  ninety_deg_usage = ninety_deg_usage_2
  shortest_distance_usage = shortest_distance_usage_2
  same_timestamp_usage = same_timestamp_usage_2
end


x = File.read(File.join(__dir__,"test_img/analysis/points.json"))
initial_obj = JSON.parse(x)
analysed_things = ["difference_ok_nok_90-degrees-method", "difference_ok_nok_shortest-distance-method", "difference_ok_nok_same-timestamp-method"]

analysed_things.each() do |analysed_thing| 
  obj = initial_obj[analysed_thing]
  overall_results = {'90-degrees-method' => {:correct => 0, :undecidable => 0, :incorrect => 0}, 'shortest-distance-method' => {:correct => 0, :undecidable => 0, :incorrect => 0}, 'same-timestamp-method' => {:correct => 0, :undecidable => 0, :incorrect => 0}}
  
  poi = (obj['poi'] + obj['peaks']).uniq()
  poi.sort!()
  poi.select!().with_index() do |p,index|
    ret = false
    if(analysed_thing.include?('90-degrees')) then
      ret = ninety_deg_usage[index] >= 5
    elsif(analysed_thing.include?('shortest-distance'))
      ret = shortest_distance_usage[index] >= 5
    elsif(analysed_thing.include?('same-timestamp'))
      ret = same_timestamp_usage[index] >= 5
    end
    ret
  end
  obj['traces'].each do |k,v|
    trace_uuid = k.split(':').first()
    trace_outcome = k.split(':').last()
  
    new_window = true
    overall = {'90-degrees-method' => {:ok => 0, :nok => 0, :undecidable => 0}, 'shortest-distance-method' => {:ok => 0, :nok => 0, :undecidable => 0}, 'same-timestamp-method' => {:ok => 0, :nok => 0, :undecidable => 0}}
    poi.each() do |e|
      request = Typhoeus.get("http://localhost:8050/#{trace_uuid}/#{e.round(1)}/json")
      if(request.success?()) then
        result = JSON.parse(request.response_body())
        dist_to_ok = result['data']['90-degrees-method']['lengths in mm']['trace + ats ok']
        dist_to_nok = result['data']['90-degrees-method']['lengths in mm']['trace + ats nok']
        dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? overall['90-degrees-method'][:undecidable]+=1 : overall['90-degrees-method'][:ok]+=1) : overall['90-degrees-method'][:nok]+=1
        
        dist_to_ok = result['data']['shortest-distance-method']['lengths in mm']['trace + ats ok']
        dist_to_nok = result['data']['shortest-distance-method']['lengths in mm']['trace + ats nok']
        dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? overall['shortest-distance-method'][:undecidable]+=1 : overall['shortest-distance-method'][:ok]+=1) : overall['shortest-distance-method'][:nok]+=1
        
        dist_to_ok = result['data']['same-timestamp-method']['lengths in mm']['trace + ats ok']
        dist_to_nok = result['data']['same-timestamp-method']['lengths in mm']['trace + ats nok']
        dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? overall['same-timestamp-method'][:undecidable]+=1 : overall['same-timestamp-method'][:ok]+=1) : overall['same-timestamp-method'][:nok]+=1
      else
        #p "    #{e.round(1)} probably out of bounds"
      end
    end
    corridor = 0
    compare = trace_outcome == 'ok' ? 1 : -1
    (overall['90-degrees-method'][:ok] - overall['90-degrees-method'][:nok]).abs() <= corridor ? overall_results['90-degrees-method'][:undecidable] += 1 : (compare == (overall['90-degrees-method'][:ok] <=> overall['90-degrees-method'][:nok]) ? overall_results['90-degrees-method'][:correct] += 1 : overall_results['90-degrees-method'][:incorrect] += 1)
    (overall['shortest-distance-method'][:ok] - overall['shortest-distance-method'][:nok]).abs() <= corridor ? overall_results['shortest-distance-method'][:undecidable] += 1 : (compare == (overall['shortest-distance-method'][:ok] <=> overall['shortest-distance-method'][:nok]) ? overall_results['shortest-distance-method'][:correct] += 1 : overall_results['shortest-distance-method'][:incorrect] += 1)
    (overall['same-timestamp-method'][:ok] - overall['same-timestamp-method'][:nok]).abs() <= corridor ? overall_results['same-timestamp-method'][:undecidable] += 1 : (compare == (overall['same-timestamp-method'][:ok] <=> overall['same-timestamp-method'][:nok]) ? overall_results['same-timestamp-method'][:correct] += 1 : overall_results['same-timestamp-method'][:incorrect] += 1)
  end
  puts "#{analysed_thing} (#{poi}) => #{overall_results}"
end
