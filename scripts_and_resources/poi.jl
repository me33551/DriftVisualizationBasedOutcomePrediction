using Polynomials
using Plots
using JSON
using Roots
using OrderedCollections
#using GR


#=
xs = range(0, 10, length = 10)
ys = @.exp(-xs)
f = fit(xs, ys) # degree = length(xs) - 1
f2 = fit(xs, ys, 2) # degree = 2

display(scatter(xs, ys, markerstrokewidth = 0, label = "Data"))
sleep(5)
display(plot!(f, extrema(xs)..., label = "Fit"))
sleep(5)
disply(plot!(f2, extrema(xs)..., label = "Quadratic Fit"))
sleep(5)
=#


f = joinpath(@__DIR__,"traces_relative.json")
s = read(f, String)
x = JSON.parse(s)
traces = x["GV12 Machining"]

f = joinpath(@__DIR__,"ats_nok_ok.json")
s = read(f, String)
y = JSON.parse(s)

####################### important
#analysed_thing = "difference_ok_nok"
#analysed_thing = "difference_ok_nok_90-degrees-method"
#analysed_thing = "difference_ok_nok_shortest-distance-method"
#analysed_thing = "difference_ok_nok_same-timestamp-method"
#analysed_thing = "difference_nok_ok_90-degrees-method"
#analysed_thing = "difference_nok_ok_shortest-distance-method"
#analysed_thing = "difference_nok_ok_same-timestamp-method"
analysed_things = ["difference_ok_nok", "difference_ok_nok_90-degrees-method", "difference_ok_nok_shortest-distance-method", "difference_ok_nok_same-timestamp-method", "difference_nok_ok_90-degrees-method", "difference_nok_ok_shortest-distance-method", "difference_nok_ok_same-timestamp-method"]
println(analysed_things)

results = Dict()
for analysed_thing in analysed_things
  results[analysed_thing] = Dict()
  
  #println(y["difference_ok_nok"])
  println(y)
  q = findmax(y[analysed_thing])
  r = findmin(y[analysed_thing])
  #z = filter(((k,v),)->v>=-0.05&&v<=0.05,y["difference_ok_nok"])
  z = y[analysed_thing]
  ordered = OrderedDict(sort(collect(z),by=el->parse(Float64,first(el))))
  #println(z)
  #println(ordered)
  
  near_zero = nothing
  last_near_zero = true 
  changes = []
  segments = []
  for(x,y) in ordered
    near_zero = abs(y) <= 0.01
    if(last_near_zero && !near_zero)
      println("change at $(x)")
      push!(changes,parse(Float64,x))
      push!(segments,[])
    end
    push!(last(segments),(x,y))
    last_near_zero = near_zero
  end


  """
  positive = (first(ordered)[2]>=0 ? true : false)
  last_positive = nothing
  changes = []
  segments = [[]]
  for(x,y) in ordered
    positive = (y>=0 ? true : false)
    if(!isnothing(last_positive) && positive != last_positive)
      println("change at $(x)")
      push!(changes,parse(Float64,x))
      push!(segments,[])
    end
    push!(last(segments),(x,y))
    last_positive = positive
  end
  """

  println(changes)
  println(map(x->size(x),segments))
  
  sc = scatter(map(x->parse(Float64,x[1]),collect(ordered)), map(x->abs(x[2]),collect(ordered)), markerstrokewidth = 0, label = "Data")
  # plot!(ordered, extrema(ordered)..., label = "points")
  #results[trace_id]["extremstellen"] = map((x) -> real(x), filter((x) -> isreal(x), roots(derivative(fitted))))
  #results[trace_id]["extremstellen"] = filter(x -> (x>=0 && x<=maximum(x)), results[trace_id]["extremstellen"])
  vline!(changes, label = "Separations")
  
  #sleep(5)
  #break
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
      println("upwards_trend: $(upwards_trend), downwards_trend: $(downwards_trend)")
    end

    #if(length(items) >= 10) #groesse anhand der elemente oder anhand der timestamps -> noch ueberlegen/testen
    if(length(items) >= 2 && parse(Float64,last(items)[1]) - parse(Float64,first(items)[1]) >= 1) #groesse anhand der timestamps
      min_item = items[findmin(map(x->abs(x[2]),items))[2]]
      push!(mins,parse(Float64,min_item[1]))
      println("mins at $(mins)")
      poi = items[findmax(map(x->abs(x[2]),items))[2]]
      push!(pois,parse(Float64,poi[1]))
    end
  end
  results[analysed_thing]["poi"] = pois
  results[analysed_thing]["peaks"] = peaks
  all = unique(vcat(pois,peaks))


  savefig(joinpath(@__DIR__,"test_img/analysis/$(analysed_thing)_segments.svg"))
  
  #vline!(pois, label = "POIs")
  display(sc)
  #vline!(mins, label = "mins")
  #vline!(peaks, label = "peaks")
  vline!(all, label = "Potentially Interesting Points")
  display(sc)
  savefig(joinpath(@__DIR__,"test_img/analysis/$(analysed_thing)_pois_peaks.svg"))
  #sleep(15)

  results[analysed_thing]["traces"] = Dict()
  for (trace_id,trace_values) in traces
    results[analysed_thing]["traces"][trace_id] = Dict()
  end



  #println(y["difference_ok_nok"])
  #println("$(last(q)): $(y["difference_ok_nok"][last(q)])")
  #println("$(last(r)): $(y["difference_ok_nok"][last(r)])")
  #results[trace_id]["extremstellen"] = [parse(Float64,last(q)),parse(Float64,last(r))]
  println(results[analysed_thing]["poi"])
  #results[trace_id]["extremstellen"] = [1.9,3.7,5.8,8.3]
end

open(joinpath(@__DIR__,"test_img/analysis/points.json"),"w") do file
  JSON.print(file, results)
end
