using Polynomials
using Plots
using JSON
using Roots
using HTTP


function calculate_differences(json)
  
  traces = x
  traces["difference_ok_nok"] = Dict()
  traces["difference_nok_ok"] = Dict()
  traces["difference_ok_nok_90-degrees-method"] = Dict()
  traces["difference_ok_nok_shortest-distance-method"] = Dict()
  traces["difference_ok_nok_same-timestamp-method"] = Dict()
  traces["difference_nok_ok_90-degrees-method"] = Dict()
  traces["difference_nok_ok_shortest-distance-method"] = Dict()
  traces["difference_nok_ok_same-timestamp-method"] = Dict()
  
  
  counter = 0
  for (k,v) in traces["ats_ok"]
    println(k)
    println(v)
    try
      println("http://localhost:8050/ats_ok/$(k)/json")
      resp = HTTP.get("http://localhost:8050/ats_ok/$(k)/json")
      println(resp.status)
      result = JSON.parse(String(resp.body))
      traces["difference_ok_nok_90-degrees-method"][k] = result["data"]["90-degrees-method"]["lengths in mm"]["trace + ats nok"]
      traces["difference_ok_nok_shortest-distance-method"][k] = result["data"]["shortest-distance-method"]["lengths in mm"]["trace + ats nok"]
      traces["difference_ok_nok_same-timestamp-method"][k] = result["data"]["same-timestamp-method"]["lengths in mm"]["trace + ats nok"]
    catch e
      println("something failed: $(e)")
    end
  
    if(k in keys(traces["ats_nok"]))
      println(traces["ats_nok"][k])
      traces["difference_ok_nok"][k] = v - traces["ats_nok"][k] 
    else
      println("--------------------------------------not available")
    end
    counter += 1
  end
  

  counter = 0
  for (k,v) in traces["ats_nok"]
    println(k)
    println(v)
    try
      println("http://localhost:8050/ats_nok/$(k)/json")
      resp = HTTP.get("http://localhost:8050/ats_nok/$(k)/json")
      result = JSON.parse(String(resp.body))
      traces["difference_nok_ok_90-degrees-method"][k] = result["data"]["90-degrees-method"]["lengths in mm"]["trace + ats ok"]
      traces["difference_nok_ok_shortest-distance-method"][k] = result["data"]["shortest-distance-method"]["lengths in mm"]["trace + ats ok"]
      traces["difference_nok_ok_same-timestamp-method"][k] = result["data"]["same-timestamp-method"]["lengths in mm"]["trace + ats ok"]
    catch e
      println("something failed: $(e)")
    end
  
    if(k in keys(traces["ats_ok"]))
      println(traces["ats_ok"][k])
      traces["difference_nok_ok"][k] = v - traces["ats_ok"][k]
    else
      println("--------------------------------------not available")
    end
    counter += 1
  end

  
  return traces
end



f = joinpath(@__DIR__,"ats_nok_ok.json")
s = read(f, String)
x = JSON.parse(s)

traces = calculate_differences(x)

open(joinpath(@__DIR__,"ats_nok_ok.json"),"w") do file
  JSON.print(file, traces)
end
