require 'json'
require 'typhoeus'

def determine_ok_nok(ok,nok,corridor = 0)
  return (ok - nok).abs() <= corridor ? 0 : ((ok > nok) ? 1 : -1)
end

# ruby open.rb 104fe464-b780-4796-8c7d-9c05b400a259:ok

x = File.read(File.join(__dir__,'test_img','analysis','full_points.json'))
initial_obj = JSON.parse(x)
#obj = obj["difference_ok_nok_90-degrees-method"]
#obj = obj["difference_nok_ok_90-degrees-method"]
analysed_things = ["difference_ok_nok", "difference_ok_nok_90-degrees-method", "difference_ok_nok_shortest-distance-method", "difference_ok_nok_same-timestamp-method", "difference_nok_ok_90-degrees-method", "difference_nok_ok_shortest-distance-method", "difference_nok_ok_same-timestamp-method"]

[analysed_things.first()].each() do |analysed_thing| 
  obj = initial_obj[analysed_thing]
  overall_results = {'90-degrees-method' => {:richtig => 0, :undecidable => 0, :falsch => 0}, 'shortest-distance-method' => {:richtig => 0, :undecidable => 0, :falsch => 0}, 'same-timestamp-method' => {:richtig => 0, :undecidable => 0, :falsch => 0}}
  
  # can be here for general pois used for all traces 
  #poi = (obj['poi'] + obj['peaks']).uniq()
  obj['traces'].each do |k,v|
    # needs to be defined here for individual pois per trace
    poi = (obj['traces'][k]['extremstellen'] + obj['traces'][k]['wendestellen']).uniq()
  
    trace_uuid = k.split(':').first()
    trace_outcome = k.split(':').last()
    #p "#{trace_uuid} - #{trace_outcome}"
  
    new_window = true
    overall = {'90-degrees-method' => {:ok => 0, :nok => 0, :undecidable => 0}, 'shortest-distance-method' => {:ok => 0, :nok => 0, :undecidable => 0}, 'same-timestamp-method' => {:ok => 0, :nok => 0, :undecidable => 0}}
    poi.each() do |e|
      #p "  #{e} -> #{e.round(1)}"
      #systemu("firefox #{new_window ? '--new-window' : '--new-tab'} 'localhost:8050/#{trace_uuid}/#{e.round(1)}'")
      #new_window = false
      #sleep 2
      #request = Typhoeus.get("http://localhost:8050/#{trace_uuid}/#{e.round(1)}/json")
      request = Typhoeus.get("http://localhost:8050/#{trace_uuid}/#{e.round(1)}/json")
      if(request.success?()) then
        result = JSON.parse(request.response_body())
        #p result
        dist_to_ok = result['data']['90-degrees-method']['lengths in mm']['trace + ats ok']
        dist_to_nok = result['data']['90-degrees-method']['lengths in mm']['trace + ats nok']
        dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? overall['90-degrees-method'][:undecidable]+=1 : overall['90-degrees-method'][:ok]+=1) : overall['90-degrees-method'][:nok]+=1
        #p "#{dist_to_ok} - #{dist_to_nok} -> #{dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? '???' : 'ok') : 'nok'}"
        
        dist_to_ok = result['data']['shortest-distance-method']['lengths in mm']['trace + ats ok']
        dist_to_nok = result['data']['shortest-distance-method']['lengths in mm']['trace + ats nok']
        dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? overall['shortest-distance-method'][:undecidable]+=1 : overall['shortest-distance-method'][:ok]+=1) : overall['shortest-distance-method'][:nok]+=1
        #p "#{dist_to_ok} - #{dist_to_nok} -> #{dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? '???' : 'ok') : 'nok'}"
        
        dist_to_ok = result['data']['same-timestamp-method']['lengths in mm']['trace + ats ok']
        dist_to_nok = result['data']['same-timestamp-method']['lengths in mm']['trace + ats nok']
        dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? overall['same-timestamp-method'][:undecidable]+=1 : overall['same-timestamp-method'][:ok]+=1) : overall['same-timestamp-method'][:nok]+=1
        #p "#{dist_to_ok} - #{dist_to_nok} -> #{dist_to_ok.abs() <= dist_to_nok.abs() ? (dist_to_ok.abs() == dist_to_nok.abs() ? '???' : 'ok') : 'nok'}"
      else
        #p "    #{e.round(1)} probably out of bounds"
      end
    end
    corridor = 0
    #corridor = 2
    puts "#{trace_uuid} - #{trace_outcome} - 90-degrees:(#{overall['90-degrees-method'].map() { |k,v| "#{k}:#{v}"}.join('/')}) - shortest-distance:(#{overall['shortest-distance-method'].map() { |k,v| "#{k}:#{v}"}.join('/')}) - same-timestamp:(#{overall['same-timestamp-method'].map() { |k,v| "#{k}:#{v}"}.join('/')}) / #{trace_outcome} -> #{determine_ok_nok(overall['90-degrees-method'][:ok],overall['90-degrees-method'][:nok],corridor)}/#{determine_ok_nok(overall['shortest-distance-method'][:ok],overall['shortest-distance-method'][:nok],corridor)}/#{determine_ok_nok(overall['same-timestamp-method'][:ok], overall['same-timestamp-method'][:nok],corridor)}"
    #p "#{trace_uuid} - #{trace_outcome} - 90-degrees:(#{overall['90-degrees-method'].map() { |k,v| "#{k}:#{v}"}.join('/')}) - shortest-distance:(#{overall['shortest-distance-method'].map() { |k,v| "#{k}:#{v}"}.join('/')}) - same-timestamp:(#{overall['same-timestamp-method'].map() { |k,v| "#{k}:#{v}"}.join('/')}) / #{trace_outcome} -> #{overall['90-degrees-method'][:ok] <=> overall['90-degrees-method'][:nok]}/#{overall['shortest-distance-method'][:ok] <=> overall['shortest-distance-method'][:nok]}/#{overall['same-timestamp-method'][:ok] <=> overall['same-timestamp-method'][:nok]}"
    compare = trace_outcome == 'ok' ? 1 : -1
    #(overall['90-degrees-method'][:ok] <=> overall['90-degrees-method'][:nok]) == 0 ? overall_results['90-degrees-method'][:undecidable] += 1 : (compare == (overall['90-degrees-method'][:ok] <=> overall['90-degrees-method'][:nok]) ? overall_results['90-degrees-method'][:richtig] += 1 : overall_results['90-degrees-method'][:falsch] += 1)
    #(overall['shortest-distance-method'][:ok] <=> overall['shortest-distance-method'][:nok]) == 0 ? overall_results['shortest-distance-method'][:undecidable] += 1 : (compare == (overall['shortest-distance-method'][:ok] <=> overall['shortest-distance-method'][:nok]) ? overall_results['shortest-distance-method'][:richtig] += 1 : overall_results['shortest-distance-method'][:falsch] += 1)
    #(overall['same-timestamp-method'][:ok] <=> overall['same-timestamp-method'][:nok]) == 0 ? overall_results['same-timestamp-method'][:undecidable] += 1 : (compare == (overall['same-timestamp-method'][:ok] <=> overall['same-timestamp-method'][:nok]) ? overall_results['same-timestamp-method'][:richtig] += 1 : overall_results['same-timestamp-method'][:falsch] += 1)
    (overall['90-degrees-method'][:ok] - overall['90-degrees-method'][:nok]).abs() <= corridor ? overall_results['90-degrees-method'][:undecidable] += 1 : (compare == (overall['90-degrees-method'][:ok] <=> overall['90-degrees-method'][:nok]) ? overall_results['90-degrees-method'][:richtig] += 1 : overall_results['90-degrees-method'][:falsch] += 1)
    (overall['shortest-distance-method'][:ok] - overall['shortest-distance-method'][:nok]).abs() <= corridor ? overall_results['shortest-distance-method'][:undecidable] += 1 : (compare == (overall['shortest-distance-method'][:ok] <=> overall['shortest-distance-method'][:nok]) ? overall_results['shortest-distance-method'][:richtig] += 1 : overall_results['shortest-distance-method'][:falsch] += 1)
    (overall['same-timestamp-method'][:ok] - overall['same-timestamp-method'][:nok]).abs() <= corridor ? overall_results['same-timestamp-method'][:undecidable] += 1 : (compare == (overall['same-timestamp-method'][:ok] <=> overall['same-timestamp-method'][:nok]) ? overall_results['same-timestamp-method'][:richtig] += 1 : overall_results['same-timestamp-method'][:falsch] += 1)
  end
  puts "generic => #{overall_results}"
end
