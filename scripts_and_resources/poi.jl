using Polynomials
using Plots
using JSON
using Roots
using OrderedCollections

f = joinpath(@__DIR__,"traces_relative.json")
s = read(f, String)
x = JSON.parse(s)
traces = x["GV12 Machining"]

f = joinpath(@__DIR__,"ats_nok_ok.json")
s = read(f, String)
y = JSON.parse(s)

analysed_things = ["difference_ok_nok", "difference_ok_nok_90-degrees-method", "difference_ok_nok_shortest-distance-method", "difference_ok_nok_same-timestamp-method", "difference_nok_ok_90-degrees-method", "difference_nok_ok_shortest-distance-method", "difference_nok_ok_same-timestamp-method"]

results = Dict()
for analysed_thing in analysed_things
  results[analysed_thing] = Dict()
  
  q = findmax(y[analysed_thing])
  r = findmin(y[analysed_thing])
  z = y[analysed_thing]
  ordered = OrderedDict(sort(collect(z),by=el->parse(Float64,first(el))))
  
  near_zero = nothing
  last_near_zero = true 
  changes = []
  segments = []
  for(x,y) in ordered
    near_zero = abs(y) <= 0.01
    if(last_near_zero && !near_zero)
      push!(changes,parse(Float64,x))
      push!(segments,[])
    end
    push!(last(segments),(x,y))
    last_near_zero = near_zero
  end

  sc = scatter(map(x->parse(Float64,x[1]),collect(ordered)), map(x->abs(x[2]),collect(ordered)), markerstrokewidth = 0, label = "Data")
  vline!(changes, label = "Separations")
  
  results[analysed_thing]["poi"] = []
  pois = []
  mins = []
  peaks = []
  window = 3
  for items in segments
    last_item = (nothing,0)
    upwards_trend = 0
    downwards_trend = 0
    last_added_peak = nothing
    for item in items
      if(abs(item[2]) > abs(last_item[2]))
        upwards_trend += 1
        downwards_trend = 0
      elseif(abs(item[2]) < abs(last_item[2]))
        if(upwards_trend >= window)
          last_added_peak = last_item
          push!(peaks,parse(Float64,last_item[1]))
        else
          if(!isnothing(last_added_peak) && last_added_peak[2] < last_item[2])
            last_added_peak = last_item
            pop!(peaks)
            push!(peaks,parse(Float64,last_item[1]))
          end
        end
        downwards_trend += 1
        upwards_trend = 0
      else
      end
      last_item = item
      if(upwards_trend >= window)
        last_added_peak = nothing
      end
    end

    if(length(items) >= 2 && parse(Float64,last(items)[1]) - parse(Float64,first(items)[1]) >= 1)
      min_item = items[findmin(map(x->abs(x[2]),items))[2]]
      push!(mins,parse(Float64,min_item[1]))
      poi = items[findmax(map(x->abs(x[2]),items))[2]]
      push!(pois,parse(Float64,poi[1]))
    end
  end
  results[analysed_thing]["poi"] = pois
  results[analysed_thing]["peaks"] = peaks
  all = unique(vcat(pois,peaks))


  savefig(joinpath(@__DIR__,"test_img/analysis/$(analysed_thing)_segments.svg"))
  
  display(sc)
  vline!(all, label = "Potentially Interesting Points")
  display(sc)
  savefig(joinpath(@__DIR__,"test_img/analysis/$(analysed_thing)_pois_peaks.svg"))

  results[analysed_thing]["traces"] = Dict()
  for (trace_id,trace_values) in traces
    results[analysed_thing]["traces"][trace_id] = Dict()
  end


end

open(joinpath(@__DIR__,"test_img/analysis/points.json"),"w") do file
  JSON.print(file, results)
end

println("created points.json with method for finding POIs over multiple traces")
